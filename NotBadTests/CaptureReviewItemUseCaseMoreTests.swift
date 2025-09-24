//
//  CaptureReviewItemUseCaseMoreTests.swift
//  NotBadTests
//
//  Created by GitHub Copilot on 9/23/25.
//

import XCTest
@testable import NotBad

final class CaptureReviewItemUseCaseMoreTests: XCTestCase {
    var useCase: CaptureReviewItemUseCase! = nil
    var reviewItemService: ReviewItemService! = nil
    var repository: ReviewItemRepository! = nil

    override func setUp() {
        super.setUp()
        repository = InMemoryReviewItemRepository()
        reviewItemService = ReviewItemService(repository: repository)
        useCase = CaptureReviewItemUseCase(reviewItemService: reviewItemService)
    }

    override func tearDown() {
        useCase = nil
        reviewItemService = nil
        repository = nil
        super.tearDown()
    }

    func testCaptureFromOCR_withWhitespaceOnlyQuestion_throws() async throws {
        let input = ReviewItemUserInput(
            question: "   \n\t   ",
            answer: "Answer",
            subject: .other,
            difficulty: .easy,
            tags: [],
            notes: nil
        )

        do {
            _ = try await useCase.captureFromOCR(ocrText: "raw", userInput: input)
            XCTFail("Expected missingRequiredFields error")
        } catch CaptureError.missingRequiredFields {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCaptureFromOCR_withWhitespaceOnlyAnswer_throws() async throws {
        let input = ReviewItemUserInput(
            question: "Question",
            answer: "   \n\t   ",
            subject: .math,
            difficulty: .medium,
            tags: ["tag1"],
            notes: nil
        )

        do {
            _ = try await useCase.captureFromOCR(ocrText: "raw", userInput: input)
            XCTFail("Expected missingRequiredFields error")
        } catch CaptureError.missingRequiredFields {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCaptureFromUserInput_withWhitespaceOnlyAnswer_throws() async throws {
        let input = ReviewItemUserInput(
            question: "Q",
            answer: "  \t  ",
            subject: .english,
            difficulty: .hard,
            tags: [],
            notes: nil
        )

        do {
            _ = try await useCase.captureFromUserInput(input)
            XCTFail("Expected missingRequiredFields error")
        } catch CaptureError.missingRequiredFields {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCaptureFromUserInput_withLongAndSpecialCharacters_succeeds() async throws {
        let longQuestion = String(repeating: "复杂字符𝌆🌟❄️-", count: 50) + "?"
        let longAnswer = String(repeating: "答案✅-", count: 80)

        let input = ReviewItemUserInput(
            question: longQuestion,
            answer: longAnswer,
            subject: .literature,
            difficulty: .medium,
            tags: ["long", "unicode", "edge"],
            notes: "包含特殊字符与超长文本"
        )

        let id = try await useCase.captureFromUserInput(input)
        XCTAssertNotNil(id)

        // Verify fields persisted
        let items = try await reviewItemService.getAllItems()
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.question, longQuestion)
        XCTAssertEqual(items.first?.answer, longAnswer)
        XCTAssertEqual(items.first?.subject, .literature)
        XCTAssertEqual(items.first?.difficulty, .medium)
        XCTAssertEqual(items.first?.tags, Set(["long", "unicode", "edge"]))
        XCTAssertEqual(items.first?.notes, "包含特殊字符与超长文本")
    }

    func testCaptureError_errorDescription_isLocalized() {
        let error: CaptureError = .missingRequiredFields
        XCTAssertEqual(error.errorDescription, "请填写完整的题目和答案")
    }

    func testReviewItemDraft_isValid_trueAndFalseCases() {
        let valid = ReviewItemDraft(
            question: "1+1?",
            answer: "2",
            subject: .math,
            difficulty: .easy,
            tags: [],
            notes: nil
        )
        XCTAssertTrue(valid.isValid)

        let invalidQ = ReviewItemDraft(
            question: "   ",
            answer: "A",
            subject: .history,
            difficulty: .medium,
            tags: [],
            notes: nil
        )
        XCTAssertFalse(invalidQ.isValid)

        let invalidA = ReviewItemDraft(
            question: "Q",
            answer: "\n\t  ",
            subject: .geography,
            difficulty: .hard,
            tags: [],
            notes: nil
        )
        XCTAssertFalse(invalidA.isValid)
    }
}
