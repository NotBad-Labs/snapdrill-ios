//
//  InMemoryReviewItemRepositoryTests.swift
//  NotBadTests
//
//  Created by Copilot on 9/22/25.
//

import XCTest
@testable import NotBad

final class InMemoryReviewItemRepositoryTests: XCTestCase {
    var repository: InMemoryReviewItemRepository!

    override func setUp() async throws {
        try await super.setUp()
        repository = InMemoryReviewItemRepository()
    }

    override func tearDown() async throws {
        #if DEBUG
        await repository.clear()
        #endif
        repository = nil
        try await super.tearDown()
    }

    // MARK: - CRUD
    func testSaveAndFindById() async throws {
        var item = try ReviewItem(
            question: "Q1",
            answer: "A1",
            subject: .math,
            difficulty: .medium,
            tags: ["tag1"],
            notes: "n"
        )
        // mutate to ensure updatedAt changes are handled well
        try item.updateAnswer("A1'")

        let id = try await repository.save(item)
        let fetched = try await repository.findById(id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, id)
        XCTAssertEqual(fetched?.answer, "A1'")
    }

    func testUpdateExistingItem() async throws {
        let id = try await repository.save(
            try ReviewItem(
                question: "Q2",
                answer: "A2",
                subject: .english,
                difficulty: .easy,
                tags: ["x"],
                notes: nil
            )
        )

        let updates = ReviewItemUpdates(
            question: "Q2+'",
            answer: "A2+'",
            subject: ReviewItem.Subject.physics.rawValue,
            difficulty: ReviewItem.Difficulty.hard.rawValue,
            tags: ["x","y"],
            notes: "note"
        )

        let updated = try await repository.update(id, with: updates)
        XCTAssertEqual(updated.question, "Q2+'")
        XCTAssertEqual(updated.answer, "A2+'")
        XCTAssertEqual(updated.subject, .physics)
        XCTAssertEqual(updated.difficulty, .hard)
    XCTAssertEqual(updated.tags, Set(["x","y"]))
        XCTAssertEqual(updated.notes, "note")
    }

    func testDeleteExistingAndNonExisting() async throws {
        let id = try await repository.save(
            try ReviewItem(
                question: "Q3",
                answer: "A3",
                subject: .other,
                difficulty: .medium
            )
        )

        // delete existing
        try await repository.delete(id)
        let existsAfter = try await repository.exists(id)
        XCTAssertFalse(existsAfter)
        let byIdNil = try await repository.findById(id)
        XCTAssertNil(byIdNil)

        // delete non-existing should throw
            await XCTAssertThrowsErrorAsync(try await repository.delete(id)) { error in
                guard let repoError = error as? RepositoryError, case .itemNotFound = repoError else {
                    return XCTFail("Expected itemNotFound error")
                }
            }
    }

    // MARK: - Query & Search
    func testFindByCriteria_andSearch() async throws {
        // create 3 items
        let id1 = try await repository.save(
            try ReviewItem(
                question: "Matrix determinant",
                answer: "|A|",
                subject: .math,
                difficulty: .hard,
                tags: ["linear","algebra"],
                notes: "线性代数"
            )
        )
        _ = id1
        let _ = try await repository.save(
            try ReviewItem(
                question: "Newton law",
                answer: "F=ma",
                subject: .physics,
                difficulty: .easy,
                tags: ["mechanics"],
                notes: nil
            )
        )
        let _ = try await repository.save(
            try ReviewItem(
                question: "English word list",
                answer: "apple, banana",
                subject: .english,
                difficulty: .medium,
                tags: ["vocabulary"],
                notes: "daily"
            )
        )

        // by subject
        let mathOnly = try await repository.findBy(ReviewItemQueryCriteria(subject: .math))
        XCTAssertEqual(mathOnly.count, 1)
        XCTAssertEqual(mathOnly.first?.subject, .math)

        // by difficulty
        let easies = try await repository.findBy(ReviewItemQueryCriteria(difficulty: .easy))
        XCTAssertEqual(easies.count, 1)
        XCTAssertEqual(easies.first?.difficulty, .easy)

        // by tags subset
        let hasLinear = try await repository.findBy(ReviewItemQueryCriteria(tags: ["linear"]))
        XCTAssertEqual(hasLinear.count, 1)
        XCTAssertTrue(hasLinear.first?.tags.contains("linear") == true)

        // by searchText (search across question/answer/notes)
        let searchCn = try await repository.search(query: "线性", limit: 10)
        XCTAssertEqual(searchCn.count, 1)
        let searchAns = try await repository.search(query: "F=ma", limit: 10)
        XCTAssertEqual(searchAns.count, 1)
        let searchWord = try await repository.search(query: "word", limit: 10)
        XCTAssertEqual(searchWord.count, 1)

    // limit works (use a query likely to match all)
    let limited = try await repository.search(query: "a", limit: 2)
    XCTAssertEqual(limited.count, 2)
    }

    func testSearch_noHits_returnsEmpty() async throws {
        // Arrange: seed a few items
        _ = try await repository.save(
            try ReviewItem(
                question: "Integrals",
                answer: "∫",
                subject: .math,
                difficulty: .medium,
                tags: ["calculus"],
                notes: nil
            )
        )
        _ = try await repository.save(
            try ReviewItem(
                question: "Momentum",
                answer: "p=mv",
                subject: .physics,
                difficulty: .easy,
                tags: ["mechanics"],
                notes: nil
            )
        )

        // Act: search with a query that shouldn't match anything
        let result = try await repository.search(query: "this_phrase_should_not_exist", limit: 10)

        // Assert
        XCTAssertEqual(result.count, 0)
    }

    func testFindBy_emptyTagsCriteria_returnsAll() async throws {
        // Arrange
        _ = try await repository.save(
            try ReviewItem(
                question: "Chem basics",
                answer: "H2O",
                subject: .chemistry,
                difficulty: .easy,
                tags: ["molecule"],
                notes: nil
            )
        )
        _ = try await repository.save(
            try ReviewItem(
                question: "Word set",
                answer: "alpha beta",
                subject: .english,
                difficulty: .medium,
                tags: ["vocabulary"],
                notes: nil
            )
        )

        // Note: 当前实现中，空集合是所有集合的子集 => 等价于不加该条件
        let items = try await repository.findBy(ReviewItemQueryCriteria(tags: []))
        let all = try await repository.findAll()

        XCTAssertEqual(items.count, all.count)
    }

    func testFindBy_conflictingCriteria_returnsEmpty() async throws {
        // Arrange
        _ = try await repository.save(
            try ReviewItem(
                question: "Hooke law",
                answer: "F=kx",
                subject: .physics,
                difficulty: .easy,
                tags: ["mechanics"],
                notes: nil
            )
        )

        // Act: 设置相互矛盾的过滤条件（学科为 math，但搜索文本命中物理题）
        let items = try await repository.findBy(ReviewItemQueryCriteria(subject: .math, searchText: "F=kx"))

        // Assert
        XCTAssertEqual(items.count, 0)
    }

    func testFindItemsForReview_sortedByProficiencyAndCreatedAt() async throws {
        // not reviewed -> notProficient (qualifies)
            let itemA = try ReviewItem(
            question: "A",
            answer: "a",
            subject: .other,
            difficulty: .medium
        )

        // one success -> learning
        var itemB = try ReviewItem(
            question: "B",
            answer: "b",
            subject: .other,
            difficulty: .medium
        )
        itemB.recordReviewResult(wasSuccessful: true)

        // two success -> proficient
        var itemC = try ReviewItem(
            question: "C",
            answer: "c",
            subject: .other,
            difficulty: .medium
        )
        itemC.recordReviewResult(wasSuccessful: true)
        itemC.recordReviewResult(wasSuccessful: true)

        let idA = try await repository.save(itemA)
        let idB = try await repository.save(itemB)
        let idC = try await repository.save(itemC)
        _ = (idA, idB, idC)

        // future date so all items with nextReviewDate (or nil) are included
        let future = Date().addingTimeInterval(14 * 24 * 60 * 60)
        let itemsForReview = try await repository.findItemsForReview(on: future, limit: 10)
        XCTAssertEqual(itemsForReview.count, 3)

        // expected order: notProficient (A), learning (B), proficient (C)
        XCTAssertEqual(itemsForReview[0].question, "A")
        XCTAssertEqual(itemsForReview[1].question, "B")
        XCTAssertEqual(itemsForReview[2].question, "C")
    }

    // MARK: - Statistics
    func testCountAndExists() async throws {
        let c0 = try await repository.count()
        XCTAssertEqual(c0, 0)
        let id = try await repository.save(
            try ReviewItem(
                question: "S",
                answer: "s",
                subject: .chemistry,
                difficulty: .easy
            )
        )
        let c1 = try await repository.count()
        XCTAssertEqual(c1, 1)
        let exists = try await repository.exists(id)
        XCTAssertTrue(exists)

        let easyCount = try await repository.count(by: ReviewItemQueryCriteria(difficulty: .easy))
        XCTAssertEqual(easyCount, 1)
    }
}

// MARK: - Async Throws Helper
private func XCTAssertThrowsErrorAsync<T>(_ expression: @autoclosure () async throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line, _ errorHandler: (Error) -> Void) async {
    do {
        _ = try await expression()
        XCTFail("Expected error to be thrown. " + message(), file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
