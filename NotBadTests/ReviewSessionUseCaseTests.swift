//
//  ReviewSessionUseCaseTests.swift
//  NotBadTests
//
//  Created by Testing Framework on 9/22/25.
//

import XCTest
@testable import NotBad

final class ReviewSessionUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    private var reviewSessionUseCase: ReviewSessionUseCase!
    private var mockRepository: InMemoryReviewItemRepository!
    private var reviewItemService: ReviewItemService!
    private var testItems: [ReviewItem]!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // Setup dependencies
        mockRepository = InMemoryReviewItemRepository()
        reviewItemService = ReviewItemService(repository: mockRepository!)
        reviewSessionUseCase = ReviewSessionUseCase(reviewItemService: reviewItemService!)
        
        // Initialize testItems array - will be populated in individual tests
        testItems = []
    }
    
    override func tearDown() {
        reviewSessionUseCase = nil
        reviewItemService = nil
        mockRepository = nil
        testItems = nil
        super.tearDown()
    }
    
    // MARK: - Setup Helpers
    
    private func setupTestItems() async {
        do {
            testItems = [
                try ReviewItem(
                    question: "什么是Swift?",
                    answer: "苹果开发的编程语言",
                    subject: .other,
                    difficulty: .medium,
                    tags: ["Swift", "编程"],
                    notes: "重要概念",
                    source: .manual
                ),
                try ReviewItem(
                    question: "什么是iOS?",
                    answer: "苹果的移动操作系统",
                    subject: .other,
                    difficulty: .easy,
                    tags: ["iOS", "系统"],
                    notes: "基础知识",
                    source: .manual
                ),
                try ReviewItem(
                    question: "什么是SwiftUI?",
                    answer: "苹果的UI框架",
                    subject: .other,
                    difficulty: .hard,
                    tags: ["SwiftUI", "UI"],
                    notes: "现代UI开发",
                    source: .manual
                )
            ]
            
            // Save test items to repository
            for item in testItems {
                try await reviewItemService.createReviewItem(
                    question: item.question,
                    answer: item.answer,
                    subject: item.subject.rawValue,
                    difficulty: item.difficulty.rawValue,
                    tags: Array(item.tags),
                    notes: item.notes ?? ""
                )
            }
        } catch {
            XCTFail("Failed to create test items: \(error)")
        }
    }
    
    // MARK: - Start Review Session Tests
    
    func testStartReviewSession_withAvailableItems_returnsSessionInfo() async throws {
        // Given
        await setupTestItems()
        
        // When
        let sessionInfo = try await reviewSessionUseCase.startReviewSession(maxItems: 2)
        
        // Then
        XCTAssertEqual(sessionInfo.totalItems, 2)
        XCTAssertEqual(sessionInfo.currentIndex, 0)
        XCTAssertEqual(sessionInfo.progress, 0.0) // 0/2 = 0.0 initially
        XCTAssertNotNil(sessionInfo.sessionId)
        XCTAssertEqual(sessionInfo.currentItem.question, testItems[0].question)
    }
    
    func testStartReviewSession_withNoAvailableItems_throwsError() async throws {
        // Given - Ensure repository is empty (fresh setUp already provides empty repo)
        
        // When & Then
        do {
            _ = try await reviewSessionUseCase.startReviewSession()
            XCTFail("Expected error to be thrown")
        } catch ReviewSessionError.noItemsToReview {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \\(error)")
        }
    }
    
    func testStartReviewSession_withMaxItemsLimit_respectsLimit() async throws {
        // Given
        await setupTestItems()
        
        // When
        let sessionInfo = try await reviewSessionUseCase.startReviewSession(maxItems: 1)
        
        // Then
        XCTAssertEqual(sessionInfo.totalItems, 1)
    }
    
    // MARK: - Submit Answer Tests
    
    func testSubmitAnswer_correctAnswer_recordsSuccessAndMovesToNext() async throws {
        // Given
        await setupTestItems()
        let sessionInfo = try await reviewSessionUseCase.startReviewSession(maxItems: 2)
        let sessionId = sessionInfo.sessionId
        
        // When
        let progress = try await reviewSessionUseCase.submitAnswer(
            sessionId: sessionId,
            wasSuccessful: true
        )
        
        // Then
        switch progress {
        case .nextItem(let nextInfo):
            XCTAssertEqual(nextInfo.currentIndex, 1)
            XCTAssertEqual(nextInfo.totalItems, 2)
            XCTAssertEqual(nextInfo.progress, 0.5) // 1/2 = 0.5
            XCTAssertEqual(nextInfo.sessionId, sessionId)
        case .completed:
            XCTFail("Should not be completed yet")
        }
    }
    
    func testSubmitAnswer_incorrectAnswer_recordsFailureAndMovesToNext() async throws {
        // Given
        await setupTestItems()
        let sessionInfo = try await reviewSessionUseCase.startReviewSession(maxItems: 2)
        let sessionId = sessionInfo.sessionId
        
        // When
        let progress = try await reviewSessionUseCase.submitAnswer(
            sessionId: sessionId,
            wasSuccessful: false
        )
        
        // Then
        switch progress {
        case .nextItem(let nextInfo):
            XCTAssertEqual(nextInfo.currentIndex, 1)
            XCTAssertEqual(nextInfo.sessionId, sessionId)
        case .completed:
            XCTFail("Should not be completed yet")
        }
    }
    
    func testSubmitAnswer_lastItem_completesSession() async throws {
        // Given
        await setupTestItems()
        let sessionInfo = try await reviewSessionUseCase.startReviewSession(maxItems: 1)
        let sessionId = sessionInfo.sessionId
        
        // When
        let progress = try await reviewSessionUseCase.submitAnswer(
            sessionId: sessionId,
            wasSuccessful: true
        )
        
        // Then
        switch progress {
        case .nextItem:
            XCTFail("Should be completed")
        case .completed(let result):
            XCTAssertEqual(result.sessionId, sessionId)
            XCTAssertEqual(result.totalItems, 1)
            XCTAssertEqual(result.completedItems, 1)
            XCTAssertEqual(result.correctAnswers, 1)
            XCTAssertEqual(result.accuracy, 1.0)
            XCTAssertTrue(result.duration > 0)
        }
    }
    
    func testSubmitAnswer_invalidSession_throwsError() async throws {
        // Given
        let invalidSessionId = UUID()
        
        // When & Then
        do {
            _ = try await reviewSessionUseCase.submitAnswer(
                sessionId: invalidSessionId,
                wasSuccessful: true
            )
            XCTFail("Expected error to be thrown")
        } catch ReviewSessionError.invalidSession {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \\(error)")
        }
    }
    
    // MARK: - Get Current Session Info Tests
    
    func testGetCurrentSessionInfo_validSession_returnsInfo() async throws {
        // Given
        await setupTestItems()
        let sessionInfo = try await reviewSessionUseCase.startReviewSession(maxItems: 2)
        let sessionId = sessionInfo.sessionId
        
        // When
        let currentInfo = try reviewSessionUseCase.getCurrentSessionInfo(sessionId: sessionId)
        
        // Then
        XCTAssertNotNil(currentInfo)
        XCTAssertEqual(currentInfo?.sessionId, sessionId)
        XCTAssertEqual(currentInfo?.totalItems, 2)
        XCTAssertEqual(currentInfo?.currentIndex, 0)
    }
    
    func testGetCurrentSessionInfo_invalidSession_returnsNil() throws {
        // Given
        let invalidSessionId = UUID()
        
        // When
        let currentInfo = try reviewSessionUseCase.getCurrentSessionInfo(sessionId: invalidSessionId)
        
        // Then
        XCTAssertNil(currentInfo)
    }
    
    func testGetCurrentSessionInfo_noActiveSession_returnsNil() throws {
        // Given - No active session
        let sessionId = UUID()
        
        // When
        let currentInfo = try reviewSessionUseCase.getCurrentSessionInfo(sessionId: sessionId)
        
        // Then
        XCTAssertNil(currentInfo)
    }
    
    // MARK: - End Session Tests
    
    func testEndSession_validSession_returnsResult() async throws {
        // Given
        await setupTestItems()
        let sessionInfo = try await reviewSessionUseCase.startReviewSession(maxItems: 1)
        let sessionId = sessionInfo.sessionId
        
        // When
        let result = try reviewSessionUseCase.endSession(sessionId: sessionId)
        
        // Then
        XCTAssertEqual(result.sessionId, sessionId)
        XCTAssertEqual(result.totalItems, 1)
        XCTAssertEqual(result.completedItems, 0) // No answers submitted
        XCTAssertEqual(result.correctAnswers, 0)
        XCTAssertEqual(result.accuracy, 0.0)
        XCTAssertTrue(result.duration >= 0)
    }
    
    func testEndSession_invalidSession_throwsError() throws {
        // Given
        let invalidSessionId = UUID()
        
        // When & Then
        XCTAssertThrowsError(try reviewSessionUseCase.endSession(sessionId: invalidSessionId)) { error in
            XCTAssertTrue(error is ReviewSessionError)
            XCTAssertEqual(error as? ReviewSessionError, .invalidSession)
        }
    }
    
    // MARK: - Session Result Tests
    
    func testSessionResult_accuracyCalculation_calculatesCorrectly() async throws {
        // Given
        await setupTestItems()
        let sessionInfo = try await reviewSessionUseCase.startReviewSession(maxItems: 3)
        let sessionId = sessionInfo.sessionId
        
        // When - Submit mixed answers (2 correct, 1 incorrect)
        _ = try await reviewSessionUseCase.submitAnswer(sessionId: sessionId, wasSuccessful: true)
        _ = try await reviewSessionUseCase.submitAnswer(sessionId: sessionId, wasSuccessful: false)
        let progress = try await reviewSessionUseCase.submitAnswer(sessionId: sessionId, wasSuccessful: true)
        
        // Then
        switch progress {
        case .completed(let result):
            XCTAssertEqual(result.totalItems, 3)
            XCTAssertEqual(result.completedItems, 3)
            XCTAssertEqual(result.correctAnswers, 2)
            XCTAssertEqual(result.accuracy, 2.0/3.0, accuracy: 0.001)
        case .nextItem:
            XCTFail("Should be completed")
        }
    }
    
    func testSessionResult_gradeCalculation_returnsCorrectGrade() async throws {
        // Test excellent grade (90%+)
        await testGradeCalculation(correctAnswers: 9, totalAnswers: 10, expectedGrade: .excellent)
        
        // Test good grade (80-89%)
        await testGradeCalculation(correctAnswers: 8, totalAnswers: 10, expectedGrade: .good)
        
        // Test fair grade (60-79%)
        await testGradeCalculation(correctAnswers: 7, totalAnswers: 10, expectedGrade: .fair)
        
        // Test needs improvement (<60%)
        await testGradeCalculation(correctAnswers: 5, totalAnswers: 10, expectedGrade: .needsImprovement)
    }
    
    private func testGradeCalculation(correctAnswers: Int, totalAnswers: Int, expectedGrade: ReviewGrade) async {
        let accuracy = Double(correctAnswers) / Double(totalAnswers)
        let result = ReviewSessionResult(
            sessionId: UUID(),
            totalItems: totalAnswers,
            completedItems: totalAnswers,
            correctAnswers: correctAnswers,
            accuracy: accuracy,
            duration: 60.0,
            startTime: Date(),
            endTime: Date()
        )
        
        XCTAssertEqual(result.grade, expectedGrade)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteReviewSession_endToEnd_worksCorrectly() async throws {
        // Given
        await setupTestItems()
        let sessionInfo = try await reviewSessionUseCase.startReviewSession(maxItems: 2)
        let sessionId = sessionInfo.sessionId
        
        // When - Complete full session
        let firstProgress = try await reviewSessionUseCase.submitAnswer(sessionId: sessionId, wasSuccessful: true)
        let secondProgress = try await reviewSessionUseCase.submitAnswer(sessionId: sessionId, wasSuccessful: false)
        
        // Then - First answer should continue
        switch firstProgress {
        case .nextItem(let info):
            XCTAssertEqual(info.currentIndex, 1)
        case .completed:
            XCTFail("Should not be completed after first answer")
        }
        
        // Then - Second answer should complete
        switch secondProgress {
        case .nextItem:
            XCTFail("Should be completed after second answer")
        case .completed(let result):
            XCTAssertEqual(result.sessionId, sessionId)
            XCTAssertEqual(result.totalItems, 2)
            XCTAssertEqual(result.completedItems, 2)
            XCTAssertEqual(result.correctAnswers, 1)
            XCTAssertEqual(result.accuracy, 0.5)
            XCTAssertEqual(result.grade, .needsImprovement)
        }
        
        // Then - Session should be cleared
        let sessionInfoAfter = try reviewSessionUseCase.getCurrentSessionInfo(sessionId: sessionId)
        XCTAssertNil(sessionInfoAfter)
    }
}