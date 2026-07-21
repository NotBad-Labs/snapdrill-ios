import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let width = 2_000
let height = 2_000
let bytesPerPixel = 3
let bytesPerRow = width * bytesPerPixel

var pixels = Data(count: bytesPerRow * height)
pixels.withUnsafeMutableBytes { rawBuffer in
    guard let bytes = rawBuffer.bindMemory(to: UInt8.self).baseAddress else {
        return
    }
    for y in 0 ..< height {
        for x in 0 ..< width {
            let offset = y * bytesPerRow + x * bytesPerPixel
            bytes[offset] = UInt8(x * 255 / (width - 1))
            bytes[offset + 1] = UInt8(y * 255 / (height - 1))
            bytes[offset + 2] = ((x / 125) ^ (y / 125)).isMultiple(of: 2)
                ? 48
                : 208
        }
    }
}

guard
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
    let provider = CGDataProvider(data: pixels as CFData),
    let image = CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 24,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )
else {
    fatalError("cannot construct deterministic source image")
}

let output: URL
if CommandLine.arguments.count == 2 {
    output = URL(fileURLWithPath: CommandLine.arguments[1])
} else {
    output = FileManager.default.temporaryDirectory
        .appendingPathComponent("snapdrill-v3-canonical-2000x2000.jpg")
}
if FileManager.default.fileExists(atPath: output.path) {
    do {
        try FileManager.default.removeItem(at: output)
    } catch {
        fatalError("cannot remove prior output: \(error)")
    }
}

guard
    let destination = CGImageDestinationCreateWithURL(
        output as CFURL,
        UTType.jpeg.identifier as CFString,
        1,
        nil
    )
else {
    fatalError("cannot create JPEG destination")
}

CGImageDestinationAddImage(
    destination,
    image,
    [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary
)
guard CGImageDestinationFinalize(destination) else {
    fatalError("cannot finalize JPEG")
}

let attributes = try FileManager.default.attributesOfItem(atPath: output.path)
let byteCount = attributes[.size] as? NSNumber
print("output=\(output.path)")
print("byte_count=\(byteCount?.intValue ?? -1)")
