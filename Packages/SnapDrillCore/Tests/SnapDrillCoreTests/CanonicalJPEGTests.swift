import CoreGraphics
import CryptoKit
import Foundation
import Testing
import UIKit
@testable import SnapDrillCore

@Suite("Canonical JPEG contract")
struct CanonicalJPEGTests {
    @Test("pinned RGB, gray, and 2000x2000 fixtures pass")
    func pinnedFixturesPass() throws {
        let fixtures = [
            FixtureCase(
                name: "canonical-rgb-sof0-2x2",
                width: 2,
                height: 2,
                components: 3,
                sha256: "3647831e9af68deb5207e1e97d1f34e8be1bd068af08eceb6119b823084e223d"
            ),
            FixtureCase(
                name: "canonical-gray-sof0-2x2",
                width: 2,
                height: 2,
                components: 1,
                sha256: "cc7988dede372bcbc20ed7419362c8cdf229d2d77989da7aaf9d01c9b7a43414"
            ),
            FixtureCase(
                name: "canonical-rgb-sof0-2000x2000",
                width: 2_000,
                height: 2_000,
                components: 3,
                sha256: "5307c20da2979646f422606035d5c8d22fba30f79c083a61fb945ee58487fdef"
            )
        ]
        for fixtureCase in fixtures {
            let bytes = try fixture(named: fixtureCase.name)
            let metadata = try CanonicalJPEG.validate(bytes)
            #expect(metadata.width == fixtureCase.width)
            #expect(metadata.height == fixtureCase.height)
            #expect(metadata.componentCount == fixtureCase.components)
            #expect((1...3).contains(metadata.scanCount))
            #expect(SHA256.hash(data: bytes).hex == fixtureCase.sha256)
        }
    }

    @Test("normalizer strips APP0 through APP15 and COM byte-exactly")
    func normalizerStripsMetadataContainers() throws {
        let valid = try fixture(named: "canonical-rgb-sof0-2x2")
        var segments: [UInt8] = []
        for marker in 0xE0...0xEF {
            segments.append(contentsOf: [0xFF, UInt8(marker), 0x00, 0x02])
        }
        segments.append(contentsOf: [0xFF, 0xFE, 0x00, 0x02])
        var metadataRich = valid
        metadataRich.insert(contentsOf: segments, at: 20)
        #expect(try CanonicalJPEG.normalizeEncoderOutput(metadataRich) == valid)
    }

    @Test("forbidden containers, frames, and trailers fail closed")
    func forbiddenMarkersAndTrailersFail() throws {
        let valid = try fixture(named: "canonical-rgb-sof0-2x2")
        let forbiddenMetadata = (0xE0...0xEF).map { marker in
            insertingSegment(marker: UInt8(marker), into: valid)
        }
        let forbiddenFrames: [UInt8] = [
            0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7,
            0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF
        ]
        let cases = forbiddenMetadata + forbiddenFrames.map {
            replacingFirstMarker(in: valid, from: 0xC0, to: $0)
        } + [
            insertingSegment(marker: 0xFE, into: valid),
            valid + Data([0x00]),
            valid + valid
        ]
        for bytes in cases {
            #expect(throws: CanonicalJPEGError.invalidGrammar) {
                try CanonicalJPEG.validate(bytes)
            }
        }
    }

    @Test("raw-valid input with incomplete ImageIO status fails the complete decode gate")
    func incompleteDecodeFails() throws {
        var incomplete = try fixture(named: "canonical-rgb-sof0-2x2")
        let sof = try markerOffset(0xC0, in: incomplete)
        incomplete[sof + 11] = 0x14
        #expect(throws: CanonicalJPEGError.decodeFailed) {
            try CanonicalJPEG.validate(incomplete)
        }
    }

    @Test("malformed tables, scans, frames, dimensions, and truncation fail closed")
    func malformedStructureFails() throws {
        let valid = try fixture(named: "canonical-rgb-sof0-2x2")
        var zeroQuantization = valid
        let dqt = try markerOffset(0xDB, in: zeroQuantization)
        zeroQuantization[dqt + 5] = 0
        var invalidScan = valid
        let sos = try markerOffset(0xDA, in: invalidScan)
        let sosLength = Int(invalidScan[sos + 2]) << 8 | Int(invalidScan[sos + 3])
        invalidScan[sos + 2 + sosLength - 1] = 1
        var zeroWidth = valid
        let sof = try markerOffset(0xC0, in: zeroWidth)
        zeroWidth[sof + 7] = 0
        zeroWidth[sof + 8] = 0
        var oversizedWidth = valid
        oversizedWidth[sof + 7] = 0x07
        oversizedWidth[sof + 8] = 0xD1
        var undefinedHuffman = valid
        undefinedHuffman[sos + 6] = 0x33
        var entropyFill = valid
        entropyFill.insert(contentsOf: [0xFF, 0xFF], at: entropyFill.count - 2)
        let cases: [Data] = [
            zeroQuantization,
            invalidScan,
            zeroWidth,
            oversizedWidth,
            undefinedHuffman,
            duplicateSegment(in: valid, marker: 0xDB),
            duplicateSegment(in: valid, marker: 0xC0),
            entropyFill,
            Data(valid.dropLast())
        ]
        for bytes in cases {
            #expect(throws: CanonicalJPEGError.invalidGrammar) {
                try CanonicalJPEG.validate(bytes)
            }
        }
    }

    @Test("50 MiB byte gate is inclusive and precedes grammar")
    func byteLimitStageIsExact() {
        let atLimit = Data(repeating: 0, count: CanonicalJPEG.maximumByteCount)
        #expect(throws: CanonicalJPEGError.invalidGrammar) { try CanonicalJPEG.validate(atLimit) }
        #expect(throws: CanonicalJPEGError.byteLimitExceeded) {
            try CanonicalJPEG.validate(atLimit + Data([0]))
        }
    }

    @Test("all eight orientations are baked into canonical pixels")
    func allOrientationsAreBaked() throws {
        let base = try #require(quadrantImage().cgImage)
        let cases: [(UIImage.Orientation, [PixelLabel])] = [
            (.up, [.red, .green, .blue, .yellow]),
            (.upMirrored, [.green, .red, .yellow, .blue]),
            (.down, [.yellow, .blue, .green, .red]),
            (.downMirrored, [.blue, .yellow, .red, .green]),
            (.leftMirrored, [.red, .blue, .green, .yellow]),
            (.right, [.blue, .red, .yellow, .green]),
            (.rightMirrored, [.yellow, .green, .blue, .red]),
            (.left, [.green, .yellow, .red, .blue])
        ]
        for (orientation, expected) in cases {
            let source = UIImage(cgImage: base, scale: 1, orientation: orientation)
            let encoded = try CanonicalJPEG.encode(source, quality: 0.95)
            _ = try CanonicalJPEG.validate(encoded)
            #expect(try cornerLabels(encoded) == expected, "orientation=\(orientation.rawValue)")
        }
    }

    @Test("sRGB, Display P3, CMYK, gray, and alpha inputs normalize to opaque canonical pixels")
    func colorAndAlphaInputsNormalize() throws {
        let sourceComponents: [CGFloat] = [0.8, 0.2, 0.1, 1]
        let inputs = [
            ColorCase(
                name: "sRGB",
                image: try rgbImage(space: try #require(CGColorSpace(name: CGColorSpace.sRGB)), components: sourceComponents),
                expectedRGB: [204, 51, 26]
            ),
            ColorCase(
                name: "Display P3",
                image: try rgbImage(space: try #require(CGColorSpace(name: CGColorSpace.displayP3)), components: sourceComponents),
                expectedRGB: [222, 24, 0]
            ),
            ColorCase(name: "CMYK", image: try cmykImage(), expectedRGB: [216, 35, 42]),
            ColorCase(name: "gray", image: try grayImage(), expectedRGB: [64, 64, 64])
        ]
        for input in inputs {
            let source = try #require(input.image.cgImage)
            let sourceRGB = try rgbValues(source, points: [(source.width / 2, source.height / 2)])[0]
            expectClose(sourceRGB, to: input.expectedRGB, tolerance: 2, name: "\(input.name) source")
            let encoded = try CanonicalJPEG.encode(input.image, quality: 0.95)
            expectClose(try centerRGB(encoded), to: input.expectedRGB, tolerance: 12, name: input.name)
            _ = try CanonicalJPEG.validate(encoded)
        }
        let transparent = transparentRedSquare()
        let encoded = try CanonicalJPEG.encode(transparent, quality: 0.95)
        let labels = try cornerLabels(encoded)
        #expect(labels == [.white, .white, .white, .white])
        #expect(try centerLabel(encoded) == .red)
    }

    private enum PixelLabel: Equatable { case red, green, blue, yellow, gray, white }

    private struct FixtureCase {
        let name: String
        let width: Int
        let height: Int
        let components: Int
        let sha256: String
    }

    private struct ColorCase {
        let name: String
        let image: UIImage
        let expectedRGB: [UInt8]
    }

    private func fixture(named name: String) throws -> Data {
        let url = try #require(Bundle.module.url(
            forResource: name,
            withExtension: "jpg",
            subdirectory: "CanonicalJPEG"
        ))
        return try Data(contentsOf: url)
    }

    private func markerOffset(_ marker: UInt8, in data: Data) throws -> Int {
        let bytes = [UInt8](data)
        return try #require(bytes.indices.dropLast().first {
            bytes[$0] == 0xFF && bytes[$0 + 1] == marker
        })
    }

    private func replacingFirstMarker(in data: Data, from: UInt8, to: UInt8) -> Data {
        var result = data
        if let offset = try? markerOffset(from, in: result) { result[offset + 1] = to }
        return result
    }

    private func insertingSegment(marker: UInt8, into data: Data) -> Data {
        var result = data
        result.insert(contentsOf: [0xFF, marker, 0x00, 0x02], at: 20)
        return result
    }

    private func duplicateSegment(in data: Data, marker: UInt8) -> Data {
        let bytes = [UInt8](data)
        guard let offset = try? markerOffset(marker, in: data), offset + 4 <= bytes.count else { return data }
        let length = Int(bytes[offset + 2]) << 8 | Int(bytes[offset + 3])
        guard offset + 2 + length <= bytes.count else { return data }
        var result = data
        result.insert(contentsOf: bytes[offset..<(offset + 2 + length)], at: offset + 2 + length)
        return result
    }

    private func quadrantImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 80))
        return renderer.image { context in
            let cells: [(UIColor, CGRect)] = [
                (.red, CGRect(x: 0, y: 0, width: 60, height: 40)),
                (.green, CGRect(x: 60, y: 0, width: 60, height: 40)),
                (.blue, CGRect(x: 0, y: 40, width: 60, height: 40)),
                (.yellow, CGRect(x: 60, y: 40, width: 60, height: 40))
            ]
            for (color, rect) in cells { color.setFill(); context.fill(rect) }
        }
    }

    private func rgbImage(space: CGColorSpace, components: [CGFloat]) throws -> UIImage {
        let context = try #require(CGContext(
            data: nil,
            width: 32,
            height: 32,
            bitsPerComponent: 8,
            bytesPerRow: 32 * 4,
            space: space,
            bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(try #require(CGColor(colorSpace: space, components: components)))
        context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
        return UIImage(cgImage: try #require(context.makeImage()))
    }

    private func cmykImage() throws -> UIImage {
        let bytes: [UInt8] = (0..<(32 * 32 * 4)).map { index in
            switch index % 4 {
            case 1, 2: 255
            default: 0
            }
        }
        return try componentImage(bytes: bytes, components: 4, space: CGColorSpaceCreateDeviceCMYK())
    }

    private func grayImage() throws -> UIImage {
        try componentImage(
            bytes: [UInt8](repeating: 64, count: 32 * 32),
            components: 1,
            space: CGColorSpaceCreateDeviceGray()
        )
    }

    private func componentImage(bytes: [UInt8], components: Int, space: CGColorSpace) throws -> UIImage {
        let data = Data(bytes) as CFData
        let provider = try #require(CGDataProvider(data: data))
        let image = try #require(CGImage(
            width: 32,
            height: 32,
            bitsPerComponent: 8,
            bitsPerPixel: components * 8,
            bytesPerRow: 32 * components,
            space: space,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ))
        return UIImage(cgImage: image)
    }

    private func transparentRedSquare() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 80), format: format)
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 30, y: 30, width: 20, height: 20))
        }
    }

    private func centerLabel(_ data: Data) throws -> PixelLabel {
        let image = try #require(UIImage(data: data)?.cgImage)
        return try labels(image, points: [(image.width / 2, image.height / 2)])[0]
    }

    private func centerRGB(_ data: Data) throws -> [UInt8] {
        let image = try #require(UIImage(data: data)?.cgImage)
        return try rgbValues(image, points: [(image.width / 2, image.height / 2)])[0]
    }

    private func cornerLabels(_ data: Data) throws -> [PixelLabel] {
        let image = try #require(UIImage(data: data)?.cgImage)
        return try labels(image, points: [
            (image.width / 4, image.height / 4),
            (3 * image.width / 4, image.height / 4),
            (image.width / 4, 3 * image.height / 4),
            (3 * image.width / 4, 3 * image.height / 4)
        ])
    }

    private func labels(_ image: CGImage, points: [(Int, Int)]) throws -> [PixelLabel] {
        try rgbValues(image, points: points).map {
            classify(red: $0[0], green: $0[1], blue: $0[2])
        }
    }

    private func rgbValues(_ image: CGImage, points: [(Int, Int)]) throws -> [[UInt8]] {
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        try pixels.withUnsafeMutableBytes { buffer in
            let context = try #require(CGContext(
                data: buffer.baseAddress,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: image.width * 4,
                space: space,
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
            ))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return points.map { point in
            let index = (point.1 * image.width + point.0) * 4
            return Array(pixels[index...(index + 2)])
        }
    }

    private func expectClose(_ actual: [UInt8], to expected: [UInt8], tolerance: Int, name: String) {
        #expect(actual.count == 3 && expected.count == 3)
        for index in 0..<min(actual.count, expected.count) {
            #expect(abs(Int(actual[index]) - Int(expected[index])) <= tolerance, "\(name) expected=\(expected) actual=\(actual)")
        }
    }

    private func classify(red: UInt8, green: UInt8, blue: UInt8) -> PixelLabel {
        if red > 220, green > 220, blue > 220 { return .white }
        if abs(Int(red) - Int(green)) < 25, abs(Int(green) - Int(blue)) < 25 { return .gray }
        if red > 150, green > 150, blue < 100 { return .yellow }
        if red > green, red > blue { return .red }
        if green > red, green > blue { return .green }
        return .blue
    }
}

private extension SHA256.Digest {
    var hex: String { map { String(format: "%02x", $0) }.joined() }
}
