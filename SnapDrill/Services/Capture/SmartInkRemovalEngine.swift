import CoreGraphics
import CoreImage
import CoreML
import Foundation
import UIKit
import Vision

/// Detailed result from heuristic ink cleanup allowing callers to distinguish
/// genuine annotation removal from untouched black-ink sheets (PRD §8.6, AC-04).
struct InkRemovalAnalysis: Sendable {
    let cleanedData: Data
    let succeeded: Bool
    let erasedPixelCount: Int
}

private enum TimeoutRaceOutcome<Value: Sendable>: Sendable {
    case finished(Value)
    case timedOut
}

/// Off-MainActor heuristic handwriting & annotation remover with smooth bilinear paper-tone estimation
/// and a strict execution timeout guard (PRD F-10, §8.6, AC-04).
struct HeuristicInkRemover: InkRemoving {
    let timeoutSeconds: Double

    init(timeoutSeconds: Double = 2.0) {
        self.timeoutSeconds = timeoutSeconds
    }

    func removeInk(from imageData: Data, mode: InkRemovalMode) async -> (cleanedData: Data, succeeded: Bool) {
        let analysis = await removeInkDetailed(from: imageData, mode: mode)
        return (analysis.cleanedData, analysis.succeeded)
    }

    func removeInkDetailed(from imageData: Data, mode: InkRemovalMode) async -> InkRemovalAnalysis {
        if mode == .off {
            return InkRemovalAnalysis(cleanedData: imageData, succeeded: true, erasedPixelCount: 0)
        }

        let workTask = Task.detached(priority: .userInitiated) { () -> InkRemovalAnalysis in
            guard !Task.isCancelled,
                  let sourceImage = UIImage(data: imageData),
                  let (processed, erasedCount) = processImageDetailed(sourceImage, mode: mode),
                  !Task.isCancelled,
                  let encoded = processed.jpegData(compressionQuality: 0.88) else {
                return InkRemovalAnalysis(cleanedData: imageData, succeeded: false, erasedPixelCount: 0)
            }
            return InkRemovalAnalysis(cleanedData: encoded, succeeded: true, erasedPixelCount: erasedCount)
        }

        let limit = timeoutSeconds
        return await withTaskGroup(of: TimeoutRaceOutcome<InkRemovalAnalysis>?.self) { group in
            group.addTask {
                .finished(await workTask.value)
            }
            group.addTask {
                do {
                    try await Task.sleep(for: .seconds(limit))
                    return .timedOut
                } catch {
                    return nil
                }
            }

            while let outcome = await group.next() {
                guard let outcome else { continue }
                switch outcome {
                case .finished(let result):
                    group.cancelAll()
                    return result
                case .timedOut:
                    workTask.cancel()
                    group.cancelAll()
                    return InkRemovalAnalysis(cleanedData: imageData, succeeded: false, erasedPixelCount: 0)
                }
            }
            return InkRemovalAnalysis(cleanedData: imageData, succeeded: false, erasedPixelCount: 0)
        }
    }

    /// Synchronous helper exposed for deterministic unit tests and previews.
    func processImage(_ image: UIImage, mode: InkRemovalMode) -> UIImage? {
        processImageDetailed(image, mode: mode)?.image
    }

    func processImageDetailed(_ image: UIImage, mode: InkRemovalMode) -> (image: UIImage, erasedPixelCount: Int)? {
        guard mode != .off else { return (image, 0) }
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        let rendered: Bool = pixels.withUnsafeMutableBytes { rawPtr in
            guard let baseAddress = rawPtr.baseAddress,
                  let context = CGContext(
                      data: baseAddress,
                      width: width,
                      height: height,
                      bitsPerComponent: 8,
                      bytesPerRow: bytesPerRow,
                      space: colorSpace,
                      bitmapInfo: bitmapInfo
                  ) else {
                return false
            }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }

        guard rendered else { return nil }

        // Step 1: Estimate local paper background on a coarse 16x16 block grid using 85th-percentile luminance.
        let gridCols = min(16, max(1, width / 24))
        let gridRows = min(16, max(1, height / 24))
        let paperGrid = estimatePaperGrid(
            pixels: pixels,
            width: width,
            height: height,
            bytesPerRow: bytesPerRow,
            cols: gridCols,
            rows: gridRows
        )

        var erasedMask = [Bool](repeating: false, count: width * height)
        var erasedPixelCount = 0

        // Step 2: Strip colored ink (red/blue/highlighter) & faint graphite pencil without altering dark printed/black ink.
        for y in 0..<height {
            if y % 64 == 0, Task.isCancelled { return nil }

            let rowOffset = y * bytesPerRow
            let maskRowOffset = y * width

            for x in 0..<width {
                let paper = interpolatedPaper(
                    atX: x,
                    y: y,
                    width: width,
                    height: height,
                    grid: paperGrid,
                    cols: gridCols,
                    rows: gridRows
                )
                let idx = rowOffset + x * 4

                let r = Int(pixels[idx])
                let g = Int(pixels[idx + 1])
                let b = Int(pixels[idx + 2])

                let maxC = max(r, max(g, b))
                let minC = min(r, min(g, b))
                let chroma = maxC - minC

                let luma = (299 * r + 587 * g + 114 * b) / 1000
                let paperLuma = (299 * Int(paper.r) + 587 * Int(paper.g) + 114 * Int(paper.b)) / 1000
                let relDark = paperLuma - luma

                let isRedInk = (r - max(g, b) > 22) && chroma > 28
                let isBlueInk = (b - r > 18) && chroma > 24
                let isBrightMarker = chroma > 32 && luma > 85
                let isColoredInk = isRedInk || isBlueInk || isBrightMarker

                if isColoredInk {
                    pixels[idx] = paper.r
                    pixels[idx + 1] = paper.g
                    pixels[idx + 2] = paper.b
                    pixels[idx + 3] = 255
                    erasedMask[maskRowOffset + x] = true
                    erasedPixelCount += 1
                    continue
                }

                guard mode == .autoAll else { continue }

                // Faint pencil & paper smudge lift; dark black pen & printed ink remain untouched
                if relDark > 8 && relDark < 46 && luma > 138 && chroma <= 26 {
                    let keepFactor = max(0.0, min(1.0, Double(relDark - 24) / 28.0)) * 0.25
                    pixels[idx] = UInt8(clamping: Int(Double(paper.r) * (1.0 - keepFactor) + Double(r) * keepFactor))
                    pixels[idx + 1] = UInt8(clamping: Int(Double(paper.g) * (1.0 - keepFactor) + Double(g) * keepFactor))
                    pixels[idx + 2] = UInt8(clamping: Int(Double(paper.b) * (1.0 - keepFactor) + Double(b) * keepFactor))
                    pixels[idx + 3] = 255
                    erasedPixelCount += 1
                }
            }
        }

        // Step 3: 1px anti-alias de-fringe pass around erased colored strokes to eliminate halos.
        if width > 2 && height > 2 {
            for y in 1..<(height - 1) {
                for x in 1..<(width - 1) {
                    let maskIdx = y * width + x
                    if erasedMask[maskIdx] { continue }

                    let hasErasedNeighbor =
                        erasedMask[maskIdx - 1] ||
                        erasedMask[maskIdx + 1] ||
                        erasedMask[maskIdx - width] ||
                        erasedMask[maskIdx + width]
                    guard hasErasedNeighbor else { continue }

                    let idx = y * bytesPerRow + x * 4
                    let r = Int(pixels[idx])
                    let g = Int(pixels[idx + 1])
                    let b = Int(pixels[idx + 2])
                    let chroma = max(r, max(g, b)) - min(r, min(g, b))
                    let luma = (299 * r + 587 * g + 114 * b) / 1000

                    if chroma > 14 && luma > 95 {
                        let paper = interpolatedPaper(
                            atX: x,
                            y: y,
                            width: width,
                            height: height,
                            grid: paperGrid,
                            cols: gridCols,
                            rows: gridRows
                        )
                        pixels[idx] = paper.r
                        pixels[idx + 1] = paper.g
                        pixels[idx + 2] = paper.b
                    }
                }
            }
        }

        let outputImage: UIImage? = pixels.withUnsafeMutableBytes { rawPtr in
            guard let baseAddress = rawPtr.baseAddress,
                  let context = CGContext(
                      data: baseAddress,
                      width: width,
                      height: height,
                      bitsPerComponent: 8,
                      bytesPerRow: bytesPerRow,
                      space: colorSpace,
                      bitmapInfo: bitmapInfo
                  ),
                  let outputCG = context.makeImage() else {
                return nil
            }
            return UIImage(cgImage: outputCG)
        }

        guard let outputImage else { return nil }
        return (outputImage, erasedPixelCount)
    }

    private func estimatePaperGrid(
        pixels: [UInt8],
        width: Int,
        height: Int,
        bytesPerRow: Int,
        cols: Int,
        rows: Int
    ) -> [(r: UInt8, g: UInt8, b: UInt8)] {
        var result = [(r: UInt8, g: UInt8, b: UInt8)](repeating: (250, 248, 244), count: cols * rows)

        for gy in 0..<rows {
            let yStart = (gy * height) / rows
            let yEnd = max(yStart + 1, ((gy + 1) * height) / rows)
            let yStep = max(1, (yEnd - yStart) / 16)

            for gx in 0..<cols {
                let xStart = (gx * width) / cols
                let xEnd = max(xStart + 1, ((gx + 1) * width) / cols)
                let xStep = max(1, (xEnd - xStart) / 16)

                var samples: [(luma: Int, r: UInt8, g: UInt8, b: UInt8)] = []
                for y in stride(from: yStart, to: yEnd, by: yStep) {
                    let rowBase = y * bytesPerRow
                    for x in stride(from: xStart, to: xEnd, by: xStep) {
                        let idx = rowBase + x * 4
                        let r = pixels[idx]
                        let g = pixels[idx + 1]
                        let b = pixels[idx + 2]
                        let luma = (299 * Int(r) + 587 * Int(g) + 114 * Int(b)) / 1000
                        samples.append((luma, r, g, b))
                    }
                }

                guard !samples.isEmpty else { continue }
                samples.sort { $0.luma < $1.luma }
                let targetIdx = min(samples.count - 1, Int(Double(samples.count - 1) * 0.85))
                let chosen = samples[targetIdx]
                // Preserve local shaded luminance smoothly instead of forcing a hard near-white clamp
                result[gy * cols + gx] = (r: chosen.r, g: chosen.g, b: chosen.b)
            }
        }
        return result
    }

    private func interpolatedPaper(
        atX x: Int,
        y: Int,
        width: Int,
        height: Int,
        grid: [(r: UInt8, g: UInt8, b: UInt8)],
        cols: Int,
        rows: Int
    ) -> (r: UInt8, g: UInt8, b: UInt8) {
        let fx = cols > 1 ? max(0.0, min(Double(cols - 1), (Double(x) / Double(max(1, width - 1))) * Double(cols - 1))) : 0.0
        let fy = rows > 1 ? max(0.0, min(Double(rows - 1), (Double(y) / Double(max(1, height - 1))) * Double(rows - 1))) : 0.0

        let x0 = Int(fx)
        let x1 = min(cols - 1, x0 + 1)
        let y0 = Int(fy)
        let y1 = min(rows - 1, y0 + 1)
        let tx = fx - Double(x0)
        let ty = fy - Double(y0)

        let p00 = grid[y0 * cols + x0]
        let p10 = grid[y0 * cols + x1]
        let p01 = grid[y1 * cols + x0]
        let p11 = grid[y1 * cols + x1]

        func lerp(_ c00: UInt8, _ c10: UInt8, _ c01: UInt8, _ c11: UInt8) -> UInt8 {
            let top = Double(c00) * (1.0 - tx) + Double(c10) * tx
            let bot = Double(c01) * (1.0 - tx) + Double(c11) * tx
            return UInt8(clamping: Int((top * (1.0 - ty) + bot * ty).rounded()))
        }

        return (
            r: lerp(p00.r, p10.r, p01.r, p11.r),
            g: lerp(p00.g, p10.g, p01.g, p11.g),
            b: lerp(p00.b, p10.b, p01.b, p11.b)
        )
    }
}

/// Core ML integration slot (Stage 0): executes bundled `HandwritingRemover.mlmodelc` off-MainActor via Vision/Neural Engine,
/// and degrades honestly when no trained Stage-0 segmentation model is present or when an image contains only dark black ink (PRD §8.6, AC-04).
struct CoreMLCapableInkRemover: InkRemoving {
    private static let inferenceContext = CIContext(options: [.useSoftwareRenderer: false])

    private let fallback: HeuristicInkRemover
    private let modelResourceName: String
    private let timeoutSeconds: Double

    init(
        modelResourceName: String = "HandwritingRemover",
        timeoutSeconds: Double = 2.0,
        fallback: HeuristicInkRemover? = nil
    ) {
        self.modelResourceName = modelResourceName
        self.timeoutSeconds = timeoutSeconds
        self.fallback = fallback ?? HeuristicInkRemover(timeoutSeconds: timeoutSeconds)
    }

    func removeInk(from imageData: Data, mode: InkRemovalMode) async -> (cleanedData: Data, succeeded: Bool) {
        if mode == .off {
            return (imageData, true)
        }

        if mode == .autoAll,
           let modelURL = Bundle.main.url(forResource: modelResourceName, withExtension: "mlmodelc") {
            if let mlCleaned = await runCoreMLInference(modelURL: modelURL, imageData: imageData) {
                return (mlCleaned, true)
            }
            // Core ML model failed or timed out -> degrade honestly per PRD §8.6
            return (imageData, false)
        }

        // Without a bundled Core ML model, run off-MainActor colored/faint-pencil cleanup honestly
        let heuristic = await fallback.removeInkDetailed(from: imageData, mode: mode)
        if !heuristic.succeeded {
            return (imageData, false)
        }

        if mode == .coloredOnly {
            return (heuristic.cleanedData, true)
        }

        // In .autoAll without a trained Core ML model, only claim succeeded when colored/pencil strokes were actually detected & stripped;
        // pure dark black-ink pages honestly report succeeded = false so PRD §8.6 prompts manual eraser.
        let actuallyCleaned = heuristic.erasedPixelCount > 0
        return (heuristic.cleanedData, actuallyCleaned)
    }

    private func runCoreMLInference(modelURL: URL, imageData: Data) async -> Data? {
        let workTask = Task.detached(priority: .userInitiated) { () -> Data? in
            guard let sourceImage = UIImage(data: imageData),
                  let cgImage = sourceImage.cgImage else {
                return nil
            }
            let config = MLModelConfiguration()
            config.computeUnits = .all
            guard let mlModel = try? MLModel(contentsOf: modelURL, configuration: config),
                  let vnModel = try? VNCoreMLModel(for: mlModel) else {
                return nil
            }

            let request = VNCoreMLRequest(model: vnModel)
            request.imageCropAndScaleOption = .scaleFill
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                guard let pixelObs = request.results?.first as? VNPixelBufferObservation else {
                    return nil
                }
                let ciOut = CIImage(cvPixelBuffer: pixelObs.pixelBuffer)
                guard !ciOut.extent.isEmpty,
                      let outCG = Self.inferenceContext.createCGImage(ciOut, from: ciOut.extent) else {
                    return nil
                }
                return UIImage(cgImage: outCG).jpegData(compressionQuality: 0.88)
            } catch {
                return nil
            }
        }

        let limit = timeoutSeconds
        return await withTaskGroup(of: TimeoutRaceOutcome<Data?>?.self) { group in
            group.addTask { .finished(await workTask.value) }
            group.addTask {
                do {
                    try await Task.sleep(for: .seconds(limit))
                    return .timedOut
                } catch {
                    return nil
                }
            }
            while let outcome = await group.next() {
                guard let outcome else { continue }
                switch outcome {
                case .finished(let data):
                    group.cancelAll()
                    return data
                case .timedOut:
                    workTask.cancel()
                    group.cancelAll()
                    return nil
                }
            }
            return nil
        }
    }
}
