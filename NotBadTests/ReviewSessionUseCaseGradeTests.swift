import XCTest
@testable import NotBad

final class ReviewSessionUseCaseGradeTests: XCTestCase {
    func makeServiceWithItems(_ n: Int) async throws -> ReviewItemService {
        let repo = InMemoryReviewItemRepository()
        let service = ReviewItemService(repository: repo)
        for i in 0..<n {
            _ = try await service.createReviewItem(
                question: "Q\(i)",
                answer: "A\(i)",
                subject: "数学",
                difficulty: "中等",
                tags: [],
                notes: nil
            )
        }
        return service
    }

    func testGradeBoundaries_needImprovement_fair_good_excellent() async throws {
        // Session 1: 0/5 correct → needsImprovement
        let service1 = try await makeServiceWithItems(5)
        let useCase1 = ReviewSessionUseCase(reviewItemService: service1)
        let info = try await useCase1.startReviewSession(maxItems: 5)

        // Submit answers: 0 correct → needsImprovement
        for _ in 0..<4 { _ = try await useCase1.submitAnswer(sessionId: info.sessionId, wasSuccessful: false) }
        // Complete last question and end session
        if case .completed(let result) = try await useCase1.submitAnswer(sessionId: info.sessionId, wasSuccessful: false) {
            XCTAssertEqual(result.grade, .needsImprovement)
        } else { XCTFail("Expected completed result") }

        // Session 2: 3/5 correct → fair (60%)
        let service2 = try await makeServiceWithItems(5)
        let useCase2 = ReviewSessionUseCase(reviewItemService: service2)
        let info2 = try await useCase2.startReviewSession(maxItems: 5)
        for _ in 0..<3 { _ = try await useCase2.submitAnswer(sessionId: info2.sessionId, wasSuccessful: true) } // 3 correct
        _ = try await useCase2.submitAnswer(sessionId: info2.sessionId, wasSuccessful: false) // 4th answer (incorrect)
        if case .completed(let result2) = try await useCase2.submitAnswer(sessionId: info2.sessionId, wasSuccessful: false) { // 5th answer (incorrect)
            XCTAssertEqual(result2.correctAnswers, 3)
            XCTAssertEqual(result2.grade, .fair)
            XCTAssertEqual(result2.totalItems, 5)
        } else { XCTFail("Expected completed result for fair grade") }

        // Session 3: 4/5 correct → good (0.8)
        let service3 = try await makeServiceWithItems(5)
        let useCase3 = ReviewSessionUseCase(reviewItemService: service3)
        let info3 = try await useCase3.startReviewSession(maxItems: 5)
        // 4/5 correct → good (0.8)
        for _ in 0..<4 { _ = try await useCase3.submitAnswer(sessionId: info3.sessionId, wasSuccessful: true) }
        if case .completed(let result3) = try await useCase3.submitAnswer(sessionId: info3.sessionId, wasSuccessful: false) {
            XCTAssertEqual(result3.correctAnswers, 4)
            XCTAssertEqual(result3.grade, .good)
        }

        // Session 4: 5/5 correct → excellent (>=0.9)
        let service4 = try await makeServiceWithItems(5)
        let useCase4 = ReviewSessionUseCase(reviewItemService: service4)
        let info4 = try await useCase4.startReviewSession(maxItems: 5)
        for _ in 0..<4 { _ = try await useCase4.submitAnswer(sessionId: info4.sessionId, wasSuccessful: true) }
        if case .completed(let result4) = try await useCase4.submitAnswer(sessionId: info4.sessionId, wasSuccessful: true) {
            XCTAssertEqual(result4.correctAnswers, 5)
            XCTAssertEqual(result4.grade, .excellent)
        }
    }

    func testEndSessionEarly_returnsComputedResult() async throws {
        let service = try await makeServiceWithItems(3)
        let useCase = ReviewSessionUseCase(reviewItemService: service)
        let info = try await useCase.startReviewSession(maxItems: 3)
        _ = try await useCase.submitAnswer(sessionId: info.sessionId, wasSuccessful: true)
        let result = try useCase.endSession(sessionId: info.sessionId)
        XCTAssertEqual(result.completedItems, 1)
        XCTAssertGreaterThan(result.duration, 0)
    }
}
