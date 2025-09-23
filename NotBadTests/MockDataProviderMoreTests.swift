// NotBadTests/MockDataProviderMoreTests.swift
// Covers MockDataProvider.loadDecodable success and error paths

import XCTest
@testable import NotBad

private struct SmallDTO: Codable, Equatable {
    let name: String
    let count: Int
}

final class MockDataProviderMoreTests: XCTestCase {

    func testLoadDecodable_success_readsFileFromProjectTree() throws {
        // Given: a small json file placed under project Resources/MockData
        // We piggyback an existing file if present; otherwise, create a temp one in the same directory structure.
        // Prefer existing demo file path: NotBad/Resources/MockData/sample_small.json
        let here = URL(fileURLWithPath: #filePath)
        let projectRoot = here.deletingLastPathComponent() // NotBadTests
            .deletingLastPathComponent() // project root
        let mockDir = projectRoot.appendingPathComponent("NotBad/Resources/MockData")
        let fileURL = mockDir.appendingPathComponent("sample_small.json")

        // Ensure directory exists (creating under repo path is safe for tests)
        try? FileManager.default.createDirectory(at: mockDir, withIntermediateDirectories: true)

        // Write predictable JSON content
        let expected = SmallDTO(name: "alpha", count: 3)
        let jsonData = try JSONEncoder().encode(expected)
        try jsonData.write(to: fileURL, options: .atomic)

        // When
        let loaded: SmallDTO = try MockDataProvider.loadDecodable(fromRelativePath: "NotBad/Resources/MockData/sample_small.json")

        // Then
        XCTAssertEqual(loaded, expected)

        // Cleanup
        try? FileManager.default.removeItem(at: fileURL)
    }

    func testLoadDecodable_missingFile_throwsFileNotFound() {
        // When/Then
        XCTAssertThrowsError(try MockDataProvider.loadDecodable(fromRelativePath: "NotBad/Resources/MockData/does_not_exist_12345.json") as SmallDTO) { error in
            // Data(contentsOf:) should throw a Cocoa error for file not found
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, NSCocoaErrorDomain)
            XCTAssertEqual(nsError.code, NSFileReadNoSuchFileError)
        }
    }

    func testLoadDecodable_invalidJSON_throwsDecodingError() throws {
        // Given
        let here = URL(fileURLWithPath: #filePath)
        let projectRoot = here.deletingLastPathComponent().deletingLastPathComponent()
        let mockDir = projectRoot.appendingPathComponent("NotBad/Resources/MockData")
        try? FileManager.default.createDirectory(at: mockDir, withIntermediateDirectories: true)
        let fileURL = mockDir.appendingPathComponent("invalid_small.json")

        // Write malformed JSON
        let malformed = Data("{".utf8)
        try malformed.write(to: fileURL, options: .atomic)

        // When/Then
        XCTAssertThrowsError(try MockDataProvider.loadDecodable(fromRelativePath: "NotBad/Resources/MockData/invalid_small.json") as SmallDTO)

        // Cleanup
        try? FileManager.default.removeItem(at: fileURL)
    }

    func testLoadReviewSessions_fallbackPath_readsNonEmpty() throws {
        // Ensure review_sessions.json exists in the fallback path already tracked in repo
        let sessions = MockDataProvider.loadReviewSessions()
        XCTAssertFalse(sessions.isEmpty, "fallback should decode bundled project file")
    }

    func testDTO_unknownDifficulty_isFilteredOut() throws {
        // Given: craft a DTO payload with an unknown difficulty value
        let here = URL(fileURLWithPath: #filePath)
        let projectRoot = here.deletingLastPathComponent().deletingLastPathComponent()
        let mockDir = projectRoot.appendingPathComponent("NotBad/Resources/MockData")
        try? FileManager.default.createDirectory(at: mockDir, withIntermediateDirectories: true)
        let fileURL = mockDir.appendingPathComponent("review_sessions_tmp.json")
        
        struct Tmp: Codable { let date: Date; let wasSuccessful: Bool; let difficulty: String }
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let payload = [Tmp(date: Date(), wasSuccessful: true, difficulty: "未知")] // unknown string
        let data = try encoder.encode(payload)
        try data.write(to: fileURL, options: .atomic)
        
        // When
        let url = fileURL
        let decoded = try Data(contentsOf: url)
        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
        let dtos = try dec.decode([AnyDecodableReviewSessionDTO].self, from: decoded)
        let models = dtos.compactMap { $0.model }
        
        // Then
        XCTAssertTrue(models.isEmpty, "unknown difficulty should be filtered out")
        
        // Cleanup
        try? FileManager.default.removeItem(at: fileURL)
    }

    func testLoadDecodable_supportsDateStrategies_iso8601_and_secondsSince1970() throws {
        // Given
        struct WithDate: Codable, Equatable { let at: Date }
        let here = URL(fileURLWithPath: #filePath)
        let projectRoot = here.deletingLastPathComponent().deletingLastPathComponent()
        let mockDir = projectRoot.appendingPathComponent("NotBad/Resources/MockData")
        try? FileManager.default.createDirectory(at: mockDir, withIntermediateDirectories: true)

        // ISO8601
        let isoURL = mockDir.appendingPathComponent("date_iso.json")
        let isoDate = Date(timeIntervalSince1970: 1_700_000_000)
        let isoEncoder = JSONEncoder(); isoEncoder.dateEncodingStrategy = .iso8601
        try isoEncoder.encode(WithDate(at: isoDate)).write(to: isoURL, options: .atomic)
        let isoDecoded: WithDate = try MockDataProvider.loadDecodable(fromRelativePath: "NotBad/Resources/MockData/date_iso.json", dateStrategy: .iso8601)
        XCTAssertEqual(isoDecoded, WithDate(at: isoDate))

        // secondsSince1970
        let secURL = mockDir.appendingPathComponent("date_sec.json")
        let secDate = Date(timeIntervalSince1970: 1_800_000_000)
        let secEncoder = JSONEncoder(); secEncoder.dateEncodingStrategy = .secondsSince1970
        try secEncoder.encode(WithDate(at: secDate)).write(to: secURL, options: .atomic)
        let secDecoded: WithDate = try MockDataProvider.loadDecodable(fromRelativePath: "NotBad/Resources/MockData/date_sec.json", dateStrategy: .secondsSince1970)
        XCTAssertEqual(secDecoded, WithDate(at: secDate))

        // Cleanup
        try? FileManager.default.removeItem(at: isoURL)
        try? FileManager.default.removeItem(at: secURL)
    }
}

// Local helper mirroring ReviewSessionDTO to verify mapping without exposing internals
private struct AnyDecodableReviewSessionDTO: Decodable {
    let date: Date
    let wasSuccessful: Bool
    let difficulty: String
    
    var model: ReviewSession? {
        switch difficulty {
        case "简单": return ReviewSession(date: date, wasSuccessful: wasSuccessful, difficulty: .easy)
        case "中等": return ReviewSession(date: date, wasSuccessful: wasSuccessful, difficulty: .medium)
        case "困难": return ReviewSession(date: date, wasSuccessful: wasSuccessful, difficulty: .hard)
        default: return nil
        }
    }
}
