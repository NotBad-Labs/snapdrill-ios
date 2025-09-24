//
//  LibraryViewModelTests.swift
//  NotBadTests
//
//  Created by Yiming Liao on 9/21/25.
//

import XCTest
@testable import NotBad

final class LibraryViewModelTests: XCTestCase {
    var repository: ReviewItemRepository!
    var service: ReviewItemService!
    
    override func setUp() {
        super.setUp()
        repository = InMemoryReviewItemRepository()
        service = ReviewItemService(repository: repository)
    }
    
    override func tearDown() {
        repository = nil
        service = nil
        super.tearDown()
    }
    
    @MainActor
    func testLoadItemsAndStatistics() async throws {
        // Given: Seed two items
        _ = try await service.createReviewItem(
            question: "Q1",
            answer: "A1",
            subject: ReviewItem.Subject.math.rawValue,
            difficulty: ReviewItem.Difficulty.easy.rawValue,
            tags: ["t1"],
            notes: nil
        )
        _ = try await service.createReviewItem(
            question: "Q2",
            answer: "A2",
            subject: ReviewItem.Subject.physics.rawValue,
            difficulty: ReviewItem.Difficulty.hard.rawValue,
            tags: ["t2"],
            notes: nil
        )
        
        let coordinator = LibraryCoordinator()
        let viewModel = LibraryViewModel(reviewItemService: service, coordinator: coordinator)
        
        // When
        await viewModel.loadReviewItems()
        await viewModel.loadStatistics()
        
        // Then
        XCTAssertEqual(viewModel.reviewItems.count, 2)
        XCTAssertEqual(viewModel.totalItems, 2)
        // 新创建的题目默认不熟练
        XCTAssertEqual(viewModel.reviewedItems, 0)
        XCTAssertEqual(viewModel.pendingItems, 2)
        
        // And: Filtering by difficulty reduces the list
        viewModel.selectedDifficulty = .hard
        await viewModel.loadReviewItems()
        XCTAssertEqual(viewModel.reviewItems.count, 1)
    }
}
