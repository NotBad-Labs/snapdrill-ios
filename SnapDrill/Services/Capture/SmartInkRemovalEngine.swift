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
    let coloredErasedCount: Int
    let pencilErasedCount: Int
    let totalPixelCount: Int

    init(
        cleanedData: Data,
        succeeded: Bool,
        erasedPixelCount: Int,
        coloredErasedCount: Int = 0,
        pencilErasedCount: Int = 0,
        totalPixelCount: Int = 0
    ) {
        self.cleanedData = cleanedData
        self.succeeded = succeeded
        self.erasedPixelCount = erasedPixelCount
        self.coloredErasedCount = coloredErasedCount
        self.pencilErasedCount = pencilErasedCount
        self.totalPixelCount = totalPixelCount
    }
}

private actor InkTimeoutRaceGate<Value: Sendable> {
    private var continuation: CheckedContinuation<Value, Never>?
    private var resolvedValue: Value?

    func wait() async -> Value {
        if let resolvedValue {
            return resolvedValue
        }
        return await withCheckedContinuation { cont in
            if let resolvedValue {
                cont.resume(returning: resolvedValue)
            } else {
                continuation = cont
            }
        }
    }

    func resolve(with value: Value) -> Bool {
        guard resolvedValue == nil else { return false }
        resolvedValue = value
        continuation?.resume(returning: value)
        continuation = nil
        return true
    }
}

private final class CancellableCoreMLRequestBox: @unchecked Sendable {
    private let lock = NSLock()
    private var request: VNRequest?
    private var isCancelled = false

    func attach(_ request: VNRequest) {
        lock.lock()
        let alreadyCancelled = isCancelled
        self.request = request
        lock.unlock()
        if alreadyCancelled {
            request.cancel()
        }
    }

    func cancel() {
        lock.lock()
        isCancelled = true
        let req = request
        lock.unlock()
        req?.cancel()
    }

    func clear() {
        lock.lock()
        request = nil
        lock.unlock()
    }
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

        let gate = InkTimeoutRaceGate<InkRemovalAnalysis>()
        let limit = timeoutSeconds

        let workTask = Task.detached(priority: .userInitiated) {
            let outcome: InkRemovalAnalysis
            if !Task.isCancelled,
               let sourceImage = UIImage(data: imageData),
               let detailed = processImageDetailedWithBreakdown(sourceImage, mode: mode),
               !Task.isCancelled,
               let encoded = detailed.image.jpegData(compressionQuality: 0.88) {
                outcome = InkRemovalAnalysis(
                    cleanedData: encoded,
                    succeeded: true,
                    erasedPixelCount: detailed.coloredCount + detailed.pencilCount,
                    coloredErasedCount: detailed.coloredCount,
                    pencilErasedCount: detailed.pencilCount,
                    totalPixelCount: detailed.totalPixels
                )
            } else {
                outcome = InkRemovalAnalysis(cleanedData: imageData, succeeded: false, erasedPixelCount: 0)
            }
            _ = await gate.resolve(with: outcome)
        }

        let timeoutTask = Task.detached(priority: .userInitiated) {
            try? await Task.sleep(for: .seconds(limit))
            guard !Task.isCancelled else { return }
            let won = await gate.resolve(with: InkRemovalAnalysis(cleanedData: imageData, succeeded: false, erasedPixelCount: 0))
            if won {
                workTask.cancel()
            }
        }

        let result = await withTaskCancellationHandler {
            await gate.wait()
        } onCancel: {
            workTask.cancel()
            timeoutTask.cancel()
            Task { _ = await gate.resolve(with: InkRemovalAnalysis(cleanedData: imageData, succeeded: false, erasedPixelCount: 0)) }
        }
        timeoutTask.cancel()
        return result
    }

    /// Synchronous helper exposed for deterministic unit tests and previews.
    func processImage(_ image: UIImage, mode: InkRemovalMode) -> UIImage? {
        processImageDetailed(image, mode: mode)?.image
    }

    func processImageDetailed(_ image: UIImage, mode: InkRemovalMode) -> (image: UIImage, erasedPixelCount: Int)? {
        guard let detailed = processImageDetailedWithBreakdown(image, mode: mode) else {
            return nil
        }
        return (detailed.image, detailed.coloredCount + detailed.pencilCount)
    }

    private func processImageDetailedWithBreakdown(
        _ image: UIImage,
        mode: InkRemovalMode
    ) -> (image: UIImage, coloredCount: Int, pencilCount: Int, totalPixels: Int)? {
        guard mode != .off else { return (image, 0, 0, 0) }
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

        // Precompute luminance map so anti-aliased edge pixels adjacent to dark printed/black ink
        // are never misclassified as faint pencil strokes.
        var originalLuma = [UInt8](repeating: 255, count: width * height)
        for y in 0..<height {
            if y % 64 == 0, Task.isCancelled { return nil }
            let rowOffset = y * bytesPerRow
            let lumaRowOffset = y * width
            for x in 0..<width {
                let idx = rowOffset + x * 4
                let luma = (299 * Int(pixels[idx]) + 587 * Int(pixels[idx + 1]) + 114 * Int(pixels[idx + 2])) / 1000
                originalLuma[lumaRowOffset + x] = UInt8(clamping: luma)
            }
        }

        var erasedMask = [Bool](repeating: false, count: width * height)
        var coloredErasedCount = 0
        var pencilErasedCount = 0

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

                let luma = Int(originalLuma[maskRowOffset + x])
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
                    coloredErasedCount += 1
                    continue
                }

                guard mode == .autoAll else { continue }

                // Faint pencil & paper smudge lift; skip anti-aliased fringe immediately bordering dark black ink
                if relDark > 8 && relDark < 46 && luma > 138 && chroma <= 26 {
                    if hasNearbyDarkInk(in: originalLuma, width: width, height: height, x: x, y: y) {
                        continue
                    }
                    let keepFactor = max(0.0, min(1.0, Double(relDark - 24) / 28.0)) * 0.25
                    pixels[idx] = UInt8(clamping: Int(Double(paper.r) * (1.0 - keepFactor) + Double(r) * keepFactor))
                    pixels[idx + 1] = UInt8(clamping: Int(Double(paper.g) * (1.0 - keepFactor) + Double(g) * keepFactor))
                    pixels[idx + 2] = UInt8(clamping: Int(Double(paper.b) * (1.0 - keepFactor) + Double(b) * keepFactor))
                    pixels[idx + 3] = 255
                    pencilErasedCount += 1
                }
            }
        }

        // Step 3: 1px anti-alias de-fringe pass around erased colored strokes to eliminate halos.
        if width > 2 && height > 2 {
            for y in 1..<(height - 1) {
                if y % 64 == 0, Task.isCancelled { return nil }
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
        return (outputImage, coloredErasedCount, pencilErasedCount, width * height)
    }

    private func hasNearbyDarkInk(in lumaMap: [UInt8], width: Int, height: Int, x: Int, y: Int) -> Bool {
        let minY = max(0, y - 2)
        let maxY = min(height - 1, y + 2)
        let minX = max(0, x - 2)
        let maxX = min(width - 1, x + 2)
        for ny in minY...maxY {
            let rowBase = ny * width
            for nx in minX...maxX {
                if lumaMap[rowBase + nx] < 125 {
                    return true
                }
            }
        }
        return false
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

        // In .autoAll without a trained Core ML model, require meaningful colored or faint-pencil stroke coverage
        // (ignoring isolated JPEG anti-aliasing/DCT fringe) so pure dark black-ink pages honestly report succeeded = false.
        let minPencilPixels = max(300, heuristic.totalPixelCount / 800)
        let actuallyCleaned = heuristic.coloredErasedCount >= 80 || heuristic.pencilErasedCount >= minPencilPixels
        if !actuallyCleaned && heuristic.erasedPixelCount == 0 {
            return (imageData, false)
        }
        return (heuristic.cleanedData, actuallyCleaned)
    }

    private func runCoreMLInference(modelURL: URL, imageData: Data) async -> Data? {
        let gate = InkTimeoutRaceGate<Data?>()
        let requestBox = CancellableCoreMLRequestBox()
        let limit = timeoutSeconds

        let workTask = Task.detached(priority: .userInitiated) {
            let result: Data? = await withTaskCancellationHandler {
                guard !Task.isCancelled,
                      let sourceImage = UIImage(data: imageData),
                      let cgImage = sourceImage.cgImage else {
                    return nil
                }
                let config = MLModelConfiguration()
                config.computeUnits = .all
                guard !Task.isCancelled,
                      let mlModel = try? MLModel(contentsOf: modelURL, configuration: config),
                      let vnModel = try? VNCoreMLModel(for: mlModel) else {
                    return nil
                }

                let request = VNCoreMLRequest(model: vnModel)
                request.imageCropAndScaleOption = .scaleFill
                requestBox.attach(request)
                defer { requestBox.clear() }

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                    guard !Task.isCancelled,
                          let pixelObs = request.results?.first as? VNPixelBufferObservation else {
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
            } onCancel: {
                requestBox.cancel()
            }
            _ = await gate.resolve(with: result)
        }

        let timeoutTask = Task.detached(priority: .userInitiated) {
            try? await Task.sleep(for: .seconds(limit))
            guard !Task.isCancelled else { return }
            let won = await gate.resolve(with: nil)
            if won {
                requestBox.cancel()
                workTask.cancel()
            }
        }

        let output = await withTaskCancellationHandler {
            await gate.wait()
        } onCancel: {
            requestBox.cancel()
            workTask.cancel()
            timeoutTask.cancel()
            Task { _ = await gate.resolve(with: nil) }
        }
        timeoutTask.cancel()
        return output
    }
}
