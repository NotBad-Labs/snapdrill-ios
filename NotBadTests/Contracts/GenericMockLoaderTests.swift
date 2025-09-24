// NotBadTests/Contracts/GenericMockLoaderTests.swift
// Validate the generic loader can decode DTOs from the same JSON.

import XCTest
@testable import NotBad

final class GenericMockLoaderTests: XCTestCase {
    func test_genericLoader_decodes_reviewSessionsDTO() throws {
        let dtos: [ReviewSessionDTO] = try MockDataProvider.loadDecodable(fromRelativePath: "NotBad/Resources/MockData/review_sessions.json")
        XCTAssertEqual(dtos.count, 3)
        XCTAssertEqual(dtos.first?.difficulty, "中等")
    }
}

// Expose a copy of DTO for this test target scope
private struct ReviewSessionDTO: Decodable {
    let date: Date
    let wasSuccessful: Bool
    let difficulty: String
}
