import XCTest
@testable import NotBad

@MainActor
final class LibraryViewModelCompletionTests: XCTestCase {
    func testCompletionPercentage_zeroItems_returnsZero() async throws {
        let repo = InMemoryReviewItemRepository()
        let service = ReviewItemService(repository: repo)
        let coordinator = LibraryCoordinator()
        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)

        // Ensure totalItems remains 0
        vm.totalItems = 0
        vm.reviewedItems = 0
        XCTAssertEqual(vm.completionPercentage, 0.0)
    }
}
