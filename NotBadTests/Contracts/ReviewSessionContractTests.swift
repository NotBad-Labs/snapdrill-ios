// NotBadTests/Contracts/ReviewSessionContractTests.swift
// Contract test to guard review_sessions.json schema and decoding behavior.

import XCTest
@testable import NotBad

final class ReviewSessionContractTests: XCTestCase {
    func test_decode_reviewSessions_json_fromSourceTree() throws {
        // Resolve JSON path from source tree to avoid bundle resource coupling.
        let here = URL(fileURLWithPath: #filePath)
        let projectRoot = here.deletingLastPathComponent() // Contracts
            .deletingLastPathComponent() // NotBadTests
            .deletingLastPathComponent() // project root
        let fileURL = projectRoot.appendingPathComponent("NotBad/Resources/MockData/review_sessions.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), "review_sessions.json should exist at expected path: \(fileURL.path)")

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dtos = try decoder.decode([ReviewSessionDTO].self, from: data)

        XCTAssertEqual(dtos.count, 3)
        XCTAssertEqual(dtos[0].difficulty, "中等")
        XCTAssertEqual(dtos[1].difficulty, "简单")
        XCTAssertEqual(dtos[2].difficulty, "困难")
    }

    func test_decode_reviewSessions_viaProvider_mapsToModel() {
        let sessions = MockDataProvider.loadReviewSessions()
        XCTAssertEqual(sessions.count, 3)
        XCTAssertEqual(sessions[0].difficulty, .medium)
        XCTAssertEqual(sessions[1].difficulty, .easy)
        XCTAssertEqual(sessions[2].difficulty, .hard)
        XCTAssertEqual(sessions[0].wasSuccessful, true)
        XCTAssertEqual(sessions[1].wasSuccessful, false)
        XCTAssertEqual(sessions[2].wasSuccessful, true)
    }
}

// Expose the DTO for tests; duplicate structure (internal in test module)
private struct ReviewSessionDTO: Decodable {
    let date: Date
    let wasSuccessful: Bool
    let difficulty: String
}
