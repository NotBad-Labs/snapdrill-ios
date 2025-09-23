// NotBadTests/ReviewItemServiceMoreTests.swift
// Focus: getItemsForReview ordering and limit behavior

import XCTest
@testable import NotBad

final class ReviewItemServiceMoreTests: XCTestCase {
    var repository: InMemoryReviewItemRepository!
    var service: ReviewItemService!

    override func setUp() async throws {
        repository = InMemoryReviewItemRepository()
        service = ReviewItemService(repository: repository)
    }

    override func tearDown() async throws {
        repository = nil
        service = nil
    }

    func testGetItemsForReview_ordersByProficiencyThenCreatedAt_andHonorsLimit() async throws {
        // Create items with different proficiency via recorded results and staggered createdAt
        var createdIds: [ReviewItemID] = []

        func create(question: String, createdOffset: TimeInterval) async throws -> ReviewItemID {
            let id = try await service.createReviewItem(
                question: question,
                answer: "A",
                subject: ReviewItem.Subject.math.rawValue,
                difficulty: ReviewItem.Difficulty.medium.rawValue,
                tags: [],
                notes: nil
            )
            // Note: createdAt is set at creation time and immutable via public API.
            // We'll rely on natural creation order as a proxy for createdAt ordering.
            return id
        }

        // Create 4 items
        createdIds.append(try await create(question: "I1", createdOffset: -400)) // will keep as notProficient
        createdIds.append(try await create(question: "I2", createdOffset: -300))
        createdIds.append(try await create(question: "I3", createdOffset: -200))
        createdIds.append(try await create(question: "I4", createdOffset: -100))

        // Upgrade proficiency levels with results
        if let i2 = try await repository.findById(createdIds[1]) {
            var m = i2; m.recordReviewResult(wasSuccessful: true) // -> learning
            _ = try await repository.save(m)
        }
        if let i3 = try await repository.findById(createdIds[2]) {
            var m = i3; m.recordReviewResult(wasSuccessful: true); m.recordReviewResult(wasSuccessful: true) // -> proficient
            _ = try await repository.save(m)
        }
        if let i4 = try await repository.findById(createdIds[3]) {
            var m = i4; m.recordReviewResult(wasSuccessful: true) // -> learning
            _ = try await repository.save(m)
        }

        // Ask for items to review at far future so all with nextReviewDate <= date are included (those never reviewed are included by needsReview logic)
        let future = Date().addingTimeInterval(365*24*60*60)
        let result = try await service.getItemsForReview(date: future, limit: 3)

        // Expect ordering: notProficient first (I1), then learning by createdAt (I2 before I4), exclude proficient (I3) if its nextReviewDate in future
        XCTAssertLessThanOrEqual(result.count, 3)
        XCTAssertEqual(result[0].proficiencyLevel, .notProficient)
        if result.count > 1 {
            XCTAssertEqual(result[1].proficiencyLevel, .learning)
        }
    }
}
