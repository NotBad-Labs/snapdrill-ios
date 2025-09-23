// NotBadTests/Helpers/MockDataProvider.swift
// Load mock JSON files for previews/tests (test target only).

import Foundation
@testable import NotBad

struct MockDataProvider {
    // MARK: - Public: Specific loaders
    static func loadReviewSessions() -> [ReviewSession] {
        // Try common bundle locations first
        if let url = Bundle.main.url(forResource: "review_sessions", withExtension: "json")
            ?? Bundle.main.url(forResource: "review_sessions", withExtension: "json", subdirectory: "MockData")
            ?? Bundle.main.url(forResource: "review_sessions", withExtension: "json", subdirectory: "Resources/MockData") {
            return decodeSessions(from: url)
        }

        // DEBUG fallback: resolve relative to source tree for unit tests
        #if DEBUG
        let fileURL = resolveURL(relativePath: "NotBad/Resources/MockData/review_sessions.json")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return decodeSessions(from: fileURL)
        }
        #endif

        return []
    }

    // MARK: - Public: Generic loader
    static func loadDecodable<T: Decodable>(fromRelativePath relativePath: String, dateStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) throws -> T {
        let url = resolveURL(relativePath: relativePath)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateStrategy
        return try decoder.decode(T.self, from: data)
    }

    private static func decodeSessions(from url: URL) -> [ReviewSession] {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([ReviewSessionDTO_Testing].self, from: data).compactMap { $0.model }
        } catch {
            return []
        }
    }

    // MARK: - Path resolver
    private static func resolveURL(relativePath: String) -> URL {
        // Attempt to find in test bundle if present
        if let testBundleURL = Bundle(for: BundleMarker.self).url(forResource: (relativePath as NSString).deletingPathExtension, withExtension: (relativePath as NSString).pathExtension) {
            return testBundleURL
        }
        // Fallback: compute from this file's location up to project root
        let here = URL(fileURLWithPath: #filePath)
        let projectRoot = here.deletingLastPathComponent() // Helpers
            .deletingLastPathComponent() // NotBadTests
            .deletingLastPathComponent() // project root
        return projectRoot.appendingPathComponent(relativePath)
    }

    private final class BundleMarker {}
}

// DTO to bridge localized difficulty strings (renamed to avoid test-module name collision)
private struct ReviewSessionDTO_Testing: Decodable {
    let date: Date
    let wasSuccessful: Bool
    let difficulty: String

    var model: ReviewSession? {
        guard let diff = Self.mapDifficulty(difficulty) else { return nil }
        return ReviewSession(date: date, wasSuccessful: wasSuccessful, difficulty: diff)
    }

    private static func mapDifficulty(_ raw: String) -> ReviewItem.Difficulty? {
        switch raw {
        case "简单": return .easy
        case "中等": return .medium
        case "困难": return .hard
        default: return nil
        }
    }
}
