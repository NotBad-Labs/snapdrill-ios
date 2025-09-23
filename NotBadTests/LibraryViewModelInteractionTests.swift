//
//  LibraryViewModelInteractionTests.swift
//  NotBadTests
//
//  Created by GitHub Copilot on 9/23/25.
//

import XCTest
import Combine
@testable import NotBad

@MainActor
final class LibraryViewModelInteractionTests: XCTestCase {
    var repository: InMemoryReviewItemRepository!
    var service: ReviewItemService!
    var coordinator: LibraryCoordinator!
    var errorHandler: AppErrorHandler!
    var cancellables: Set<AnyCancellable> = []

    override func setUp() async throws {
        repository = InMemoryReviewItemRepository()
        service = ReviewItemService(repository: repository)
        coordinator = LibraryCoordinator()
        errorHandler = AppErrorHandler()
    }

    override func tearDown() async throws {
        cancellables.removeAll()
        repository = nil
        service = nil
        coordinator = nil
        errorHandler = nil
    }

    func testToggleSearchBar_andFilters() async throws {
        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)
        vm.configure(errorHandler: errorHandler)

        XCTAssertFalse(vm.showSearchBar)
        vm.toggleSearchBar()
        XCTAssertTrue(vm.showSearchBar)

        vm.searchText = "abc"
        vm.toggleSearchBar() // hides and clears
        XCTAssertFalse(vm.showSearchBar)
        XCTAssertEqual(vm.searchText, "")

        XCTAssertFalse(vm.showFilters)
        vm.toggleFilters()
        XCTAssertTrue(vm.showFilters)
    }

    func testApplyAndClearFilters_triggerReloads() async throws {
        // Seed some data
        _ = try await service.createReviewItem(question: "Q1", answer: "A1", subject: ReviewItem.Subject.math.rawValue, difficulty: ReviewItem.Difficulty.easy.rawValue, tags: [], notes: nil)
        _ = try await service.createReviewItem(question: "Q2", answer: "A2", subject: ReviewItem.Subject.physics.rawValue, difficulty: ReviewItem.Difficulty.hard.rawValue, tags: [], notes: nil)

        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)
        vm.configure(errorHandler: errorHandler)

        await vm.loadReviewItems()
        let initialCount = vm.reviewItems.count
        XCTAssertEqual(initialCount, 2)

        vm.selectedSubject = .physics
        vm.applyFilters()
        // allow async load
        try await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertEqual(vm.reviewItems.count, 1)

        vm.clearFilters()
        // allow async load
        try await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertEqual(vm.reviewItems.count, 2)
    }

    func testNavigateToDetail_andAdd() async throws {
        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)
        let id = try await service.createReviewItem(question: "Q", answer: "A", subject: ReviewItem.Subject.other.rawValue, difficulty: ReviewItem.Difficulty.medium.rawValue, tags: [], notes: nil)
        if let item = try await service.getReviewItem(id: id) {
            vm.navigateToDetail(item)
            XCTAssertEqual(coordinator.navigationPath.count, 1)
        } else {
            XCTFail("Expected item to exist")
        }

        vm.navigateToAddItem()
        // navigateToAddItem delegates to .saveReviewItem, which LibraryCoordinator does not push, so no path change expected
        XCTAssertEqual(coordinator.navigationPath.count, 1)
    }

    func testDeleteItem_handlesErrorGracefully() async throws {
        // Given: create one item then simulate deleting non-existing
        let id = try await service.createReviewItem(question: "Q", answer: "A", subject: ReviewItem.Subject.other.rawValue, difficulty: ReviewItem.Difficulty.medium.rawValue, tags: [], notes: nil)
        guard let item = try await service.getReviewItem(id: id) else { return XCTFail("seed failed") }

        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)
        vm.configure(errorHandler: errorHandler)

        // actually delete directly to force next deletion to fail
        try await service.deleteReviewItem(id: id)

        await vm.deleteItem(item) // should trigger handler but not crash
        XCTAssertNotNil(errorHandler.currentError)
    }

    func testDeleteItem_success_updatesItemsAndStatistics() async throws {
        // Seed two items
        let id1 = try await service.createReviewItem(question: "Q1", answer: "A1", subject: ReviewItem.Subject.other.rawValue, difficulty: ReviewItem.Difficulty.easy.rawValue, tags: [], notes: nil)
        _ = try await service.createReviewItem(question: "Q2", answer: "A2", subject: ReviewItem.Subject.other.rawValue, difficulty: ReviewItem.Difficulty.medium.rawValue, tags: [], notes: nil)

        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)
        vm.configure(errorHandler: errorHandler)

        await vm.loadReviewItems()
        await vm.loadStatistics()
        XCTAssertEqual(vm.reviewItems.count, 2)
        XCTAssertEqual(vm.totalItems, 2)

        guard let item1 = try await service.getReviewItem(id: id1) else { return XCTFail("seed failed") }
        await vm.deleteItem(item1)

        // After successful delete, LibraryViewModel should reload items and stats
        XCTAssertEqual(vm.reviewItems.count, 1)
        XCTAssertEqual(vm.totalItems, 1)
    }

    func testSearchDebounce_triggersReload() async throws {
        // Seed data
        _ = try await service.createReviewItem(question: "Apple pie", answer: "Delicious", subject: ReviewItem.Subject.other.rawValue, difficulty: ReviewItem.Difficulty.easy.rawValue, tags: [], notes: nil)
        _ = try await service.createReviewItem(question: "Banana", answer: "Yellow", subject: ReviewItem.Subject.other.rawValue, difficulty: ReviewItem.Difficulty.easy.rawValue, tags: [], notes: nil)

        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)
        vm.configure(errorHandler: errorHandler)

        await vm.loadReviewItems()
        XCTAssertEqual(vm.reviewItems.count, 2)

        vm.searchText = "apple"
        // Wait longer than debounce window (500ms)
        try await Task.sleep(nanoseconds: 700_000_000)
        XCTAssertEqual(vm.reviewItems.count, 1)
        XCTAssertTrue(vm.reviewItems[0].question.lowercased().contains("apple"))
    }

    func testClearSearchText_triggersReload() async throws {
        // Seed data
        _ = try await service.createReviewItem(question: "Cat", answer: "Meow", subject: ReviewItem.Subject.other.rawValue, difficulty: ReviewItem.Difficulty.easy.rawValue, tags: [], notes: nil)
        _ = try await service.createReviewItem(question: "Dog", answer: "Woof", subject: ReviewItem.Subject.other.rawValue, difficulty: ReviewItem.Difficulty.easy.rawValue, tags: [], notes: nil)

        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)
        vm.configure(errorHandler: errorHandler)

        await vm.loadReviewItems()
        XCTAssertEqual(vm.reviewItems.count, 2)

        vm.searchText = "cat"
        try await Task.sleep(nanoseconds: 700_000_000)
        XCTAssertEqual(vm.reviewItems.count, 1)

        // Clearing searchText via toggleSearchBar hides bar and resets text => triggers reload
        vm.toggleSearchBar()
        XCTAssertTrue(vm.showSearchBar)
        vm.toggleSearchBar() // hide and clear
        XCTAssertEqual(vm.searchText, "")
        // wait for debounce load
        try await Task.sleep(nanoseconds: 700_000_000)
        XCTAssertEqual(vm.reviewItems.count, 2)
    }
}
