//
//  LibraryDetailViewModelTests.swift
//  NotBadTests
//
//  Created by GitHub Copilot on 9/22/25.
//

import XCTest
@testable import NotBad

@MainActor
final class LibraryDetailViewModelTests: XCTestCase {
    var repository: InMemoryReviewItemRepository!
    var service: ReviewItemService!
    var coordinator: LibraryCoordinator!
    var errorHandler: AppErrorHandler!

    override func setUp() async throws {
        repository = InMemoryReviewItemRepository()
        service = ReviewItemService(repository: repository)
        coordinator = LibraryCoordinator()
        errorHandler = AppErrorHandler()
    }

    override func tearDown() async throws {
        repository = nil
        service = nil
        coordinator = nil
        errorHandler = nil
    }

    func testLoad_validId_loadsItem() async throws {
        // Arrange: create one item and persist
        let id = try await service.createReviewItem(
            question: "Q1",
            answer: "A1",
            subject: "math",
            difficulty: "easy",
            tags: ["tag1"],
            notes: "note"
        )

        let vm = LibraryDetailViewModel(
            reviewItemService: service,
            itemId: id.value.uuidString,
            coordinator: coordinator,
            errorHandler: errorHandler
        )

        // Act
        await vm.load()

        // Assert
        XCTAssertNotNil(vm.item)
        XCTAssertEqual(vm.item?.question, "Q1")
        XCTAssertEqual(vm.item?.answer, "A1")
    }

    func testLoad_invalidUUID_setsNilAndReportsError() async throws {
        let vm = LibraryDetailViewModel(
            reviewItemService: service,
            itemId: "not-a-uuid",
            coordinator: coordinator,
            errorHandler: errorHandler
        )

        await vm.load()

        XCTAssertNil(vm.item)
    }

    func testLoad_nonExistingItem_setsNil() async throws {
        let random = UUID().uuidString
        let vm = LibraryDetailViewModel(
            reviewItemService: service,
            itemId: random,
            coordinator: coordinator,
            errorHandler: errorHandler
        )

        await vm.load()
        XCTAssertNil(vm.item)
    }

    func testStartPractice_coordinatesToPracticeMode() async throws {
        // Arrange
        let vm = LibraryDetailViewModel(
            reviewItemService: service,
            itemId: UUID().uuidString,
            coordinator: coordinator,
            errorHandler: errorHandler
        )

        // Act
        vm.startPractice()

        // Assert: navigation path should push one route
        XCTAssertEqual(coordinator.navigationPath.count, 1)
    }

    func testDeleteCurrentItem_removesItem() async throws {
        // Arrange: create one item and load it into VM
        let id = try await service.createReviewItem(
            question: "Q1",
            answer: "A1",
            subject: "math",
            difficulty: "easy",
            tags: ["t"],
            notes: nil
        )
        let vm = LibraryDetailViewModel(
            reviewItemService: service,
            itemId: id.value.uuidString,
            coordinator: coordinator,
            errorHandler: errorHandler
        )
        await vm.load()
        XCTAssertNotNil(vm.item)

        // Act
        await vm.deleteCurrentItem()

        // Assert
        XCTAssertNil(vm.item)
        let all = try await service.getAllItems()
        XCTAssertEqual(all.count, 0)
    }
}
