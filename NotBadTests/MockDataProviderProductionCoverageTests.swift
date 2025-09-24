import XCTest
@testable import NotBad

final class MockDataProviderProductionCoverageTests: XCTestCase {
    func testLoadReviewSessions_ProductionProvider_returnsNonEmpty_andMapsDifficulty() {
        // Explicitly qualify with module name to avoid picking the test helper with the same type name.
        let sessions = NotBad.MockDataProvider.loadReviewSessions()
        XCTAssertFalse(sessions.isEmpty, "Production MockDataProvider should load non-empty review sessions from project resources")
        // Sanity-check difficulties are mapped into domain enum values
        let allowed: Set<ReviewItem.Difficulty> = [.easy, .medium, .hard]
        XCTAssertTrue(sessions.contains { allowed.contains($0.difficulty) }, "At least one session should have a recognized difficulty mapping")
    }
}
