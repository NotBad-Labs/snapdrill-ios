//
//  CreateReviewItemUseCaseTests.swift
//  NotBadTests
//
//  Use Case 单元测试
//

import Testing
import Foundation
@testable import NotBad

// MARK: - CreateReviewItemUseCaseTests

@Suite("CreateReviewItemUseCase Tests")
@MainActor
struct CreateReviewItemUseCaseTests {
    
    // MARK: - Test Fixtures
    
    private func makeSUT() -> (sut: CreateReviewItemUseCase, repository: MockReviewItemRepository) {
        let repository = MockReviewItemRepository()
        let sut = CreateReviewItemUseCase(repository: repository)
        return (sut, repository)
    }
    
    private func makeValidInput() -> CreateReviewItemInput {
        CreateReviewItemInput(
            title: "测试错题",
            imageData: Data(),
            subject: .math,
            grade: .grade10,
            difficulty: .medium,
            errorType: .concept,
            knowledgePoints: ["知识点1"],
            note: "测试笔记"
        )
    }
    
    // MARK: - Success Tests
    
    @Test("创建错题成功")
    func testCreateReviewItem_success() async throws {
        // Given
        let (sut, repository) = makeSUT()
        let input = makeValidInput()
        
        // When
        let result = try await sut.execute(input: input)
        
        // Then
        #expect(result.title == "测试错题")
        #expect(result.subject == .math)
        #expect(result.grade == .grade10)
        #expect(repository.saveCalled == true)
    }
    
    @Test("创建错题保存到仓库")
    func testCreateReviewItem_savesToRepository() async throws {
        // Given
        let (sut, repository) = makeSUT()
        let input = makeValidInput()
        
        // When
        let result = try await sut.execute(input: input)
        
        // Then
        #expect(repository.items.contains { $0.id == result.id })
    }
    
    @Test("创建错题设置默认掌握度")
    func testCreateReviewItem_setsDefaultMasteryLevel() async throws {
        // Given
        let (sut, _) = makeSUT()
        let input = makeValidInput()
        
        // When
        let result = try await sut.execute(input: input)
        
        // Then
        #expect(result.masteryLevel == .none)
    }
    
    // MARK: - Validation Tests
    
    @Test("标题为空时抛出错误")
    func testCreateReviewItem_emptyTitle_throws() async {
        // Given
        let (sut, _) = makeSUT()
        var input = makeValidInput()
        input.title = ""
        
        // When/Then
        await #expect(throws: CreateReviewItemError.self) {
            try await sut.execute(input: input)
        }
    }
    
    @Test("标题过长时抛出错误")
    func testCreateReviewItem_titleTooLong_throws() async {
        // Given
        let (sut, _) = makeSUT()
        var input = makeValidInput()
        input.title = String(repeating: "A", count: 300)  // 超过最大长度
        
        // When/Then
        await #expect(throws: CreateReviewItemError.self) {
            try await sut.execute(input: input)
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Test("保存失败时抛出 saveFailed 错误")
    func testCreateReviewItem_saveFails_throwsSaveFailed() async {
        // Given
        let (sut, repository) = makeSUT()
        repository.shouldFailOnSave = true
        let input = makeValidInput()
        
        // When/Then
        await #expect(throws: CreateReviewItemError.self) {
            try await sut.execute(input: input)
        }
    }
}
