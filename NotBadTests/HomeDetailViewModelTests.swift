//
//  HomeDetailViewModelTests.swift
//  NotBadTests
//
//  Created by GitHub Copilot on 9/22/25.
//

import XCTest
@testable import NotBad

@MainActor
final class HomeDetailViewModelTests: XCTestCase {
    var repository: InMemoryReviewItemRepository!
    var service: ReviewItemService!
    var coordinator: HomeCoordinator!
    var errorHandler: AppErrorHandler!

    override func setUp() async throws {
        repository = InMemoryReviewItemRepository()
        service = ReviewItemService(repository: repository)
        coordinator = HomeCoordinator()
        errorHandler = AppErrorHandler()
    }

    override func tearDown() async throws {
        repository = nil
        service = nil
        coordinator = nil
        errorHandler = nil
    }

    func testLoad_validId_loadsItem() async throws {
        // Arrange
        let id = try await service.createReviewItem(
            question: "Q1",
            answer: "A1",
            subject: "math",
            difficulty: "easy",
            tags: ["tag1"],
            notes: "note"
        )

        let vm = HomeDetailViewModel(
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
        let vm = HomeDetailViewModel(
            reviewItemService: service,
            itemId: "not-a-uuid",
            coordinator: coordinator,
            errorHandler: errorHandler
        )

        await vm.load()

        XCTAssertNil(vm.item)
    }

    func testLoad_nonExistingItem_setsNil() async throws {
        let vm = HomeDetailViewModel(
            reviewItemService: service,
            itemId: UUID().uuidString,
            coordinator: coordinator,
            errorHandler: errorHandler
        )

        await vm.load()
        XCTAssertNil(vm.item)
    }
}
