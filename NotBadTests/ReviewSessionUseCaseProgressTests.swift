import XCTest
@testable import NotBad

@MainActor
final class ReviewSessionUseCaseProgressTests: XCTestCase {
    private func makeServiceWithItems(_ n: Int) async throws -> ReviewItemService {
        let repo = InMemoryReviewItemRepository()
        let service = ReviewItemService(repository: repo)
        for i in 0..<n {
            _ = try await service.createReviewItem(
                question: "Q\(i)",
                answer: "A\(i)",
                subject: ReviewItem.Subject.math.rawValue,
                difficulty: ReviewItem.Difficulty.medium.rawValue,
                tags: [],
                notes: nil
            )
        }
        return service
    }

    func testProgress_updatesAfterEachAnswer_untilCompletion() async throws {
        // Given 5 items queued for review
        let service = try await makeServiceWithItems(5)
        let useCase = ReviewSessionUseCase(reviewItemService: service)
        let info = try await useCase.startReviewSession(maxItems: 5)

        // When & Then: progress starts at 0.0
        let start = try useCase.getCurrentSessionInfo(sessionId: info.sessionId)
        XCTAssertNotNil(start)
        XCTAssertEqual(start?.progress ?? -1, 0.0, accuracy: 0.0001)

        // Answer first 4 questions and check progress increments by 0.2 each time
        for answered in 1...4 {
            _ = try await useCase.submitAnswer(sessionId: info.sessionId, wasSuccessful: true)
            let current = try useCase.getCurrentSessionInfo(sessionId: info.sessionId)
            XCTAssertNotNil(current)
            let expected = Double(answered) / 5.0
            XCTAssertEqual(current?.progress ?? -1, expected, accuracy: 0.0001)
        }

        // Final answer completes the session; progress becomes 1.0 but session is cleared
        let progressBeforeCompletion = try useCase.getCurrentSessionInfo(sessionId: info.sessionId)
        XCTAssertEqual(progressBeforeCompletion?.progress ?? -1, 0.8, accuracy: 0.0001)
        if case .completed(let result) = try await useCase.submitAnswer(sessionId: info.sessionId, wasSuccessful: true) {
            XCTAssertEqual(result.completedItems, 5)
            XCTAssertEqual(result.totalItems, 5)
            XCTAssertEqual(result.correctAnswers, 5)
            XCTAssertEqual(result.grade, .excellent)
        } else {
            XCTFail("Expected session to complete on last answer")
        }

        let after = try useCase.getCurrentSessionInfo(sessionId: info.sessionId)
        XCTAssertNil(after)
    }
}
