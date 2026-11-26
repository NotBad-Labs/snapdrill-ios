import CoreGraphics
import CoreML
import Foundation
import UIKit

// MARK: - Tile Planning

/// Pure geometry for covering a high-resolution crop with overlapping fixed-size model tiles.
enum TiledInkSegmentationPlanner {
    struct TileSpec: Equatable, Sendable {
        let pixelRect: CGRect
        let isLeftEdge: Bool
        let isRightEdge: Bool
        let isTopEdge: Bool
        let isBottomEdge: Bool

        var validSize: CGSize { pixelRect.size }
    }

    static func planTiles(imageWidth: Int, imageHeight: Int, tileSize: Int = 512, overlap: Int = 64) -> [TileSpec] {
        guard imageWidth > 0, imageHeight > 0, tileSize > 0 else { return [] }
        let xs = axisStarts(length: imageWidth, tile: tileSize, overlap: overlap)
        let ys = axisStarts(length: imageHeight, tile: tileSize, overlap: overlap)
        let tileWidth = min(tileSize, imageWidth)
        let tileHeight = min(tileSize, imageHeight)

        var tiles: [TileSpec] = []
        tiles.reserveCapacity(xs.count * ys.count)
        for (yi, y) in ys.enumerated() {
            for (xi, x) in xs.enumerated() {
                tiles.append(
                    TileSpec(
                        pixelRect: CGRect(x: x, y: y, width: tileWidth, height: tileHeight),
                        isLeftEdge: xi == 0,
                        isRightEdge: xi == xs.count - 1,
                        isTopEdge: yi == 0,
                        isBottomEdge: yi == ys.count - 1
                    )
                )
            }
        }
        return tiles
    }

    private static func axisStarts(length: Int, tile: Int, overlap: Int) -> [Int] {
        guard length > tile else { return [0] }
        let stride = max(1, tile - overlap)
        var starts: [Int] = []
        var position = 0
        while true {
            if position + tile >= length {
                let finalStart = length - tile
                if starts.last != finalStart {
                    starts.append(finalStart)
                }
                break
            }
            starts.append(position)
            position += stride
        }
        return starts
    }

    /// Raised-cosine blend weight so adjacent tiles fuse without visible seams.
    static func featherWeight(
        localX: Int,
        localY: Int,
        tileWidth: Int,
        tileHeight: Int,
        overlap: Int,
        isLeftEdge: Bool,
        isRightEdge: Bool,
        isTopEdge: Bool,
        isBottomEdge: Bool
    ) -> Float {
        func ramp(_ position: Int, _ size: Int, leadingEdge: Bool, trailingEdge: Bool) -> Float {
            guard overlap > 0 else { return 1 }
            var weight: Float = 1
            if !leadingEdge {
                let t = Float(position) / Float(overlap)
                if t < 1 { weight = min(weight, 0.05 + 0.95 * (0.5 - 0.5 * cos(Float.pi * t))) }
            }
            if !trailingEdge {
                let t = Float(size - 1 - position) / Float(overlap)
                if t < 1 { weight = min(weight, 0.05 + 0.95 * (0.5 - 0.5 * cos(Float.pi * t))) }
            }
            return weight
        }
        return ramp(localX, tileWidth, leadingEdge: isLeftEdge, trailingEdge: isRightEdge)
            * ramp(localY, tileHeight, leadingEdge: isTopEdge, trailingEdge: isBottomEdge)
    }
}

// MARK: - Mask Compositing

/// Rebuilds a clean page from a 3-class segmentation result: only pixels judged to be handwriting are replaced with
/// a locally estimated paper tone, so printed text keeps its original full-resolution sharpness.
enum SegmentationMaskCompositor {
    struct Result {
        let image: UIImage
        let erasedPixelCount: Int
        let totalPixelCount: Int
    }

    static func composite(
        source: CGImage,
        handwritingProb: [Float],
        printedProb: [Float],
        handwritingThreshold: Float = 0.55
    ) -> Result? {
        let width = source.width
        let height = source.height
        let total = width * height
        guard width > 0, height > 0,
              handwritingProb.count == total,
              printedProb.count == total else {
            return nil
        }

        var pixels = [UInt8](repeating: 0, count: total * 4)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return nil
        }
        context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))

        // 1) Core erase mask with a printed-text safety guard.
        var erase = [Bool](repeating: false, count: total)
        var strong = [Bool](repeating: false, count: total)
        for i in 0..<total {
            let hw = handwritingProb[i]
            if hw >= handwritingThreshold && hw > printedProb[i] * 1.15 {
                erase[i] = true
                if hw >= 0.70 { strong[i] = true }
            }
        }

        // 2) One-pixel fringe dilation, never into printed strokes.
        var dilated = erase
        for y in 0..<height {
            for x in 0..<width {
                let i = y * width + x
                guard !erase[i], printedProb[i] < 0.35 else { continue }
                var touchesStrong = false
                for dy in -1...1 {
                    for dx in -1...1 where dx != 0 || dy != 0 {
                        let nx = x + dx
                        let ny = y + dy
                        if nx >= 0, nx < width, ny >= 0, ny < height, strong[ny * width + nx] {
                            touchesStrong = true
                        }
                    }
                }
                if touchesStrong { dilated[i] = true }
            }
        }

        var erasedCount = 0
        for flag in dilated where flag { erasedCount += 1 }
        guard erasedCount > 0 else {
            return Result(image: UIImage(cgImage: source), erasedPixelCount: 0, totalPixelCount: total)
        }

        // 3) Local paper tone grid from pixels that are neither printed nor handwritten.
        let cell = 32
        let cols = max(1, (width + cell - 1) / cell)
        let rows = max(1, (height + cell - 1) / cell)
        var grid = [(r: Float, g: Float, b: Float)?](repeating: nil, count: cols * rows)
        var globalSumR: Float = 0, globalSumG: Float = 0, globalSumB: Float = 0, globalCount: Float = 0

        for gy in 0..<rows {
            for gx in 0..<cols {
                var samples: [(luma: Int, r: UInt8, g: UInt8, b: UInt8)] = []
                let x0 = gx * cell, x1 = min(width, x0 + cell)
                let y0 = gy * cell, y1 = min(height, y0 + cell)
                for y in y0..<y1 {
                    for x in x0..<x1 {
                        let i = y * width + x
                        guard !dilated[i], printedProb[i] < 0.30, handwritingProb[i] < 0.30 else { continue }
                        let o = i * 4
                        let r = pixels[o], g = pixels[o + 1], b = pixels[o + 2]
                        samples.append(((299 * Int(r) + 587 * Int(g) + 114 * Int(b)) / 1000, r, g, b))
                    }
                }
                guard samples.count >= 4 else { continue }
                // Row-major sample order + Swift's guaranteed-stable Timsort keeps luma ties deterministic,
                // matching Python np.argsort(lum, kind="mergesort") in MLPipeline/postprocess.py.
                samples.sort { $0.luma < $1.luma }
                let pick = samples[min(samples.count - 1, Int(Double(samples.count - 1) * 0.85))]
                grid[gy * cols + gx] = (Float(pick.r), Float(pick.g), Float(pick.b))
                globalSumR += Float(pick.r)
                globalSumG += Float(pick.g)
                globalSumB += Float(pick.b)
                globalCount += 1
            }
        }

        let fallback: (r: Float, g: Float, b: Float) = globalCount > 0
            ? (globalSumR / globalCount, globalSumG / globalCount, globalSumB / globalCount)
            : (245, 243, 238)
        let filled = grid.map { $0 ?? fallback }

        func paperColor(x: Int, y: Int) -> (r: Float, g: Float, b: Float) {
            let fx = min(Float(cols - 1), max(0, (Float(x) + 0.5) / Float(cell) - 0.5))
            let fy = min(Float(rows - 1), max(0, (Float(y) + 0.5) / Float(cell) - 0.5))
            let x0 = Int(fx), y0 = Int(fy)
            let x1 = min(cols - 1, x0 + 1), y1 = min(rows - 1, y0 + 1)
            let tx = fx - Float(x0), ty = fy - Float(y0)
            let p00 = filled[y0 * cols + x0], p10 = filled[y0 * cols + x1]
            let p01 = filled[y1 * cols + x0], p11 = filled[y1 * cols + x1]
            func lerp(_ a: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
                (a * (1 - tx) + b * tx) * (1 - ty) + (c * (1 - tx) + d * tx) * ty
            }
            return (
                lerp(p00.r, p10.r, p01.r, p11.r),
                lerp(p00.g, p10.g, p01.g, p11.g),
                lerp(p00.b, p10.b, p01.b, p11.b)
            )
        }

        for y in 0..<height {
            for x in 0..<width {
                let i = y * width + x
                guard dilated[i] else { continue }
                let paper = paperColor(x: x, y: y)
                let o = i * 4
                pixels[o] = UInt8(max(0, min(255, paper.r.rounded())))
                pixels[o + 1] = UInt8(max(0, min(255, paper.g.rounded())))
                pixels[o + 2] = UInt8(max(0, min(255, paper.b.rounded())))
                pixels[o + 3] = 255
            }
        }

        guard let output = context.makeImage() else { return nil }
        return Result(image: UIImage(cgImage: output), erasedPixelCount: erasedCount, totalPixelCount: total)
    }
}

// MARK: - Model Cache

/// Keeps compiled Core ML models resident so batch inference does not reload the Neural Engine program per question.
final class CoreMLSegmentationModelCache: @unchecked Sendable {
    static let shared = CoreMLSegmentationModelCache()

    private let lock = NSLock()
    private var models: [URL: MLModel] = [:]

    func model(at url: URL) -> MLModel? {
        lock.lock()
        defer { lock.unlock() }
        if let cached = models[url] { return cached }
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        guard let loaded = try? MLModel(contentsOf: url, configuration: configuration) else { return nil }
        models[url] = loaded
        return loaded
    }
}

// MARK: - Tiled Runner

/// Runs the 3-class (paper / printed / handwriting) segmentation model over overlapping 512 px tiles and
/// rebuilds the page with `SegmentationMaskCompositor`.
struct TiledCoreMLSegmentationRunner: Sendable {
    struct Output: Sendable {
        let cleanedData: Data
        let erasedPixelCount: Int
        let inferenceMs: Double
    }

    static let inputName = "image"
    static let outputName = "handwriting_prob"

    let modelURL: URL
    var tileSize: Int = 512
    var overlap: Int = 64

    static func supports(_ model: MLModel) -> Bool {
        model.modelDescription.outputDescriptionsByName[outputName] != nil
            && model.modelDescription.inputDescriptionsByName[inputName] != nil
    }

    func run(imageData: Data, preloadedModel: MLModel? = nil) -> Output? {
        guard let model = preloadedModel ?? CoreMLSegmentationModelCache.shared.model(at: modelURL),
              Self.supports(model),
              let uiImage = UIImage(data: imageData),
              let cgImage = Self.uprightCGImage(from: uiImage) else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        // Note: Quartz bitmap memory stores row 0 as the top row of the image when drawn with identity CTM,
        // matching top-left pixel indexing (y * width + x) used by Core ML and SegmentationMaskCompositor.
        var rgba = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &rgba,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return nil
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let padPaperRGB = Self.estimatePadPaperRGB(rgba: rgba, width: width, height: height)
        let total = width * height
        var printedAccum = [Float](repeating: 0, count: total)
        var handwritingAccum = [Float](repeating: 0, count: total)
        var weightAccum = [Float](repeating: 0, count: total)

        let tiles = TiledInkSegmentationPlanner.planTiles(imageWidth: width, imageHeight: height, tileSize: tileSize, overlap: overlap)
        let clock = ContinuousClock()
        let start = clock.now

        for tile in tiles {
            if Task.isCancelled { return nil }
            let tileWidth = Int(tile.pixelRect.width)
            let tileHeight = Int(tile.pixelRect.height)
            let padX = (tileSize - tileWidth) / 2
            let padY = (tileSize - tileHeight) / 2

            // Retry once on transient prediction failure; if still failing abort cleanly so caller can fall back.
            let probabilities = predict(
                tile: tile,
                rgba: rgba,
                imageWidth: width,
                padX: padX,
                padY: padY,
                padRGB: padPaperRGB,
                model: model
            ) ?? predict(
                tile: tile,
                rgba: rgba,
                imageWidth: width,
                padX: padX,
                padY: padY,
                padRGB: padPaperRGB,
                model: model
            )
            guard let probabilities else {
                return nil
            }

            let originX = Int(tile.pixelRect.origin.x)
            let originY = Int(tile.pixelRect.origin.y)

            for ty in 0..<tileHeight {
                for tx in 0..<tileWidth {
                    let weight = TiledInkSegmentationPlanner.featherWeight(
                        localX: tx,
                        localY: ty,
                        tileWidth: tileWidth,
                        tileHeight: tileHeight,
                        overlap: overlap,
                        isLeftEdge: tile.isLeftEdge,
                        isRightEdge: tile.isRightEdge,
                        isTopEdge: tile.isTopEdge,
                        isBottomEdge: tile.isBottomEdge
                    )
                    let dst = (originY + ty) * width + (originX + tx)
                    let src = (padY + ty) * tileSize + (padX + tx)
                    printedAccum[dst] += weight * probabilities.printed[src]
                    handwritingAccum[dst] += weight * probabilities.handwriting[src]
                    weightAccum[dst] += weight
                }
            }
        }

        for i in 0..<total where weightAccum[i] > 0 {
            printedAccum[i] /= weightAccum[i]
            handwritingAccum[i] /= weightAccum[i]
        }

        if Task.isCancelled { return nil }
        guard let composed = SegmentationMaskCompositor.composite(
            source: cgImage,
            handwritingProb: handwritingAccum,
            printedProb: printedAccum
        ), let encoded = composed.image.jpegData(compressionQuality: 0.88) else {
            return nil
        }

        let elapsed = clock.now - start
        let ms = Double(elapsed.components.seconds) * 1000 + Double(elapsed.components.attoseconds) / 1e15
        return Output(cleanedData: encoded, erasedPixelCount: composed.erasedPixelCount, inferenceMs: ms)
    }

    static func uprightCGImage(from image: UIImage) -> CGImage? {
        if image.imageOrientation == .up, let cg = image.cgImage {
            return cg
        }
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image.cgImage }
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true
        let rendered = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return rendered.cgImage
    }

    static func tilePaddingOffsets(tileWidth: Int, tileHeight: Int, tileSize: Int = 512) -> (padX: Int, padY: Int) {
        (max(0, (tileSize - tileWidth) / 2), max(0, (tileSize - tileHeight) / 2))
    }

    private static func estimatePadPaperRGB(rgba: [UInt8], width: Int, height: Int) -> (r: UInt8, g: UInt8, b: UInt8) {
        let stepX = max(1, width / 48)
        let stepY = max(1, height / 48)
        var samples: [(luma: Int, r: UInt8, g: UInt8, b: UInt8)] = []
        for y in stride(from: 0, to: height, by: stepY) {
            for x in stride(from: 0, to: width, by: stepX) {
                let o = (y * width + x) * 4
                let r = rgba[o], g = rgba[o + 1], b = rgba[o + 2]
                let luma = (299 * Int(r) + 587 * Int(g) + 114 * Int(b)) / 1000
                samples.append((luma, r, g, b))
            }
        }
        guard !samples.isEmpty else { return (245, 243, 238) }
        // Row-major stride + Swift's stable sort matches Python np.argsort(..., kind="mergesort") on luma ties.
        samples.sort { $0.luma < $1.luma }
        let pick = samples[min(samples.count - 1, Int(Double(samples.count - 1) * 0.85))]
        return (pick.r, pick.g, pick.b)
    }

    private struct TileProbabilities {
        let printed: [Float]
        let handwriting: [Float]
    }

    private func predict(
        tile: TiledInkSegmentationPlanner.TileSpec,
        rgba: [UInt8],
        imageWidth: Int,
        padX: Int,
        padY: Int,
        padRGB: (r: UInt8, g: UInt8, b: UInt8),
        model: MLModel
    ) -> TileProbabilities? {
        var pixelBuffer: CVPixelBuffer?
        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        guard CVPixelBufferCreate(
            kCFAllocatorDefault,
            tileSize,
            tileSize,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        ) == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        guard let base = CVPixelBufferGetBaseAddress(buffer) else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            return nil
        }
        let rowBytes = CVPixelBufferGetBytesPerRow(buffer)
        let dest = base.assumingMemoryBound(to: UInt8.self)
        let originX = Int(tile.pixelRect.origin.x)
        let originY = Int(tile.pixelRect.origin.y)
        let tileWidth = Int(tile.pixelRect.width)
        let tileHeight = Int(tile.pixelRect.height)

        for y in 0..<tileSize {
            let localY = y - padY
            for x in 0..<tileSize {
                let localX = x - padX
                let d = y * rowBytes + x * 4
                if localX >= 0, localX < tileWidth, localY >= 0, localY < tileHeight {
                    let s = ((originY + localY) * imageWidth + (originX + localX)) * 4
                    dest[d] = rgba[s + 2]
                    dest[d + 1] = rgba[s + 1]
                    dest[d + 2] = rgba[s]
                } else {
                    dest[d] = padRGB.b
                    dest[d + 1] = padRGB.g
                    dest[d + 2] = padRGB.r
                }
                dest[d + 3] = 255
            }
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])

        guard let input = try? MLDictionaryFeatureProvider(dictionary: [Self.inputName: MLFeatureValue(pixelBuffer: buffer)]),
              let result = try? model.prediction(from: input),
              let array = result.featureValue(for: Self.outputName)?.multiArrayValue else {
            return nil
        }
        return Self.extractProbabilities(array, tileSize: tileSize)
    }

    private static func extractProbabilities(_ array: MLMultiArray, tileSize: Int) -> TileProbabilities? {
        let shape = array.shape.map(\.intValue)
        let strides = array.strides.map(\.intValue)
        guard shape.count >= 3, shape.count == strides.count else { return nil }

        let channelAxis = shape.count - 3
        let channels = shape[channelAxis]
        let height = shape[channelAxis + 1]
        let width = shape[channelAxis + 2]
        guard channels >= 3, height >= tileSize, width >= tileSize else { return nil }

        let channelStride = strides[channelAxis]
        let rowStride = strides[channelAxis + 1]
        let colStride = strides[channelAxis + 2]

        var printed = [Float](repeating: 0, count: tileSize * tileSize)
        var handwriting = [Float](repeating: 0, count: tileSize * tileSize)

        func fill(_ read: (Int) -> Float) {
            for y in 0..<tileSize {
                for x in 0..<tileSize {
                    let base = y * rowStride + x * colStride
                    printed[y * tileSize + x] = read(base + channelStride)
                    handwriting[y * tileSize + x] = read(base + 2 * channelStride)
                }
            }
        }

        switch array.dataType {
        case .float32:
            let pointer = array.dataPointer.assumingMemoryBound(to: Float.self)
            fill { pointer[$0] }
        case .double:
            let pointer = array.dataPointer.assumingMemoryBound(to: Double.self)
            fill { Float(pointer[$0]) }
        case .float16:
            #if arch(arm64)
            let pointer = array.dataPointer.assumingMemoryBound(to: Float16.self)
            fill { Float(pointer[$0]) }
            #else
            return nil
            #endif
        default:
            return nil
        }
        return TileProbabilities(printed: printed, handwriting: handwriting)
    }
}
