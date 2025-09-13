//
//  ReviewItemTests.swift
//  NotBadTests
//
//  Created by AI Assistant on 2025/9/13.
//

import XCTest
@testable import NotBad

// MARK: - ReviewItem实体测试
class ReviewItemTests: XCTestCase {
    
    func testReviewItemCreation() {
        // Given
        let content = ReviewContent(
            title: "数学题",
            question: "1+1等于多少？",
            answer: "2",
            subject: "数学",
            difficulty: .easy
        )
        
        let metadata = ReviewMetadata(
            ownerId: UUID(),
            source: .manual
        )
        
        // When
        let reviewItem = ReviewItem(
            content: content,
            metadata: metadata
        )
        
        // Then
        XCTAssertEqual(reviewItem.content.title, "数学题")
        XCTAssertEqual(reviewItem.content.question, "1+1等于多少？")
        XCTAssertEqual(reviewItem.content.answer, "2")
        XCTAssertEqual(reviewItem.content.subject, "数学")
        XCTAssertEqual(reviewItem.content.difficulty, .easy)
        XCTAssertEqual(reviewItem.masteryLevel, .notMastered)
        XCTAssertEqual(reviewItem.studyHistory.count, 0)
    }
    
    func testReviewItemEquality() {
        // Given
        let id = UUID()
        let ownerId = UUID()
        
        let content1 = ReviewContent(
            title: "数学题",
            question: "1+1等于多少？",
            answer: "2",
            subject: "数学",
            difficulty: .easy
        )
        
        let metadata1 = ReviewMetadata(
            ownerId: ownerId,
            source: .manual
        )
        
        let content2 = ReviewContent(
            title: "数学题",
            question: "1+1等于多少？",
            answer: "2",
            subject: "数学",
            difficulty: .easy
        )
        
        let metadata2 = ReviewMetadata(
            ownerId: ownerId,
            source: .manual
        )
        
        // When
        let item1 = ReviewItem(
            id: id,
            content: content1,
            metadata: metadata1
        )
        
        let item2 = ReviewItem(
            id: id,
            content: content2,
            metadata: metadata2
        )
        
        // Then
        XCTAssertEqual(item1, item2)
    }
    
    func testMasteryLevelDisplayName() {
        // Then
        XCTAssertEqual(MasteryLevel.notMastered.displayName, "未掌握")
        XCTAssertEqual(MasteryLevel.fuzzy.displayName, "模糊")
        XCTAssertEqual(MasteryLevel.mastered.displayName, "已掌握")
    }
    
    func testMasteryLevelColor() {
        // Then
        XCTAssertEqual(MasteryLevel.notMastered.color, "red")
        XCTAssertEqual(MasteryLevel.fuzzy.color, "orange")
        XCTAssertEqual(MasteryLevel.mastered.color, "green")
    }
    
    func testDifficultyLevelWeight() {
        // Then
        XCTAssertEqual(DifficultyLevel.easy.weight, 1)
        XCTAssertEqual(DifficultyLevel.medium.weight, 2)
        XCTAssertEqual(DifficultyLevel.hard.weight, 3)
    }
    
    func testStudyRecordCreation() {
        // When
        let studyRecord = StudyRecord(
            isCorrect: true,
            timeSpent: 30.0,
            notes: "做对了"
        )
        
        // Then
        XCTAssertTrue(studyRecord.isCorrect)
        XCTAssertEqual(studyRecord.timeSpent, 30.0)
        XCTAssertEqual(studyRecord.notes, "做对了")
    }
}

// MARK: - CreateReviewItemUseCase测试
class CreateReviewItemUseCaseTests: XCTestCase {
    
    private var useCase: CreateReviewItemUseCase!
    private var mockRepository: MockReviewItemRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockReviewItemRepository()
        useCase = CreateReviewItemUseCase(repository: mockRepository)
    }
    
    override func tearDown() {
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    func testCreateReviewItemSuccess() async throws {
        // Given
        let request = CreateReviewItemRequest(
            title: "数学题",
            question: "1+1等于多少？",
            answer: "2",
            subject: "数学",
            difficulty: .easy,
            ownerId: UUID(),
            source: .manual
        )
        
        let expectedItem = ReviewItem(
            content: ReviewContent(
                title: "数学题",
                question: "1+1等于多少？",
                answer: "2",
                subject: "数学",
                difficulty: .easy
            ),
            metadata: ReviewMetadata(
                ownerId: request.ownerId,
                source: .manual
            )
        )
        
        mockRepository.createResult = expectedItem
        
        // When
        let result = try await useCase.execute(request)
        
        // Then
        XCTAssertEqual(result.content.title, "数学题")
        XCTAssertEqual(result.content.question, "1+1等于多少？")
        XCTAssertEqual(result.content.answer, "2")
        XCTAssertEqual(result.content.subject, "数学")
        XCTAssertEqual(result.content.difficulty, .easy)
        XCTAssertTrue(mockRepository.createCalled)
    }
    
    func testCreateReviewItemWithEmptyTitle() async throws {
        // Given
        let request = CreateReviewItemRequest(
            title: "",
            question: "1+1等于多少？",
            subject: "数学",
            ownerId: UUID()
        )
        
        // When & Then
        do {
            _ = try await useCase.execute(request)
            XCTFail("应该抛出错误")
        } catch CreateReviewItemError.invalidTitle(let message) {
            XCTAssertEqual(message, "标题不能为空")
        } catch {
            XCTFail("错误的异常类型: \(error)")
        }
    }
    
    func testCreateReviewItemWithEmptyQuestion() async throws {
        // Given
        let request = CreateReviewItemRequest(
            title: "数学题",
            question: "",
            subject: "数学",
            ownerId: UUID()
        )
        
        // When & Then
        do {
            _ = try await useCase.execute(request)
            XCTFail("应该抛出错误")
        } catch CreateReviewItemError.invalidQuestion(let message) {
            XCTAssertEqual(message, "题目不能为空")
        } catch {
            XCTFail("错误的异常类型: \(error)")
        }
    }
    
    func testCreateReviewItemWithEmptySubject() async throws {
        // Given
        let request = CreateReviewItemRequest(
            title: "数学题",
            question: "1+1等于多少？",
            subject: "",
            ownerId: UUID()
        )
        
        // When & Then
        do {
            _ = try await useCase.execute(request)
            XCTFail("应该抛出错误")
        } catch CreateReviewItemError.invalidSubject(let message) {
            XCTAssertEqual(message, "科目不能为空")
        } catch {
            XCTFail("错误的异常类型: \(error)")
        }
    }
    
    func testCreateReviewItemWithLongTitle() async throws {
        // Given
        let longTitle = String(repeating: "a", count: 101)
        let request = CreateReviewItemRequest(
            title: longTitle,
            question: "1+1等于多少？",
            subject: "数学",
            ownerId: UUID()
        )
        
        // When & Then
        do {
            _ = try await useCase.execute(request)
            XCTFail("应该抛出错误")
        } catch CreateReviewItemError.invalidTitle(let message) {
            XCTAssertEqual(message, "标题长度不能超过100个字符")
        } catch {
            XCTFail("错误的异常类型: \(error)")
        }
    }
}

// MARK: - Mock仓储
class MockReviewItemRepository: ReviewItemRepository {
    var createResult: ReviewItem?
    var getByIdResult: ReviewItem?
    var getAllResult: [ReviewItem] = []
    var getByOwnerResult: [ReviewItem] = []
    var getBySubjectResult: [ReviewItem] = []
    var getByMasteryLevelResult: [ReviewItem] = []
    var searchResult: [ReviewItem] = []
    
    var createCalled = false
    var getByIdCalled = false
    var getAllCalled = false
    var getByOwnerCalled = false
    var getBySubjectCalled = false
    var getByMasteryLevelCalled = false
    var updateCalled = false
    var deleteCalled = false
    var deleteBatchCalled = false
    var searchCalled = false
    var addStudyRecordCalled = false
    var updateMasteryLevelCalled = false
    
    func create(_ item: ReviewItem) async throws -> ReviewItem {
        createCalled = true
        if let result = createResult {
            return result
        }
        throw ReviewItemRepositoryError.storageError("Mock error")
    }
    
    func getById(_ id: UUID) async throws -> ReviewItem? {
        getByIdCalled = true
        return getByIdResult
    }
    
    func getAll() async throws -> [ReviewItem] {
        getAllCalled = true
        return getAllResult
    }
    
    func getByOwner(_ ownerId: UUID) async throws -> [ReviewItem] {
        getByOwnerCalled = true
        return getByOwnerResult
    }
    
    func getBySubject(_ subject: String) async throws -> [ReviewItem] {
        getBySubjectCalled = true
        return getBySubjectResult
    }
    
    func getByMasteryLevel(_ masteryLevel: MasteryLevel) async throws -> [ReviewItem] {
        getByMasteryLevelCalled = true
        return getByMasteryLevelResult
    }
    
    func update(_ item: ReviewItem) async throws -> ReviewItem {
        updateCalled = true
        return item
    }
    
    func delete(_ id: UUID) async throws {
        deleteCalled = true
    }
    
    func deleteBatch(_ ids: [UUID]) async throws {
        deleteBatchCalled = true
    }
    
    func search(_ query: String) async throws -> [ReviewItem] {
        searchCalled = true
        return searchResult
    }
    
    func addStudyRecord(itemId: UUID, record: StudyRecord) async throws -> ReviewItem {
        addStudyRecordCalled = true
        return ReviewItem(
            content: ReviewContent(title: "Test", question: "Test", subject: "Test"),
            metadata: ReviewMetadata(ownerId: UUID())
        )
    }
    
    func updateMasteryLevel(itemId: UUID, masteryLevel: MasteryLevel) async throws -> ReviewItem {
        updateMasteryLevelCalled = true
        return ReviewItem(
            content: ReviewContent(title: "Test", question: "Test", subject: "Test"),
            metadata: ReviewMetadata(ownerId: UUID())
        )
    }
}