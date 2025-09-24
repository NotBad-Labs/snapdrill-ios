import XCTest
@testable import NotBad

private struct SmallDTO_Prod: Codable, Equatable {
    let name: String
    let count: Int
}

final class MockDataProviderProductionMoreTests: XCTestCase {

    func testProduction_loadDecodable_success_readsFileFromProjectTree() throws {
        // Arrange: create a small JSON file under the repo mock data directory
        let here = URL(fileURLWithPath: #filePath)
        let projectRoot = here.deletingLastPathComponent() // NotBadTests
            .deletingLastPathComponent() // project root
        let mockDir = projectRoot.appendingPathComponent("NotBad/Resources/MockData")
        try? FileManager.default.createDirectory(at: mockDir, withIntermediateDirectories: true)
        let fileURL = mockDir.appendingPathComponent("sample_small_prod.json")
        let expected = SmallDTO_Prod(name: "beta", count: 7)
        let jsonData = try JSONEncoder().encode(expected)
        try jsonData.write(to: fileURL, options: .atomic)

        // Act
        let loaded: SmallDTO_Prod = try NotBad.MockDataProvider.loadDecodable(fromRelativePath: "NotBad/Resources/MockData/sample_small_prod.json")

        // Assert
        XCTAssertEqual(loaded, expected)

        // Cleanup
        try? FileManager.default.removeItem(at: fileURL)
    }

    func testProduction_loadDecodable_missingFile_throwsFileNotFound() {
        XCTAssertThrowsError(try NotBad.MockDataProvider.loadDecodable(fromRelativePath: "NotBad/Resources/MockData/does_not_exist_prod_12345.json") as SmallDTO_Prod) { error in
            let ns = error as NSError
            XCTAssertEqual(ns.domain, NSCocoaErrorDomain)
            XCTAssertEqual(ns.code, NSFileReadNoSuchFileError)
        }
    }

    func testProduction_loadDecodable_invalidJSON_throwsDecodingError() throws {
        // Arrange
        let here = URL(fileURLWithPath: #filePath)
        let projectRoot = here.deletingLastPathComponent().deletingLastPathComponent()
        let mockDir = projectRoot.appendingPathComponent("NotBad/Resources/MockData")
        try? FileManager.default.createDirectory(at: mockDir, withIntermediateDirectories: true)
        let fileURL = mockDir.appendingPathComponent("invalid_small_prod.json")
        try Data("{".utf8).write(to: fileURL, options: .atomic)

        // Act/Assert
        XCTAssertThrowsError(try NotBad.MockDataProvider.loadDecodable(fromRelativePath: "NotBad/Resources/MockData/invalid_small_prod.json") as SmallDTO_Prod)

        // Cleanup
        try? FileManager.default.removeItem(at: fileURL)
    }

    func testProduction_loadDecodable_supportsDateStrategies_iso8601_and_secondsSince1970() throws {
        struct WithDate: Codable, Equatable { let at: Date }
        let here = URL(fileURLWithPath: #filePath)
        let projectRoot = here.deletingLastPathComponent().deletingLastPathComponent()
        let mockDir = projectRoot.appendingPathComponent("NotBad/Resources/MockData")
        try? FileManager.default.createDirectory(at: mockDir, withIntermediateDirectories: true)

        // ISO8601
        let isoURL = mockDir.appendingPathComponent("date_iso_prod.json")
        let isoDate = Date(timeIntervalSince1970: 1_700_000_123)
        let isoEncoder = JSONEncoder(); isoEncoder.dateEncodingStrategy = .iso8601
        try isoEncoder.encode(WithDate(at: isoDate)).write(to: isoURL, options: .atomic)
        let isoDecoded: WithDate = try NotBad.MockDataProvider.loadDecodable(fromRelativePath: "NotBad/Resources/MockData/date_iso_prod.json", dateStrategy: .iso8601)
        XCTAssertEqual(isoDecoded, WithDate(at: isoDate))

        // secondsSince1970
        let secURL = mockDir.appendingPathComponent("date_sec_prod.json")
        let secDate = Date(timeIntervalSince1970: 1_800_000_123)
        let secEncoder = JSONEncoder(); secEncoder.dateEncodingStrategy = .secondsSince1970
        try secEncoder.encode(WithDate(at: secDate)).write(to: secURL, options: .atomic)
        let secDecoded: WithDate = try NotBad.MockDataProvider.loadDecodable(fromRelativePath: "NotBad/Resources/MockData/date_sec_prod.json", dateStrategy: .secondsSince1970)
        XCTAssertEqual(secDecoded, WithDate(at: secDate))

        // Cleanup
        try? FileManager.default.removeItem(at: isoURL)
        try? FileManager.default.removeItem(at: secURL)
    }
}
