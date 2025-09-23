// NotBadTests/LibraryViewModelNavigationTests.swift
// Focus: LibraryViewModel.startPracticeMode triggers coordinator navigation

import XCTest
@testable import NotBad

@MainActor
final class LibraryViewModelNavigationTests: XCTestCase {
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

    func testStartPracticeMode_coordinates() async throws {
        let coordinator = LibraryCoordinator()
        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)

        vm.startPracticeMode()

        XCTAssertEqual(coordinator.navigationPath.count, 1)
    }
}
