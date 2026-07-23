import CoreGraphics
import Foundation
import ImageIO
import UIKit
public nonisolated enum CanonicalJPEGError: Error, Equatable, Sendable { case invalidGrammar, byteLimitExceeded, decodeFailed, renderFailed, encodeFailed }
/// The single production implementation of the Backup v3 canonical JPEG grammar.
public nonisolated enum CanonicalJPEG {
    public static let maximumByteCount = 50 * 1_024 * 1_024
    public static let maximumDimension = 2_000
    public struct Metadata: Equatable, Sendable {
        public let width: Int
        public let height: Int
        public let componentCount: Int
        public let scanCount: Int
    }
    private static let fixedJFIF: [UInt8] = [
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46,
        0x00, 0x01, 0x02, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00
    ]
    public static func validate(_ data: Data) throws -> Metadata {
        guard data.count <= maximumByteCount else {
            throw CanonicalJPEGError.byteLimitExceeded
        }
        guard data.count >= fixedJFIF.count, data.starts(with: fixedJFIF) else {
            throw CanonicalJPEGError.invalidGrammar
        }
        var parser = RawParser(bytes: [UInt8](data), offset: fixedJFIF.count)
        let metadata = try parser.parse()
        try validateImageIO(data, metadata: metadata)
        return metadata
    }
    static func encode(
        _ image: UIImage,
        maxLongSide: Int = maximumDimension,
        quality: CGFloat = 0.8
    ) throws -> Data {
        guard (1...maximumDimension).contains(maxLongSide),
              quality.isFinite,
              (0...1).contains(quality),
              let source = image.cgImage else {
            throw CanonicalJPEGError.renderFailed
        }
        let orientedSize = orientedPixelSize(
            width: source.width,
            height: source.height,
            orientation: image.imageOrientation
        )
        let scale = min(1, CGFloat(maxLongSide) / CGFloat(max(orientedSize.width, orientedSize.height)))
        let width = max(1, Int(floor(CGFloat(orientedSize.width) * scale)))
        let height = max(1, Int(floor(CGFloat(orientedSize.height) * scale)))
        let rendered = try renderInSRGB(image, width: width, height: height)
        let encoded = try encodeImageIO(rendered, quality: quality)
        let normalized = try normalizeEncoderOutput(encoded)
        _ = try validate(normalized)
        return normalized
    }
    static func normalizeEncoderOutput(_ data: Data) throws -> Data {
        var normalizer = EncoderOutputNormalizer(bytes: [UInt8](data), output: fixedJFIF)
        return try normalizer.normalize()
    }
}
private nonisolated extension CanonicalJPEG {
    struct Frame {
        let width: Int
        let height: Int
        let components: [UInt8: UInt8]
        let componentIDs: [UInt8]
    }
    struct EncoderOutputNormalizer {
        let bytes: [UInt8]
        var output: [UInt8]
        var offset = 2
        mutating func normalize() throws -> Data {
            guard bytes.starts(with: [0xFF, 0xD8]) else {
                throw CanonicalJPEGError.invalidGrammar
            }
            while offset < bytes.count {
                let markerStart = offset
                let marker = try readMarker()
                if marker == 0xD9 {
                    guard offset == bytes.count else { throw CanonicalJPEGError.invalidGrammar }
                    output.append(contentsOf: [0xFF, 0xD9])
                    return Data(output)
                }
                let segmentEnd = try readSegmentEnd(marker: marker)
                if !(0xE0...0xEF).contains(marker), marker != 0xFE {
                    output.append(contentsOf: bytes[markerStart..<segmentEnd])
                }
                offset = segmentEnd
                if marker == 0xDA { try appendEntropy() }
            }
            throw CanonicalJPEGError.invalidGrammar
        }
        mutating func readMarker() throws -> UInt8 {
            guard offset + 2 <= bytes.count,
                  bytes[offset] == 0xFF,
                  bytes[offset + 1] != 0xFF else {
                throw CanonicalJPEGError.invalidGrammar
            }
            let marker = bytes[offset + 1]
            offset += 2
            return marker
        }
        func readSegmentEnd(marker: UInt8) throws -> Int {
            guard marker != 0x01,
                  marker != 0xD8,
                  !(0xD0...0xD7).contains(marker),
                  offset + 2 <= bytes.count else {
                throw CanonicalJPEGError.invalidGrammar
            }
            let length = bigEndian16(bytes, at: offset)
            guard length >= 2, offset + length <= bytes.count else {
                throw CanonicalJPEGError.invalidGrammar
            }
            return offset + length
        }
        mutating func appendEntropy() throws {
            let entropyStart = offset
            while offset < bytes.count {
                guard bytes[offset] == 0xFF else {
                    offset += 1
                    continue
                }
                guard offset + 1 < bytes.count else { throw CanonicalJPEGError.invalidGrammar }
                let marker = bytes[offset + 1]
                guard marker == 0x00 || (0xD0...0xD7).contains(marker) else { break }
                offset += 2
            }
            output.append(contentsOf: bytes[entropyStart..<offset])
        }
    }
    struct RawParser {
        let bytes: [UInt8]
        var offset: Int
        var quantizationTables = Set<UInt8>()
        var huffmanTables: [Int: Bool] = [:]
        var frame: Frame?
        var scannedComponents = Set<UInt8>()
        var restartInterval: Int?
        var scanCount = 0
        mutating func parse() throws -> Metadata {
            while offset < bytes.count {
                let marker = try readMarker()
                if marker == 0xD9 { return try finish() }
                let payload = try readPayload(marker: marker)
                try consume(marker: marker, payload: payload)
            }
            throw CanonicalJPEGError.invalidGrammar
        }
        mutating func readMarker() throws -> UInt8 {
            guard offset + 2 <= bytes.count,
                  bytes[offset] == 0xFF,
                  bytes[offset + 1] != 0xFF else {
                throw CanonicalJPEGError.invalidGrammar
            }
            let marker = bytes[offset + 1]
            offset += 2
            return marker
        }
        mutating func readPayload(marker: UInt8) throws -> [UInt8] {
            guard [0xC0, 0xC4, 0xDA, 0xDB, 0xDD].contains(marker),
                  offset + 2 <= bytes.count else {
                throw CanonicalJPEGError.invalidGrammar
            }
            let length = bigEndian16(bytes, at: offset)
            guard length >= 2, offset + length <= bytes.count else {
                throw CanonicalJPEGError.invalidGrammar
            }
            let payload = Array(bytes[(offset + 2)..<(offset + length)])
            offset += length
            return payload
        }
        mutating func consume(marker: UInt8, payload: [UInt8]) throws {
            switch marker {
            case 0xDB: try parseDQT(payload)
            case 0xC4: try parseDHT(payload)
            case 0xDD:
                guard restartInterval == nil, payload.count == 2 else {
                    throw CanonicalJPEGError.invalidGrammar
                }
                restartInterval = bigEndian16(payload, at: 0)
            case 0xC0:
                guard frame == nil else { throw CanonicalJPEGError.invalidGrammar }
                frame = try parseSOF(payload)
            case 0xDA:
                try parseSOS(payload)
                offset = try entropyEnd(from: offset)
            default: throw CanonicalJPEGError.invalidGrammar
            }
        }
        mutating func parseDQT(_ payload: [UInt8]) throws {
            var cursor = 0
            while cursor < payload.count {
                let info = payload[cursor]
                cursor += 1
                let precision = info >> 4
                let identifier = info & 0x0F
                guard precision <= 1, identifier <= 3 else {
                    throw CanonicalJPEGError.invalidGrammar
                }
                let size = 64 * (Int(precision) + 1)
                guard cursor + size <= payload.count,
                      !quantizationTables.contains(identifier) else {
                    throw CanonicalJPEGError.invalidGrammar
                }
                let values = payload[cursor..<(cursor + size)]
                if precision == 0 {
                    guard values.allSatisfy({ $0 != 0 }) else {
                        throw CanonicalJPEGError.invalidGrammar
                    }
                } else {
                    for index in stride(from: cursor, to: cursor + size, by: 2) {
                        guard payload[index] != 0 || payload[index + 1] != 0 else {
                            throw CanonicalJPEGError.invalidGrammar
                        }
                    }
                }
                quantizationTables.insert(identifier)
                cursor += size
            }
            guard cursor == payload.count else { throw CanonicalJPEGError.invalidGrammar }
        }
        mutating func parseDHT(_ payload: [UInt8]) throws {
            var cursor = 0
            var segmentDefinitions = Set<Int>()
            while cursor < payload.count {
                guard cursor + 17 <= payload.count else {
                    throw CanonicalJPEGError.invalidGrammar
                }
                let info = payload[cursor]
                cursor += 1
                let tableClass = info >> 4
                let identifier = info & 0x0F
                guard tableClass <= 1, identifier <= 3 else {
                    throw CanonicalJPEGError.invalidGrammar
                }
                let counts = payload[cursor..<(cursor + 16)]
                cursor += 16
                let symbolCount = counts.reduce(0) { $0 + Int($1) }
                guard (1...256).contains(symbolCount) else {
                    throw CanonicalJPEGError.invalidGrammar
                }
                var remainingCodes = 1
                for count in counts {
                    remainingCodes = remainingCodes * 2 - Int(count)
                    guard remainingCodes >= 0 else { throw CanonicalJPEGError.invalidGrammar }
                }
                guard cursor + symbolCount <= payload.count else {
                    throw CanonicalJPEGError.invalidGrammar
                }
                let symbols = Array(payload[cursor..<(cursor + symbolCount)])
                try validateHuffmanSymbols(symbols, tableClass: tableClass)
                let key = Int(tableClass) << 8 | Int(identifier)
                guard !segmentDefinitions.contains(key), huffmanTables[key] ?? true else {
                    throw CanonicalJPEGError.invalidGrammar
                }
                segmentDefinitions.insert(key)
                huffmanTables[key] = false
                cursor += symbolCount
            }
            guard cursor == payload.count else { throw CanonicalJPEGError.invalidGrammar }
        }
        func validateHuffmanSymbols(_ symbols: [UInt8], tableClass: UInt8) throws {
            guard Set(symbols).count == symbols.count else {
                throw CanonicalJPEGError.invalidGrammar
            }
            if tableClass == 0 {
                guard symbols.allSatisfy({ $0 <= 11 }) else {
                    throw CanonicalJPEGError.invalidGrammar
                }
                return
            }
            guard symbols.allSatisfy({ symbol in
                let size = symbol & 0x0F
                return size <= 10 && (size != 0 || [0, 15].contains(symbol >> 4))
            }) else {
                throw CanonicalJPEGError.invalidGrammar
            }
        }
        func parseSOF(_ payload: [UInt8]) throws -> Frame {
            guard payload.count >= 6,
                  payload[0] == 8 else {
                throw CanonicalJPEGError.invalidGrammar
            }
            let height = bigEndian16(payload, at: 1)
            let width = bigEndian16(payload, at: 3)
            let componentCount = Int(payload[5])
            guard (1...CanonicalJPEG.maximumDimension).contains(width),
                  (1...CanonicalJPEG.maximumDimension).contains(height),
                  [1, 3].contains(componentCount),
                  payload.count == 6 + 3 * componentCount else {
                throw CanonicalJPEGError.invalidGrammar
            }
            var components: [UInt8: UInt8] = [:]
            var componentIDs: [UInt8] = []
            var cursor = 6
            for _ in 0..<componentCount {
                let identifier = payload[cursor]
                let sampling = payload[cursor + 1]
                let quantization = payload[cursor + 2]
                cursor += 3
                let horizontal = sampling >> 4
                let vertical = sampling & 0x0F
                guard components[identifier] == nil,
                      (1...4).contains(horizontal),
                      (1...4).contains(vertical),
                      quantization <= 3 else {
                    throw CanonicalJPEGError.invalidGrammar
                }
                components[identifier] = quantization
                componentIDs.append(identifier)
            }
            guard componentIDs == (componentCount == 1 ? [1] : [1, 2, 3]) else {
                throw CanonicalJPEGError.invalidGrammar
            }
            return Frame(width: width, height: height, components: components, componentIDs: componentIDs)
        }
        mutating func parseSOS(_ payload: [UInt8]) throws {
            guard let frame,
                  payload.count >= 4 else {
                throw CanonicalJPEGError.invalidGrammar
            }
            let componentCount = Int(payload[0])
            guard (1...frame.components.count).contains(componentCount),
                  payload.count == 4 + 2 * componentCount else {
                throw CanonicalJPEGError.invalidGrammar
            }
            var components = Set<UInt8>()
            var references = Set<Int>()
            var cursor = 1
            for _ in 0..<componentCount {
                let identifier = payload[cursor]
                let tables = payload[cursor + 1]
                cursor += 2
                let dcTable = tables >> 4
                let acTable = tables & 0x0F
                guard frame.components[identifier] != nil,
                      !components.contains(identifier),
                      dcTable <= 3,
                      acTable <= 3 else {
                    throw CanonicalJPEGError.invalidGrammar
                }
                components.insert(identifier)
                references.insert(Int(dcTable))
                references.insert(1 << 8 | Int(acTable))
            }
            guard payload[cursor] == 0,
                  payload[cursor + 1] == 63,
                  payload[cursor + 2] == 0 else {
                throw CanonicalJPEGError.invalidGrammar
            }
            let requiredDQT = Set(components.compactMap { frame.components[$0] })
            guard requiredDQT.isSubset(of: quantizationTables),
                  references.isSubset(of: Set(huffmanTables.keys)),
                  scannedComponents.isDisjoint(with: components) else {
                throw CanonicalJPEGError.invalidGrammar
            }
            for reference in references { huffmanTables[reference] = true }
            scannedComponents.formUnion(components)
            scanCount += 1
            guard scanCount <= 3 else { throw CanonicalJPEGError.invalidGrammar }
        }
        func entropyEnd(from start: Int) throws -> Int {
            var cursor = start
            var expectedRestart: UInt8 = 0
            while cursor < bytes.count {
                guard bytes[cursor] == 0xFF else {
                    cursor += 1
                    continue
                }
                guard cursor + 1 < bytes.count else { throw CanonicalJPEGError.invalidGrammar }
                let marker = bytes[cursor + 1]
                if marker == 0x00 {
                    cursor += 2
                } else if (0xD0...0xD7).contains(marker) {
                    guard let restartInterval, restartInterval > 0,
                          marker == 0xD0 + expectedRestart else {
                        throw CanonicalJPEGError.invalidGrammar
                    }
                    expectedRestart = (expectedRestart + 1) % 8
                    cursor += 2
                } else {
                    guard marker != 0xFF else { throw CanonicalJPEGError.invalidGrammar }
                    return cursor
                }
            }
            throw CanonicalJPEGError.invalidGrammar
        }
        func finish() throws -> Metadata {
            guard offset == bytes.count,
                  let frame,
                  scanCount > 0,
                  scannedComponents == Set(frame.componentIDs),
                  Set(frame.components.values).isSubset(of: quantizationTables),
                  huffmanTables.values.allSatisfy({ $0 }) else {
                throw CanonicalJPEGError.invalidGrammar
            }
            return Metadata(
                width: frame.width,
                height: frame.height,
                componentCount: frame.components.count,
                scanCount: scanCount
            )
        }
    }
    static func bigEndian16(_ bytes: [UInt8], at offset: Int) -> Int {
        Int(bytes[offset]) << 8 | Int(bytes[offset + 1])
    }
    static func orientedPixelSize(
        width: Int,
        height: Int,
        orientation: UIImage.Orientation
    ) -> (width: Int, height: Int) {
        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            (height, width)
        default:
            (width, height)
        }
    }
    static func renderInSRGB(_ image: UIImage, width: Int, height: Int) throws -> CGImage {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue
                    | CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            throw CanonicalJPEGError.renderFailed
        }
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context.fill(bounds)
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        UIGraphicsPushContext(context)
        image.draw(in: bounds)
        UIGraphicsPopContext()
        guard let result = context.makeImage() else { throw CanonicalJPEGError.renderFailed }
        return result
    }
    static func encodeImageIO(_ image: CGImage, quality: CGFloat) throws -> Data {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            throw CanonicalJPEGError.encodeFailed
        }
        let properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw CanonicalJPEGError.encodeFailed
        }
        return output as Data
    }
    static func validateImageIO(_ data: Data, metadata: Metadata) throws {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetType(source) as String? == "public.jpeg",
              CGImageSourceGetCount(source) == 1,
              CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else {
            throw CanonicalJPEGError.decodeFailed
        }
        if let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
           let orientation = properties[kCGImagePropertyOrientation] as? NSNumber,
           orientation.intValue != 1 {
            throw CanonicalJPEGError.decodeFailed
        }
        let options: [CFString: Any] = [kCGImageSourceShouldCacheImmediately: true]
        guard let image = CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary),
              image.width == metadata.width,
              image.height == metadata.height,
              let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: image.width * 4,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue
                    | CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            throw CanonicalJPEGError.decodeFailed
        }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else { throw CanonicalJPEGError.decodeFailed }
    }
}
