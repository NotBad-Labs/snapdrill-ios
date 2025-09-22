// NotBadTests/ReviewCompletionRateTests.swift
// TDD example: start with failing tests for a new domain behavior.

import XCTest
@testable import NotBad

final class ReviewCompletionRateTests: XCTestCase {
    // Helper to make a date offset by day components from a base
    private func day(_ offset: Int, from base: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: offset, to: base) ?? base
    }

    func testCompletionRate_last7Days_twoDaysHaveSessions_isTwoSeventh() {
        // Given: a base today and history with sessions on -1d and -2d
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sessions = [
            ReviewSession(date: day(-2, from: today), wasSuccessful: true, difficulty: .medium),
            ReviewSession(date: day(-1, from: today), wasSuccessful: false, difficulty: .easy),
        ]
        let history = ReviewHistory(sessions: sessions)

        // When: compute completion rate for last 7 days (inclusive today window)
        // Then: 2 unique days with sessions out of 7 days window = 2/7 ≈ 0.2857
        // Note: We assert with accuracy tolerance
        let rate = history.completionRate(lastNDays: 7, calendar: calendar)
        XCTAssertEqual(rate, 2.0/7.0, accuracy: 0.0001)
    }

    func testCompletionRate_emptyHistory_isZero() {
        let history = ReviewHistory()
        let rate = history.completionRate(lastNDays: 7)
        XCTAssertEqual(rate, 0.0)
    }

    func testCompletionRate_zeroDays_isZero() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sessions = [ReviewSession(date: today, wasSuccessful: true, difficulty: .hard)]
        let history = ReviewHistory(sessions: sessions)
        let rate = history.completionRate(lastNDays: 0)
        XCTAssertEqual(rate, 0.0)
    }
}
