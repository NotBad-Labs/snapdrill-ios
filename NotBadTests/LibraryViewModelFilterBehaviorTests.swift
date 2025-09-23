import XCTest
@testable import NotBad

@MainActor
final class LibraryViewModelFilterBehaviorTests: XCTestCase {
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

    func testApplyFilters_hidesFilterPanel_andReloads() async throws {
        // Seed two items for visibility
        _ = try await service.createReviewItem(
            question: "Physics A",
            answer: "A",
            subject: ReviewItem.Subject.physics.rawValue,
            difficulty: ReviewItem.Difficulty.easy.rawValue,
            tags: [],
            notes: nil
        )
        _ = try await service.createReviewItem(
            question: "Math B",
            answer: "B",
            subject: ReviewItem.Subject.math.rawValue,
            difficulty: ReviewItem.Difficulty.hard.rawValue,
            tags: [],
            notes: nil
        )

        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)
        await vm.loadReviewItems()
        XCTAssertEqual(vm.reviewItems.count, 2)

        vm.showFilters = true
        vm.selectedSubject = .math
        vm.applyFilters()
        // allow async load to finish
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertFalse(vm.showFilters)
        XCTAssertEqual(vm.reviewItems.count, 1)
    }
}
