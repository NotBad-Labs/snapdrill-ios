// NotBadTests/ReviewSessionUseCaseMoreTests.swift
// Focus: sessionAlreadyInProgress branch and getCurrentSessionInfo.progress at 0

import XCTest
@testable import NotBad

final class ReviewSessionUseCaseMoreTests: XCTestCase {
    private var reviewSessionUseCase: ReviewSessionUseCase!
    private var mockRepository: InMemoryReviewItemRepository!
    private var reviewItemService: ReviewItemService!

    override func setUp() {
        super.setUp()
        mockRepository = InMemoryReviewItemRepository()
        reviewItemService = ReviewItemService(repository: mockRepository)
        reviewSessionUseCase = ReviewSessionUseCase(reviewItemService: reviewItemService)
    }

    override func tearDown() {
        reviewSessionUseCase = nil
        reviewItemService = nil
        mockRepository = nil
        super.tearDown()
    }

    func testStartReviewSession_whileActive_throwsAlreadyInProgress() async throws {
        // Given
        // Seed one item so session can start
        _ = try await reviewItemService.createReviewItem(
            question: "Q",
            answer: "A",
            subject: ReviewItem.Subject.math.rawValue,
            difficulty: ReviewItem.Difficulty.easy.rawValue,
            tags: [],
            notes: nil
        )

        // Start first session
        let info = try await reviewSessionUseCase.startReviewSession(maxItems: 1)
        XCTAssertEqual(info.progress, 0.0)

        // When & Then: starting again should throw
        do {
            _ = try await reviewSessionUseCase.startReviewSession(maxItems: 1)
            XCTFail("Expected sessionAlreadyInProgress error")
        } catch ReviewSessionError.sessionAlreadyInProgress {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
