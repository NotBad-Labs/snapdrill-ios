//
//  ReviewItemTests.swift
//  NotBadTests
//
//  Created by Copilot on 9/22/25.
//

import XCTest
@testable import NotBad

final class ReviewItemTests: XCTestCase {

    // MARK: - Init & Validation
    func testInit_valid_succeeds() throws {
        let item = try ReviewItem(
            question: "1+1?",
            answer: "2",
            subject: .math,
            difficulty: .medium,
            tags: ["arithmetic"],
            notes: "simple",
            source: .manual
        )

        XCTAssertEqual(item.question, "1+1?")
        XCTAssertEqual(item.answer, "2")
        XCTAssertEqual(item.subject, .math)
        XCTAssertEqual(item.difficulty, .medium)
        XCTAssertEqual(item.tags, ["arithmetic"])
        XCTAssertEqual(item.notes, "simple")
        XCTAssertNil(item.lastReviewedDate)
        XCTAssertNil(item.nextReviewDate)
        XCTAssertEqual(item.proficiencyLevel, .notProficient)
        XCTAssertTrue(item.reviewHistory.isEmpty)
    }

    func testInit_emptyQuestion_throws() {
        XCTAssertThrowsError(try ReviewItem(
            question: "  \n  ",
            answer: "A",
            subject: .other
        )) { error in
            XCTAssertTrue(error is ReviewItemError)
            XCTAssertEqual(error as? ReviewItemError, .emptyQuestion)
        }
    }

    func testInit_emptyAnswer_throws() {
        XCTAssertThrowsError(try ReviewItem(
            question: "Q",
            answer: "\t  ",
            subject: .other
        )) { error in
            XCTAssertTrue(error is ReviewItemError)
            XCTAssertEqual(error as? ReviewItemError, .emptyAnswer)
        }
    }

    // MARK: - Update Content
    func testUpdateContent_updatesFieldsAndTimestamps() throws {
        var item = try ReviewItem(
            question: "Q1",
            answer: "A1",
            subject: .english,
            difficulty: .easy,
            tags: ["t1"],
            notes: "n1"
        )

        let originalUpdatedAt = item.updatedAt
        sleep(1) // ensure timestamp advances

        try item.updateContent(
            question: "Q2",
            answer: "A2",
            subject: .biology,
            difficulty: .hard,
            tags: ["t2", "t3"],
            notes: ""
        )

        XCTAssertEqual(item.question, "Q2")
        XCTAssertEqual(item.answer, "A2")
        XCTAssertEqual(item.subject, .biology)
        XCTAssertEqual(item.difficulty, .hard)
        XCTAssertEqual(item.tags, ["t2", "t3"])
        XCTAssertNil(item.notes) // empty string becomes nil
        XCTAssertTrue(item.updatedAt > originalUpdatedAt)
    }

    func testUpdateQuestion_and_UpdateAnswer_validation() throws {
        var item = try ReviewItem(
            question: "Q",
            answer: "A",
            subject: .history
        )

        // Valid updates
        try item.updateQuestion("Q2")
        try item.updateAnswer("A2")
        XCTAssertEqual(item.question, "Q2")
        XCTAssertEqual(item.answer, "A2")

        // Invalid updates
        XCTAssertThrowsError(try item.updateQuestion("   \n")) { error in
            XCTAssertEqual(error as? ReviewItemError, .emptyQuestion)
        }
        XCTAssertThrowsError(try item.updateAnswer("\t")) { error in
            XCTAssertEqual(error as? ReviewItemError, .emptyAnswer)
        }
    }

    func testUpdateNotes_emptyBecomesNil_andNonEmptyPersists() throws {
        var item = try ReviewItem(
            question: "Q",
            answer: "A",
            subject: .literature,
            notes: "foo"
        )
        let t1 = item.updatedAt
        sleep(1)
        item.updateNotes("")
        XCTAssertNil(item.notes)
        XCTAssertTrue(item.updatedAt > t1)

        let t2 = item.updatedAt
        sleep(1)
        item.updateNotes("bar")
        XCTAssertEqual(item.notes, "bar")
        XCTAssertTrue(item.updatedAt > t2)
    }

    // MARK: - Review Sessions
    func testAddReviewSession_updatesHistoryProficiencyAndNextDate() throws {
        var item = try ReviewItem(
            question: "Q",
            answer: "A",
            subject: .math,
            difficulty: .medium
        )

        let now = Date()
        let session = ReviewSession(date: now, wasSuccessful: true, difficulty: .medium)
        let prevUpdated = item.updatedAt
        item.addReviewSession(session)

        XCTAssertEqual(item.reviewHistory.count, 1)
        XCTAssertEqual(item.lastReviewedDate, now)
        XCTAssertNotNil(item.nextReviewDate)
        XCTAssertEqual(item.proficiencyLevel, .learning) // progressed on success
        XCTAssertTrue(item.updatedAt >= prevUpdated)

        if let next = item.nextReviewDate {
            // After success at learning + medium, base ~3 days
            XCTAssertGreaterThan(next.timeIntervalSince(now), 12 * 60 * 60) // > 12h
        }
    }

    func testRecordReviewResult_successIncreasesProficiencyAndSetsFutureNextDate() throws {
        var item = try ReviewItem(
            question: "Q",
            answer: "A",
            subject: .physics,
            difficulty: .medium
        )

        let before = Date()
        item.recordReviewResult(wasSuccessful: true)

        XCTAssertEqual(item.reviewHistory.count, 1)
        XCTAssertEqual(item.proficiencyLevel, .learning)
        XCTAssertNotNil(item.lastReviewedDate)
        XCTAssertNotNil(item.nextReviewDate)
        if let last = item.lastReviewedDate { XCTAssertGreaterThanOrEqual(last, before) }
        if let next = item.nextReviewDate, let last = item.lastReviewedDate {
            XCTAssertGreaterThan(next, last)
        }
    }

    func testRecordReviewResult_failureSetsShortNextDateAndDowngrades() throws {
        var item = try ReviewItem(
            question: "Q",
            answer: "A",
            subject: .chemistry,
            difficulty: .medium
        )

        // First, succeed twice to reach proficient
        item.recordReviewResult(wasSuccessful: true) // notProficient -> learning
        item.recordReviewResult(wasSuccessful: true) // learning -> proficient
        XCTAssertEqual(item.proficiencyLevel, .proficient)

        // Then fail to downgrade and set short next interval
        let before = item.lastReviewedDate
        item.recordReviewResult(wasSuccessful: false)
        XCTAssertEqual(item.proficiencyLevel, .learning) // downgrade from proficient -> learning
        XCTAssertEqual(item.reviewHistory.count, 3)
        XCTAssertNotNil(item.nextReviewDate)
        if let last = item.lastReviewedDate, let next = item.nextReviewDate {
            XCTAssertNotNil(before)
            XCTAssertGreaterThanOrEqual(last, before!)
            XCTAssertGreaterThan(next, last)
        }
    }

    func testNeedsReview_beforeAndAfterSession() throws {
        var item = try ReviewItem(
            question: "Q",
            answer: "A",
            subject: .english,
            difficulty: .medium
        )

        XCTAssertTrue(item.needsReview(on: Date())) // never reviewed

        item.recordReviewResult(wasSuccessful: true)
        XCTAssertFalse(item.needsReview(on: Date())) // nextReviewDate is future
    }
}
