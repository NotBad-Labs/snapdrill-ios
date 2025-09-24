//
//  ReviewItemRepositoryMoreTests.swift
//  NotBadTests
//
//  Created by GitHub Copilot on 9/23/25.
//

import XCTest
@testable import NotBad

final class ReviewItemRepositoryMoreTests: XCTestCase {
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

    // MARK: - Error paths & values
    func testUpdateNonExistingItem_throwsItemNotFound() async {
        let randomId = ReviewItemID()
        let updates = ReviewItemUpdates(question: "Q*")
        await XCTAssertThrowsErrorAsync(try await repository.update(randomId, with: updates)) { error in
            guard let repoError = error as? RepositoryError, case .itemNotFound(let id) = repoError else {
                return XCTFail("Expected RepositoryError.itemNotFound")
            }
            XCTAssertEqual(id, randomId)
        }
    }

    func testRepositoryErrorDescriptions_coverAllCases() {
        let id = ReviewItemID()
        let e1: RepositoryError = .itemNotFound(id)
        let e2: RepositoryError = .duplicateItem(id)
        let e3: RepositoryError = .persistenceFailure(NSError(domain: "x", code: 1))
        let e4: RepositoryError = .queryError("bad criteria")
        let e5: RepositoryError = .connectionFailure

        XCTAssertTrue(e1.localizedDescription.contains(id.value.uuidString))
        XCTAssertTrue(e2.localizedDescription.contains(id.value.uuidString))
        XCTAssertTrue(e3.localizedDescription.contains("持久化失败"))
        XCTAssertTrue(e4.localizedDescription.contains("查询错误"))
        XCTAssertTrue(e5.localizedDescription.contains("数据库连接失败"))
    }

    func testDateRange_invalidRange_throws_andContainsChecks() async throws {
        let now = Date()
        let earlier = now.addingTimeInterval(-3600)
        // invalid: start > end
        XCTAssertThrowsError(try DateRange(start: now, end: earlier))

        // valid: window includes now
        let rng = try DateRange(start: earlier, end: now)
        XCTAssertTrue(rng.contains(now))
        XCTAssertTrue(rng.contains(earlier))
        XCTAssertFalse(rng.contains(now.addingTimeInterval(10)))
    }

    // MARK: - Query filters
    func testFindBy_proficiencyLevel_filtersCorrectly() async throws {
        // Given: one default (notProficient), one upgraded to learning
        let id1 = try await service.createReviewItem(question: "Q1", answer: "A1", subject: ReviewItem.Subject.math.rawValue, difficulty: ReviewItem.Difficulty.medium.rawValue, tags: [], notes: nil)
        _ = id1
        let id2 = try await service.createReviewItem(question: "Q2", answer: "A2", subject: ReviewItem.Subject.math.rawValue, difficulty: ReviewItem.Difficulty.medium.rawValue, tags: [], notes: nil)
        try await service.recordReviewResult(id: id2, wasSuccessful: true)

        let notProficient = try await repository.findBy(.init(proficiencyLevel: .notProficient))
        let learning = try await repository.findBy(.init(proficiencyLevel: .learning))

        XCTAssertEqual(notProficient.count, 1)
        XCTAssertEqual(learning.count, 1)
    }

    func testFindBy_dateRange_filtersByCreatedAt() async throws {
        // seed one item created ~now
        _ = try await service.createReviewItem(question: "nowQ", answer: "nowA", subject: ReviewItem.Subject.other.rawValue, difficulty: ReviewItem.Difficulty.easy.rawValue, tags: [], notes: nil)
        let now = Date()
        let past = now.addingTimeInterval(-24*60*60)
        let future = now.addingTimeInterval(24*60*60)

        // Range that excludes now (end before now)
        let excludeNow = try DateRange(start: past.addingTimeInterval(-10), end: past)
        let none = try await repository.findBy(.init(dateRange: excludeNow))
        XCTAssertEqual(none.count, 0)

        // Range that includes now
        let includeNow = try DateRange(start: past, end: future)
        let some = try await repository.findBy(.init(dateRange: includeNow))
        XCTAssertGreaterThanOrEqual(some.count, 1)
    }

    func testFindItemsForReview_honorsLimit() async throws {
        // Create multiple items (all qualify with future cutoff)
        for i in 0..<5 {
            _ = try await service.createReviewItem(question: "Q\\(i)", answer: "A", subject: ReviewItem.Subject.other.rawValue, difficulty: ReviewItem.Difficulty.medium.rawValue, tags: [], notes: nil)
        }
        let future = Date().addingTimeInterval(30 * 24 * 60 * 60)
        let list = try await repository.findItemsForReview(on: future, limit: 3)
        XCTAssertEqual(list.count, 3)
    }

    func testReviewItemQueryCriteria_initializer_assignsFields() {
        let crit = ReviewItemQueryCriteria(
            subject: .physics,
            difficulty: .hard,
            proficiencyLevel: .learning,
            tags: ["t1","t2"],
            dateRange: try? DateRange(start: Date(), end: Date()),
            searchText: "abc"
        )
        XCTAssertEqual(crit.subject, .physics)
        XCTAssertEqual(crit.difficulty, .hard)
        XCTAssertEqual(crit.proficiencyLevel, .learning)
        XCTAssertEqual(crit.tags, ["t1","t2"])
        XCTAssertEqual(crit.searchText, "abc")
    }
}

// MARK: - Async Throws Helper (local copy)
private func XCTAssertThrowsErrorAsync<T>(_ expression: @autoclosure () async throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line, _ errorHandler: (Error) -> Void) async {
    do {
        _ = try await expression()
        XCTFail("Expected error to be thrown. " + message(), file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
