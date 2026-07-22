import CoreGraphics
import CryptoKit
import Foundation
import ImageIO

struct DecodedImage {
    let width: Int
    let height: Int
    let pixels: Data
}

func decode(_ path: String) -> DecodedImage {
    let url = URL(fileURLWithPath: path)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        fatalError("cannot open \(path)")
    }
    guard CGImageSourceGetCount(source) == 1 else {
        fatalError("image count is not one: \(path)")
    }
    guard CGImageSourceGetStatus(source) == .statusComplete else {
        fatalError("source status is incomplete: \(path)")
    }
    guard CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else {
        fatalError("index status is incomplete: \(path)")
    }
    if
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
            as? [CFString: Any],
        let orientation = properties[kCGImagePropertyOrientation] as? NSNumber,
        orientation.intValue != 1
    {
        fatalError("orientation is not one: \(path)")
    }
    guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("cannot decode \(path)")
    }
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        fatalError("cannot create sRGB color space")
    }

    let bytesPerRow = image.width * 4
    var pixels = Data(count: bytesPerRow * image.height)
    pixels.withUnsafeMutableBytes { rawBuffer in
        guard let address = rawBuffer.baseAddress else {
            fatalError("cannot access decode buffer")
        }
        guard
            let context = CGContext(
                data: address,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue
                    | CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            fatalError("cannot create decode context")
        }
        context.interpolationQuality = .none
        context.draw(
            image,
            in: CGRect(x: 0, y: 0, width: image.width, height: image.height)
        )
    }
    return DecodedImage(width: image.width, height: image.height, pixels: pixels)
}

guard CommandLine.arguments.count == 3 else {
    fatalError("usage: verify-jpeg-imageio.swift source.jpg normalized.jpg")
}

let source = decode(CommandLine.arguments[1])
let normalized = decode(CommandLine.arguments[2])
guard source.width == normalized.width, source.height == normalized.height else {
    fatalError("decoded dimensions differ")
}
guard source.pixels == normalized.pixels else {
    fatalError("decoded pixels differ")
}
let digest = SHA256.hash(data: normalized.pixels)
    .map { String(format: "%02x", $0) }
    .joined()
print(
    "PASS ImageIO full decode \(source.width)x\(source.height) "
        + "rgba_sha256=\(digest)"
)
