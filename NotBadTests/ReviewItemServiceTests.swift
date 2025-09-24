//
//  ReviewItemServiceTests.swift
//  NotBadTests
//
//  Created by Copilot on 9/22/25.
//

import XCTest
@testable import NotBad

final class ReviewItemServiceTests: XCTestCase {
    var repository: InMemoryReviewItemRepository!
    var service: ReviewItemService!

    override func setUp() async throws {
        try await super.setUp()
        repository = InMemoryReviewItemRepository()
        service = ReviewItemService(repository: repository)
    }

    override func tearDown() async throws {
        #if DEBUG
        await repository.clear()
        #endif
        repository = nil
        service = nil
        try await super.tearDown()
    }

    func testCreateAndGetItem_defaultsAndEnums() async throws {
        let id = try await service.createReviewItem(
            question: "Q",
            answer: "A",
            subject: "数学", // maps to .math
            difficulty: "中等", // maps to .medium
            tags: ["t1","t2"],
            notes: nil
        )
        let item = try await service.getReviewItem(id: id)
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.subject, .math)
        XCTAssertEqual(item?.difficulty, .medium)
        XCTAssertEqual(item?.tags, ["t1","t2"])
    }

    func testUpdateItem_andDelete() async throws {
        let id = try await service.createReviewItem(
            question: "Q2",
            answer: "A2",
            subject: "其他",
            difficulty: "困难",
            tags: [],
            notes: nil
        )

        try await service.updateReviewItem(id: id, updates: .init(question: "Q2*", answer: nil, subject: "物理", difficulty: nil, tags: ["k"], notes: "n"))
        let afterUpdate = try await service.getReviewItem(id: id)
        XCTAssertEqual(afterUpdate?.question, "Q2*")
        XCTAssertEqual(afterUpdate?.subject, .physics)
        XCTAssertEqual(afterUpdate?.tags, ["k"])
        XCTAssertEqual(afterUpdate?.notes, "n")

        try await service.deleteReviewItem(id: id)
        let afterDelete = try await service.getReviewItem(id: id)
        XCTAssertNil(afterDelete)
    }

    func testRecordReviewResult_increasesHistory_andSchedulesNext() async throws {
        let id = try await service.createReviewItem(
            question: "Q3",
            answer: "A3",
            subject: "英语",
            difficulty: "简单",
            tags: [],
            notes: nil
        )

        try await service.recordReviewResult(id: id, wasSuccessful: true)
        let item = try await service.getReviewItem(id: id)
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.reviewHistory.count, 1)
        XCTAssertNotNil(item?.nextReviewDate)
    }

    func testQueries_andStatistics() async throws {
        // create 3 items with different difficulty and subject
        _ = try await service.createReviewItem(question: "m1", answer: "a", subject: "数学", difficulty: "简单", tags: [], notes: nil)
        _ = try await service.createReviewItem(question: "p1", answer: "a", subject: "物理", difficulty: "中等", tags: [], notes: nil)
        _ = try await service.createReviewItem(question: "e1", answer: "a", subject: "英语", difficulty: "困难", tags: [], notes: nil)

        let all = try await service.getAllItems()
        XCTAssertEqual(all.count, 3)

        let search = try await service.searchReviewItems(query: "m1", limit: 5)
        XCTAssertEqual(search.count, 1)

        let maths = try await service.getItemsByCriteria(.init(subject: .math))
        XCTAssertEqual(maths.count, 1)

        let stats = try await service.getStatistics()
        XCTAssertEqual(stats.total, 3)
        XCTAssertEqual(stats.difficultyBreakdown.easy, 1)
        XCTAssertEqual(stats.difficultyBreakdown.medium, 1)
        XCTAssertEqual(stats.difficultyBreakdown.hard, 1)
        XCTAssertEqual(stats.proficiencyBreakdown.notProficient, 3)
        XCTAssertEqual(stats.proficiencyBreakdown.learning + stats.proficiencyBreakdown.proficient, 0)
        XCTAssertGreaterThanOrEqual(stats.averageDifficulty, 1.0)
        XCTAssertLessThanOrEqual(stats.averageDifficulty, 3.0)
        XCTAssertEqual(stats.proficiencyRate, 0)
    }
}
