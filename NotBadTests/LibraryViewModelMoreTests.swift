//
//  LibraryViewModelMoreTests.swift
//  NotBadTests
//
//  Created by GitHub Copilot on 9/22/25.
//

import XCTest
@testable import NotBad

@MainActor
final class LibraryViewModelMoreTests: XCTestCase {
    var repository: InMemoryReviewItemRepository!
    var service: ReviewItemService!
    var coordinator: LibraryCoordinator!

    override func setUp() async throws {
        repository = InMemoryReviewItemRepository()
        service = ReviewItemService(repository: repository)
        coordinator = LibraryCoordinator()
    }

    override func tearDown() async throws {
        repository = nil
        service = nil
        coordinator = nil
    }

    func testCompletionPercentage_ComputedCorrectly() async throws {
        // Given
        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)
        vm.totalItems = 10
        vm.reviewedItems = 4

        // When
        let pct = vm.completionPercentage

        // Then
        XCTAssertEqual(pct, 40.0, accuracy: 0.0001)
    }

    func testHasActiveFilters_ReflectsState() async throws {
        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)
        XCTAssertFalse(vm.hasActiveFilters)
        vm.selectedSubject = .math
        XCTAssertTrue(vm.hasActiveFilters)
        vm.selectedSubject = nil
        vm.searchText = "hello"
        XCTAssertTrue(vm.hasActiveFilters)
    }

    func testClearFilters_ResetsFilters() async throws {
        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)
        vm.selectedSubject = .physics
        vm.selectedDifficulty = .hard
        vm.searchText = "abc"

        vm.clearFilters()

        XCTAssertNil(vm.selectedSubject)
        XCTAssertNil(vm.selectedDifficulty)
        XCTAssertEqual(vm.searchText, "")
    }

    func testClearingSearchText_triggersReloadViaDebounce() async throws {
        // Seed some items
        _ = try await service.createReviewItem(question: "A apple", answer: "a", subject: ReviewItem.Subject.other.rawValue, difficulty: ReviewItem.Difficulty.easy.rawValue, tags: [], notes: nil)
        _ = try await service.createReviewItem(question: "B banana", answer: "b", subject: ReviewItem.Subject.other.rawValue, difficulty: ReviewItem.Difficulty.easy.rawValue, tags: [], notes: nil)

        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)
        await vm.loadReviewItems()
        let baseline = vm.reviewItems.count
        XCTAssertEqual(baseline, 2)

        // Apply a search to reduce results
        vm.searchText = "apple"
        try await Task.sleep(nanoseconds: 600_000_000) // wait > debounce
        XCTAssertEqual(vm.reviewItems.count, 1)

        // Clear search should trigger reload back to all
        vm.searchText = ""
        try await Task.sleep(nanoseconds: 600_000_000) // wait > debounce
        XCTAssertEqual(vm.reviewItems.count, 2)
    }

    func testRefresh_updatesItemsAndStatistics() async throws {
        // Seed initial data
        _ = try await service.createReviewItem(
            question: "Q1",
            answer: "A1",
            subject: ReviewItem.Subject.other.rawValue,
            difficulty: ReviewItem.Difficulty.easy.rawValue,
            tags: [],
            notes: nil
        )

        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)

        // When
        await vm.refresh()

        // Then
        XCTAssertEqual(vm.reviewItems.count, 1)
        XCTAssertEqual(vm.totalItems, 1)

        // And: After adding another item, refresh updates both lists and stats
        _ = try await service.createReviewItem(
            question: "Q2",
            answer: "A2",
            subject: ReviewItem.Subject.other.rawValue,
            difficulty: ReviewItem.Difficulty.medium.rawValue,
            tags: [],
            notes: nil
        )

        await vm.refresh()
        XCTAssertEqual(vm.reviewItems.count, 2)
        XCTAssertEqual(vm.totalItems, 2)
    }

    func testOnAppear_loadsItemsAndStatistics() async throws {
        // Seed data
        _ = try await service.createReviewItem(
            question: "Hello",
            answer: "World",
            subject: ReviewItem.Subject.math.rawValue,
            difficulty: ReviewItem.Difficulty.hard.rawValue,
            tags: [],
            notes: nil
        )
        _ = try await service.createReviewItem(
            question: "Foo",
            answer: "Bar",
            subject: ReviewItem.Subject.physics.rawValue,
            difficulty: ReviewItem.Difficulty.easy.rawValue,
            tags: [],
            notes: nil
        )

        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)

        // When: onAppear schedules async loads for items and statistics
        vm.onAppear()
        // allow tasks to complete
        try await Task.sleep(nanoseconds: 250_000_000)

        // Then
        XCTAssertEqual(vm.reviewItems.count, 2)
        XCTAssertEqual(vm.totalItems, 2)
        XCTAssertEqual(vm.pendingItems, 2)
    }

    func testFilteredItemsCount_reflectsCurrentItems() async throws {
        // Seed 3 items: 2 easy, 1 hard
        _ = try await service.createReviewItem(
            question: "E1",
            answer: "A",
            subject: ReviewItem.Subject.other.rawValue,
            difficulty: ReviewItem.Difficulty.easy.rawValue,
            tags: [],
            notes: nil
        )
        _ = try await service.createReviewItem(
            question: "E2",
            answer: "A",
            subject: ReviewItem.Subject.other.rawValue,
            difficulty: ReviewItem.Difficulty.easy.rawValue,
            tags: [],
            notes: nil
        )
        _ = try await service.createReviewItem(
            question: "H1",
            answer: "A",
            subject: ReviewItem.Subject.other.rawValue,
            difficulty: ReviewItem.Difficulty.hard.rawValue,
            tags: [],
            notes: nil
        )

        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)
        await vm.loadReviewItems()
        XCTAssertEqual(vm.filteredItemsCount, 3)

        vm.selectedDifficulty = .hard
        await vm.loadReviewItems()
        XCTAssertEqual(vm.filteredItemsCount, 1)
    }
}
