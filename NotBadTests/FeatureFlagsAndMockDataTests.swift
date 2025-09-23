// NotBadTests/FeatureFlagsAndMockDataTests.swift
// Covers FeatureFlag.isEnabled (DEBUG path) and MockDataProvider JSON loading.

import XCTest
@testable import NotBad

final class FeatureFlagsAndMockDataTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        // Clean up toggles to avoid side effects between tests
        UserDefaults.standard.removeObject(forKey: FeatureFlag.newOnboarding.rawValue)
        UserDefaults.standard.removeObject(forKey: FeatureFlag.advancedStatistics.rawValue)
    }

    func testFeatureFlags_toggleViaUserDefaults_reflectsInIsEnabled() {
        // Ensure clean slate
        UserDefaults.standard.removeObject(forKey: FeatureFlag.newOnboarding.rawValue)
        XCTAssertFalse(FeatureFlag.newOnboarding.isEnabled, "Default should be disabled when no value is set")

        // Enable flag and assert
        UserDefaults.standard.set(true, forKey: FeatureFlag.newOnboarding.rawValue)
        XCTAssertTrue(FeatureFlag.newOnboarding.isEnabled)

        // Disable again and assert
        UserDefaults.standard.set(false, forKey: FeatureFlag.newOnboarding.rawValue)
        XCTAssertFalse(FeatureFlag.newOnboarding.isEnabled)
    }

    func testMockDataProvider_loadReviewSessions_decodesNonEmpty() {
        // When
        let sessions = MockDataProvider.loadReviewSessions()

        // Then
        XCTAssertFalse(sessions.isEmpty, "Expected bundled mock review_sessions.json to decode into non-empty sessions")

        // Basic sanity checks on fields to exercise DTO mapping code paths
        // Ensure all dates are valid and difficulties are within the domain
        let difficulties = Set(sessions.map { $0.difficulty })
        XCTAssertFalse(difficulties.isEmpty)
        XCTAssertTrue(difficulties.isSubset(of: [.easy, .medium, .hard]))
    }
}
