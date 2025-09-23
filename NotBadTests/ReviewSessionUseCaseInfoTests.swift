import XCTest
@testable import NotBad

final class ReviewSessionUseCaseInfoTests: XCTestCase {
    func testGetCurrentSessionInfo_invalidSessionId_returnsNil() async throws {
        // Prepare service with at least one item
        let repo = InMemoryReviewItemRepository()
        let service = ReviewItemService(repository: repo)
        _ = try await service.createReviewItem(
            question: "Q",
            answer: "A",
            subject: "数学",
            difficulty: "中等",
            tags: [],
            notes: nil
        )

        let useCase = ReviewSessionUseCase(reviewItemService: service)
        let info = try await useCase.startReviewSession(maxItems: 1)

        // Random different sessionId should return nil
        let otherId = UUID()
        XCTAssertNotEqual(otherId, info.sessionId)
        let current = try useCase.getCurrentSessionInfo(sessionId: otherId)
        XCTAssertNil(current)
    }
}
