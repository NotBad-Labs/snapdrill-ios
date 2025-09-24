// NotBadTests/ReviewItemStreakTests.swift
// Focus: cover ReviewItem.calculateCurrentStreak() and calculateLongestStreak()

import XCTest
@testable import NotBad

final class ReviewItemStreakTests: XCTestCase {
    func testCalculateStreaks_wrapsHistoryCorrectly() throws {
        var item = try ReviewItem(
            question: "Q",
            answer: "A",
            subject: .math,
            difficulty: .medium
        )

        // Sequence: T, T, F, T, T => current=2, longest=2
        item.recordReviewResult(wasSuccessful: true)
        item.recordReviewResult(wasSuccessful: true)
        item.recordReviewResult(wasSuccessful: false)
        item.recordReviewResult(wasSuccessful: true)
        item.recordReviewResult(wasSuccessful: true)

        XCTAssertEqual(item.calculateCurrentStreak(), 2)
        XCTAssertEqual(item.calculateLongestStreak(), 2)
    }

    func testCalculateStreaks_withLongerRun() throws {
        var item = try ReviewItem(
            question: "Q2",
            answer: "A2",
            subject: .physics,
            difficulty: .easy
        )

        // Sequence: F, T, T, T, F, T => current=1, longest=3
        item.recordReviewResult(wasSuccessful: false)
        item.recordReviewResult(wasSuccessful: true)
        item.recordReviewResult(wasSuccessful: true)
        item.recordReviewResult(wasSuccessful: true)
        item.recordReviewResult(wasSuccessful: false)
        item.recordReviewResult(wasSuccessful: true)

        XCTAssertEqual(item.calculateCurrentStreak(), 1)
        XCTAssertEqual(item.calculateLongestStreak(), 3)
    }
}
