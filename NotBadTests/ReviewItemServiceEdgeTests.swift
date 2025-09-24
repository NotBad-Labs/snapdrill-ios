//
//  ReviewItemServiceEdgeTests.swift
//  NotBadTests
//
//  Created by GitHub Copilot on 9/23/25.
//

import XCTest
@testable import NotBad

final class ReviewItemServiceEdgeTests: XCTestCase {
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

    func testDeleteNonExistentItem_throwsItemNotFound() async throws {
        let nonExistent = ReviewItemID()
        do {
            try await service.deleteReviewItem(id: nonExistent)
            return XCTFail("Expected itemNotFound to be thrown")
        } catch let error as RepositoryError {
            switch error {
            case .itemNotFound(let id):
                XCTAssertEqual(id, nonExistent)
            default:
                return XCTFail("Expected .itemNotFound, got: \(error)")
            }
        } catch {
            return XCTFail("Unexpected error: \(error)")
        }
    }

    func testSearch_mixedCase_andEmptyQuery() async throws {
        // Seed items with different cases and notes
        _ = try await service.createReviewItem(
            question: "Linear Algebra",
            answer: "Matrix",
            subject: ReviewItem.Subject.math.rawValue,
            difficulty: ReviewItem.Difficulty.easy.rawValue,
            tags: ["algebra"],
            notes: "eigenvalues"
        )
        _ = try await service.createReviewItem(
            question: "physics: Optics",
            answer: "Lens",
            subject: ReviewItem.Subject.physics.rawValue,
            difficulty: ReviewItem.Difficulty.medium.rawValue,
            tags: ["PHYS"],
            notes: nil
        )

    // Mixed case query should match case-insensitively (at least one)
    let results1 = try await service.searchReviewItems(query: "optICS", limit: 10)
    XCTAssertGreaterThanOrEqual(results1.count, 1)
    XCTAssertTrue(results1.contains { $0.question.lowercased().contains("optics") || $0.answer.lowercased().contains("optics") || ($0.notes?.lowercased().contains("optics") ?? false) })

        // Query by notes content
    let results2 = try await service.searchReviewItems(query: "EIGENVALUES", limit: 10)
    XCTAssertGreaterThanOrEqual(results2.count, 1)
    XCTAssertTrue(results2.contains { $0.notes?.lowercased().contains("eigenvalues") ?? false })

        // Empty query should return first N (through criteria with nil search when empty in VM, but service.search itself treats empty as a query)
        // Here we assert that an empty query returns items up to limit without crashing (repository uses filtering that will treat empty string as contained by all strings)
        let results3 = try await service.searchReviewItems(query: "", limit: 1)
        // Empty query behavior can vary by repository implementation; ensure it doesn't crash
        // and returns at most the requested limit.
        XCTAssertGreaterThanOrEqual(results3.count, 0)
        XCTAssertLessThanOrEqual(results3.count, 1)
    }
}
