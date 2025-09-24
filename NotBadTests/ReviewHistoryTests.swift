//
//  ReviewHistoryTests.swift
//  NotBadTests
//
//  Created by Yiming Liao on 9/21/25.
//

import XCTest
@testable import NotBad

final class ReviewHistoryTests: XCTestCase {
    
    func testEmptyHistory() {
        // Given
        let history = ReviewHistory()
        
        // When & Then
        XCTAssertTrue(history.isEmpty)
        XCTAssertEqual(history.count, 0)
        XCTAssertEqual(history.getCurrentStreak(), 0)
        XCTAssertEqual(history.getLongestStreak(), 0)
    }
    
    func testAddSession() {
        // Given
        var history = ReviewHistory()
        let session = ReviewSession(
            date: Date(),
            wasSuccessful: true,
            difficulty: .medium
        )
        
        // When
        history.addSession(session)
        
        // Then
        XCTAssertFalse(history.isEmpty)
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.lastSession, session)
    }
    
    func testGetStatistics() {
        // Given
        var history = ReviewHistory()
        let sessions = [
            ReviewSession(date: Date().addingTimeInterval(-300), wasSuccessful: true, difficulty: .easy),
            ReviewSession(date: Date().addingTimeInterval(-200), wasSuccessful: false, difficulty: .medium),
            ReviewSession(date: Date().addingTimeInterval(-100), wasSuccessful: true, difficulty: .hard),
            ReviewSession(date: Date(), wasSuccessful: true, difficulty: .medium)
        ]
        
        sessions.forEach { history.addSession($0) }
        
        // When
        let stats = history.getStatistics()
        
        // Then
        XCTAssertEqual(stats.totalReviews, 4)
        XCTAssertEqual(stats.successfulReviews, 3)
        XCTAssertEqual(stats.successRate, 0.75, accuracy: 0.01)
        XCTAssertEqual(stats.currentStreak, 2) // 最后两次成功
        XCTAssertEqual(stats.longestStreak, 2)
    }
    
    func testCurrentStreak() {
        // Given
        var history = ReviewHistory()
        let sessions = [
            ReviewSession(date: Date().addingTimeInterval(-400), wasSuccessful: true, difficulty: .easy),
            ReviewSession(date: Date().addingTimeInterval(-300), wasSuccessful: true, difficulty: .medium),
            ReviewSession(date: Date().addingTimeInterval(-200), wasSuccessful: false, difficulty: .medium),
            ReviewSession(date: Date().addingTimeInterval(-100), wasSuccessful: true, difficulty: .hard),
            ReviewSession(date: Date(), wasSuccessful: true, difficulty: .medium)
        ]
        
        sessions.forEach { history.addSession($0) }
        
        // When
        let currentStreak = history.getCurrentStreak()
        
        // Then
        XCTAssertEqual(currentStreak, 2) // 最后两次连续成功
    }
    
    func testLongestStreak() {
        // Given
        var history = ReviewHistory()
        let sessions = [
            ReviewSession(date: Date().addingTimeInterval(-500), wasSuccessful: true, difficulty: .easy),
            ReviewSession(date: Date().addingTimeInterval(-400), wasSuccessful: true, difficulty: .medium),
            ReviewSession(date: Date().addingTimeInterval(-300), wasSuccessful: true, difficulty: .medium),
            ReviewSession(date: Date().addingTimeInterval(-200), wasSuccessful: false, difficulty: .medium),
            ReviewSession(date: Date().addingTimeInterval(-100), wasSuccessful: true, difficulty: .hard),
            ReviewSession(date: Date(), wasSuccessful: true, difficulty: .medium)
        ]
        
        sessions.forEach { history.addSession($0) }
        
        // When
        let longestStreak = history.getLongestStreak()
        
        // Then
        XCTAssertEqual(longestStreak, 3) // 开始的三次连续成功
    }
    
    func testGetSessionsInDateRange() {
        // Given
        var history = ReviewHistory()
        let now = Date()
        let yesterday = now.addingTimeInterval(-24*60*60)
        let twoDaysAgo = now.addingTimeInterval(-2*24*60*60)
        
        let sessions = [
            ReviewSession(date: twoDaysAgo, wasSuccessful: true, difficulty: .easy),
            ReviewSession(date: yesterday, wasSuccessful: false, difficulty: .medium),
            ReviewSession(date: now, wasSuccessful: true, difficulty: .hard)
        ]
        
        sessions.forEach { history.addSession($0) }
        
        // When
        let recentSessions = history.getSessionsInDateRange(yesterday, now)
        
        // Then
        XCTAssertEqual(recentSessions.count, 2)
    }
    
    func testGetRecentSessions() {
        // Given
        var history = ReviewHistory()
        let sessions = (1...5).map { i in
            ReviewSession(
                date: Date().addingTimeInterval(Double(-i * 100)),
                wasSuccessful: i % 2 == 0,
                difficulty: .medium
            )
        }
        
        sessions.forEach { history.addSession($0) }
        
        // When
        let recent = history.getRecentSessions(count: 3)
        
        // Then
        XCTAssertEqual(recent.count, 3)
        // 应该是最近的3个（按时间排序）
    }
}