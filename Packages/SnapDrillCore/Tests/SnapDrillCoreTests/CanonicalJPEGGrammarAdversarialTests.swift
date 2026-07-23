import Foundation
import Testing
@testable import SnapDrillCore

@Suite("Canonical JPEG effective grammar adversarial corpus")
struct CanonicalJPEGGrammarAdversarialTests {
    @Test("all 59 effective negative grammar cases fail closed")
    func effectiveNegativeCorpusFailsClosed() throws {
        let rgb = try fixture()
        let cases = try negativeCases(for: rgb)
        #expect(cases.count == 59)
        #expect(Set(cases.map(\.0)).count == cases.count)
        for (identifier, bytes) in cases {
            do {
                _ = try CanonicalJPEG.validate(bytes)
                Issue.record("accepted hostile JPEG case: \(identifier)")
            } catch CanonicalJPEGError.invalidGrammar {
                continue
            } catch {
                Issue.record("wrong error for \(identifier): \(error)")
            }
        }
    }

    private func negativeCases(for rgb: Data) throws -> [(String, Data)] {
        var cases: [(String, Data)] = []
        for marker in 0xE0...0xEF {
            cases.append(("APP\(marker - 0xE0)", insertAfterPrefix(rgb, segment(marker: UInt8(marker)))))
        }
        cases.append(("COM", insertAfterPrefix(rgb, segment(marker: 0xFE))))
        cases.append(("trailer", rgb + Data([0])))
        cases.append(("missing EOI", Data(rgb.dropLast(2))))
        cases.append(("truncated entropy marker", Data(rgb.dropLast(2)) + Data([0xFF])))
        cases.append(("entropy marker fill", insertEntropyMarker(rgb, marker: 0xFF)))
        cases.append(("RST without DRI", insertEntropyMarker(rgb, marker: 0xD0)))
        cases.append(("RST after zero DRI", insertEntropyMarker(insertDRI(rgb, interval: 0), marker: 0xD0)))
        cases.append(("RST sequence not zero", insertEntropyMarker(insertDRI(rgb, interval: 1), marker: 0xD1)))
        cases.append(("invalid DRI length", insertBeforeFirstScan(rgb, bytes: [0xFF, 0xDD, 0, 3, 1])))
        cases.append(("duplicate DRI", insertBeforeFirstScan(
            rgb,
            bytes: [0xFF, 0xDD, 0, 4, 0, 1, 0xFF, 0xDD, 0, 4, 0, 1]
        )))
        cases.append(("bad segment length", mutateSegmentLength(rgb)))
        cases.append(("zero DQT", mutatePayload(rgb, marker: 0xDB, offset: 1, value: 0)))
        cases.append(("DQT after scan", moveDQTAfterScan(rgb)))
        cases.append(("invalid DQT precision", mutatePayload(rgb, marker: 0xDB, offset: 0, value: 0x20)))
        cases.append(("invalid DQT identifier", mutatePayload(rgb, marker: 0xDB, offset: 0, value: 0x04)))
        cases.append(("duplicate DQT", duplicateSegment(rgb, marker: 0xDB)))
        cases.append(("oversubscribed DHT", mutateAbsolute(rgb, at: try first(rgb, marker: 0xC4).start + 5, value: 3)))
        cases.append(("invalid DHT class", mutatePayload(rgb, marker: 0xC4, offset: 0, value: 0x20)))
        cases.append(("invalid DHT identifier", mutatePayload(rgb, marker: 0xC4, offset: 0, value: 0x04)))
        cases.append(("empty DHT", emptyFirstDHT(rgb)))
        cases.append(("duplicate DHT symbol", duplicateFirstDHTSymbol(rgb)))
        cases.append(("invalid DC symbol", mutatePayload(rgb, marker: 0xC4, offset: 17, value: 12)))
        cases.append(("invalid AC symbol", invalidACHuffmanSymbol(rgb)))
        cases.append(("undefined DHT", undefinedHuffmanReference(rgb)))
        cases.append(("same-segment DHT duplicate", duplicateDHTInOneSegment(rgb)))
        cases.append(("unreferenced DHT replacement", duplicateSegment(rgb, marker: 0xC4)))
        cases.append(("unreferenced final DHT", appendUnreferencedDHT(rgb)))
        cases.append(("SOF precision", mutatePayload(rgb, marker: 0xC0, offset: 0, value: 12)))
        cases.append(("SOF width 2001", mutateSOFDimension(rgb, highOffset: 3)))
        cases.append(("SOF height 2001", mutateSOFDimension(rgb, highOffset: 1)))
        cases.append(("SOF component count", mutatePayload(rgb, marker: 0xC0, offset: 5, value: 2)))
        cases.append(("SOF component order", mutatePayload(rgb, marker: 0xC0, offset: 12, value: 4)))
        cases.append(("SOF sampling", mutatePayload(rgb, marker: 0xC0, offset: 7, value: 0x01)))
        cases.append(("SOF DQT identifier", mutatePayload(rgb, marker: 0xC0, offset: 8, value: 4)))
        cases.append(("duplicate SOF", duplicateSegment(rgb, marker: 0xC0)))
        cases.append(("SOF1", replaceMarker(rgb, original: 0xC0, replacement: 0xC1)))
        cases.append(("SOF2", replaceMarker(rgb, original: 0xC0, replacement: 0xC2)))
        cases.append(("missing SOF", removeSegment(rgb, marker: 0xC0)))
        cases.append(("missing SOS", removeSegment(rgb, marker: 0xDA)))
        cases.append(("unknown SOS component", mutatePayload(rgb, marker: 0xDA, offset: 1, value: 4)))
        cases.append(("duplicate SOS component", mutatePayload(rgb, marker: 0xDA, offset: 3, value: 1)))
        cases.append(("sequential spectral parameters", mutateSpectralStart(rgb)))
        cases.append(("duplicate component scan", duplicateSegment(rgb, marker: 0xDA)))
        return cases
    }

    private struct Span {
        let marker: UInt8
        let start: Int
        let end: Int
    }

    private func fixture() throws -> Data {
        let url = try #require(Bundle.module.url(
            forResource: "canonical-rgb-sof0-2x2",
            withExtension: "jpg",
            subdirectory: "CanonicalJPEG"
        ))
        return try Data(contentsOf: url)
    }

    private func spans(_ data: Data) throws -> [Span] {
        var result: [Span] = []
        var offset = 20
        while offset < data.count {
            let start = offset
            guard offset + 2 <= data.count, data[offset] == 0xFF else { throw MutationError.invalidFixture }
            let marker = data[offset + 1]
            offset += 2
            if marker == 0xD9 {
                result.append(Span(marker: marker, start: start, end: offset))
                break
            }
            guard offset + 2 <= data.count else { throw MutationError.invalidFixture }
            let length = Int(data[offset]) << 8 | Int(data[offset + 1])
            guard length >= 2, offset + length <= data.count else { throw MutationError.invalidFixture }
            offset += length
            if marker == 0xDA { offset = try entropyEnd(data, from: offset) }
            result.append(Span(marker: marker, start: start, end: offset))
        }
        return result
    }

    private func entropyEnd(_ data: Data, from start: Int) throws -> Int {
        var offset = start
        while offset < data.count {
            if data[offset] != 0xFF {
                offset += 1
                continue
            }
            guard offset + 1 < data.count else { throw MutationError.invalidFixture }
            let marker = data[offset + 1]
            if marker == 0 || (0xD0...0xD7).contains(marker) {
                offset += 2
            } else {
                return offset
            }
        }
        throw MutationError.invalidFixture
    }

    private func first(_ data: Data, marker: UInt8) throws -> Span {
        try #require(spans(data).first { $0.marker == marker })
    }

    private func segment(marker: UInt8) -> [UInt8] { [0xFF, marker, 0, 2] }

    private func insertAfterPrefix(_ data: Data, _ bytes: [UInt8]) -> Data {
        inserting(bytes, in: data, at: 20)
    }

    private func insertBeforeFirstScan(_ data: Data, bytes: [UInt8]) -> Data {
        guard let span = try? first(data, marker: 0xDA) else { return data }
        return inserting(bytes, in: data, at: span.start)
    }

    private func inserting(_ bytes: [UInt8], in data: Data, at offset: Int) -> Data {
        var result = data
        result.insert(contentsOf: bytes, at: offset)
        return result
    }

    private func mutatePayload(
        _ data: Data,
        marker: UInt8,
        offset: Int,
        value: UInt8,
        occurrence: Int = 0
    ) -> Data {
        guard let segments = try? spans(data).filter({ $0.marker == marker }),
              segments.indices.contains(occurrence) else { return data }
        return mutateAbsolute(data, at: segments[occurrence].start + 4 + offset, value: value)
    }

    private func mutateAbsolute(_ data: Data, at offset: Int, value: UInt8) -> Data {
        var result = data
        guard result.indices.contains(offset) else { return data }
        result[offset] = value
        return result
    }

    private func duplicateSegment(_ data: Data, marker: UInt8) -> Data {
        guard let span = try? first(data, marker: marker) else { return data }
        return inserting(Array(data[span.start..<span.end]), in: data, at: span.end)
    }

    private func removeSegment(_ data: Data, marker: UInt8) -> Data {
        guard let span = try? first(data, marker: marker) else { return data }
        var result = data
        result.removeSubrange(span.start..<span.end)
        return result
    }

    private func insertEntropyMarker(_ data: Data, marker: UInt8) -> Data {
        inserting([0xFF, marker], in: data, at: data.count - 2)
    }

    private func insertDRI(_ data: Data, interval: UInt16) -> Data {
        insertBeforeFirstScan(data, bytes: [0xFF, 0xDD, 0, 4, UInt8(interval >> 8), UInt8(interval & 0xFF)])
    }

    private func mutateSegmentLength(_ data: Data) -> Data {
        guard let span = try? first(data, marker: 0xDB) else { return data }
        var result = data
        result.replaceSubrange((span.start + 2)..<(span.start + 4), with: [0, 1])
        return result
    }

    private func moveDQTAfterScan(_ data: Data) -> Data {
        guard let span = try? first(data, marker: 0xDB) else { return data }
        let definition = Array(data[span.start..<span.end])
        var result = data
        result.removeSubrange(span.start..<span.end)
        result.insert(contentsOf: definition, at: result.count - 2)
        return result
    }

    private func emptyFirstDHT(_ data: Data) -> Data {
        guard let span = try? first(data, marker: 0xC4) else { return data }
        var result = data
        result.replaceSubrange((span.start + 5)..<(span.start + 21), with: [UInt8](repeating: 0, count: 16))
        return result
    }

    private func duplicateFirstDHTSymbol(_ data: Data) -> Data {
        guard let span = try? first(data, marker: 0xC4) else { return data }
        var result = data
        let symbol = span.start + 4 + 17
        result[symbol + 1] = result[symbol]
        return result
    }

    private func invalidACHuffmanSymbol(_ data: Data) -> Data {
        guard let segments = try? spans(data),
              let span = segments.first(where: { $0.marker == 0xC4 && data[$0.start + 4] >> 4 == 1 }) else {
            return data
        }
        return mutateAbsolute(data, at: span.start + 4 + 17, value: 0x0B)
    }

    private func undefinedHuffmanReference(_ data: Data) -> Data {
        guard let span = try? first(data, marker: 0xDA) else { return data }
        return mutateAbsolute(data, at: span.start + 6, value: 0x33)
    }

    private func duplicateDHTInOneSegment(_ data: Data) -> Data {
        guard let span = try? first(data, marker: 0xC4) else { return data }
        let payload = Array(data[(span.start + 4)..<span.end])
        let length = UInt16(2 + 2 * payload.count)
        let replacement = [0xFF, 0xC4, UInt8(length >> 8), UInt8(length & 0xFF)] + payload + payload
        var result = data
        result.replaceSubrange(span.start..<span.end, with: replacement)
        return result
    }

    private func appendUnreferencedDHT(_ data: Data) -> Data {
        let definition = [0xFF, 0xC4, 0, 0x14, 0x02, 0x01] + [UInt8](repeating: 0, count: 15) + [0]
        return inserting(definition, in: data, at: data.count - 2)
    }

    private func mutateSOFDimension(_ data: Data, highOffset: Int) -> Data {
        mutatePayload(
            mutatePayload(data, marker: 0xC0, offset: highOffset, value: 0x07),
            marker: 0xC0,
            offset: highOffset + 1,
            value: 0xD1
        )
    }

    private func replaceMarker(_ data: Data, original: UInt8, replacement: UInt8) -> Data {
        guard let span = try? first(data, marker: original) else { return data }
        return mutateAbsolute(data, at: span.start + 1, value: replacement)
    }

    private func mutateSpectralStart(_ data: Data) -> Data {
        guard let span = try? first(data, marker: 0xDA) else { return data }
        let componentCount = Int(data[span.start + 4])
        return mutateAbsolute(data, at: span.start + 5 + 2 * componentCount, value: 1)
    }

    private enum MutationError: Error { case invalidFixture }
}
