// NotBadTests/HomeDetailViewModelMoreTests.swift
// Covers additional negative and success branches for HomeDetailViewModel

import XCTest
@testable import NotBad

@MainActor
final class HomeDetailViewModelMoreTests: XCTestCase {
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

    func testLoad_invalidUUID_setsNil_andInvokesErrorHandler() async throws {
        let vm = HomeDetailViewModel(
            reviewItemService: service,
            itemId: "bad-uuid",
            coordinator: coordinator,
            errorHandler: errorHandler
        )
        await vm.load()
        XCTAssertNil(vm.item)
    }

    func testLoad_validId_notFound_invokesErrorHandler_setsNil() async throws {
        let vm = HomeDetailViewModel(
            reviewItemService: service,
            itemId: UUID().uuidString,
            coordinator: coordinator,
            errorHandler: errorHandler
        )
        await vm.load()
        XCTAssertNil(vm.item)
    }

    func testLoad_validId_success_setsItem_andStopsLoading() async throws {
        let id = try await service.createReviewItem(
            question: "Q",
            answer: "A",
            subject: "s",
            difficulty: "easy",
            tags: [],
            notes: nil
        )
        let vm = HomeDetailViewModel(
            reviewItemService: service,
            itemId: id.value.uuidString,
            coordinator: coordinator,
            errorHandler: errorHandler
        )
        await vm.load()
        XCTAssertNotNil(vm.item)
    }

    func testLoad_serviceThrows_setsNil_andInvokesErrorHandler() async throws {
        struct ThrowingService: ReviewItemServicing {
            func createReviewItem(question: String, answer: String, subject: String, difficulty: String, tags: [String], notes: String?) async throws -> ReviewItemID {
                throw TestError.boom
            }
            func getReviewItem(id: ReviewItemID) async throws -> ReviewItem? { throw TestError.boom }
            func updateReviewItem(id: ReviewItemID, updates: ReviewItemUpdates) async throws { /* no-op */ }
            func deleteReviewItem(id: ReviewItemID) async throws { /* no-op */ }
            func recordReviewResult(id: ReviewItemID, wasSuccessful: Bool) async throws { /* no-op */ }
            func getItemsForReview(date: Date, limit: Int) async throws -> [ReviewItem] { return [] }
            func getAllItems() async throws -> [ReviewItem] { return [] }
            func searchReviewItems(query: String, limit: Int) async throws -> [ReviewItem] { return [] }
            func getItemsByCriteria(_ criteria: ReviewItemQueryCriteria) async throws -> [ReviewItem] { return [] }
            func getStatistics() async throws -> ReviewItemStatistics {
                return ReviewItemStatistics(
                    total: 0,
                    difficultyBreakdown: DifficultyBreakdown(easy: 0, medium: 0, hard: 0),
                    proficiencyBreakdown: ProficiencyBreakdown(notProficient: 0, learning: 0, proficient: 0)
                )
            }
        }
        enum TestError: LocalizedError { case boom }
        let vm = HomeDetailViewModel(
            reviewItemService: ThrowingService(),
            itemId: UUID().uuidString,
            coordinator: coordinator,
            errorHandler: errorHandler
        )
        await vm.load()
        XCTAssertNil(vm.item)
    }
}
