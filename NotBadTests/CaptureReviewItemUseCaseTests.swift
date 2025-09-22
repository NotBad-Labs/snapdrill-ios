//
//  CaptureReviewItemUseCaseTests.swift
//  NotBadTests
//
//  Created by Yiming Liao on 9/21/25.
//

import XCTest
@testable import NotBad

final class CaptureReviewItemUseCaseTests: XCTestCase {
    var useCase: CaptureReviewItemUseCase!
    var reviewItemService: ReviewItemService!
    var repository: ReviewItemRepository!
    
    override func setUp() {
        super.setUp()
        // 使用新的 Repository 架构
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
    
    func testCaptureFromOCR() async throws {
        // Given
        let ocrText = "What is the capital of France?" // OCR文本仅作为参考
        let userInput = ReviewItemUserInput(
            question: "What is the capital of France?",
            answer: "Paris",
            subject: .geography,
            difficulty: .medium,
            tags: ["geography", "capital"],
            notes: nil
        )
        
        // When
        let reviewItemID = try await useCase.captureFromOCR(
            ocrText: ocrText,
            userInput: userInput
        )
        
        // Then
        XCTAssertNotNil(reviewItemID)
        
        // Verify it was saved
        let savedItems = try await reviewItemService.getAllItems()
        XCTAssertEqual(savedItems.count, 1)
        XCTAssertEqual(savedItems.first?.question, "What is the capital of France?")
        XCTAssertEqual(savedItems.first?.answer, "Paris")
    }
    
    func testCaptureFromUserInput() async throws {
        // Given
        let userInput = ReviewItemUserInput(
            question: "Explain quantum entanglement",
            answer: "Quantum entanglement is a phenomenon where particles become connected...",
            subject: .physics,
            difficulty: .hard,
            tags: ["physics", "quantum"],
            notes: "Important concept in quantum mechanics"
        )
        
        // When
        let reviewItemID = try await useCase.captureFromUserInput(userInput)
        
        // Then
        XCTAssertNotNil(reviewItemID)
        
        // Verify it was saved
        let savedItems = try await reviewItemService.getAllItems()
        XCTAssertEqual(savedItems.count, 1)
        XCTAssertEqual(savedItems.first?.question, "Explain quantum entanglement")
        XCTAssertEqual(savedItems.first?.answer, "Quantum entanglement is a phenomenon where particles become connected...")
        XCTAssertEqual(savedItems.first?.subject, .physics)
    }
    
    func testCaptureFromUserInput_WithMissingFields() async throws {
        // Given
        let invalidUserInput = ReviewItemUserInput(
            question: "",  // Empty question
            answer: "Some answer",
            subject: .math,
            difficulty: .easy,
            tags: [],
            notes: nil
        )
        
        // When & Then
        do {
            _ = try await useCase.captureFromUserInput(invalidUserInput)
            XCTFail("Should have thrown an error for missing required fields")
        } catch CaptureError.missingRequiredFields {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}