//
//  DeleteReviewItemUseCaseTests.swift
//  NotBadTests
//
//  Use Case 单元测试
//

import Testing
import Foundation
@testable import NotBad

// MARK: - DeleteReviewItemUseCaseTests

@Suite("DeleteReviewItemUseCase Tests")
@MainActor
struct DeleteReviewItemUseCaseTests {
    
    // MARK: - Test Fixtures
    
    private func makeSUT() -> (sut: DeleteReviewItemUseCase, repository: MockReviewItemRepository) {
        let repository = MockReviewItemRepository()
        let sut = DeleteReviewItemUseCase(repository: repository)
        return (sut, repository)
    }
    
    private func makeSampleItem() -> ReviewItem {
        ReviewItem(
            imageData: Data(),
            title: "测试错题",
            subject: .math,
            grade: .grade10,
            difficulty: .medium,
            errorType: .concept
        )
    }
    
    // MARK: - Success Tests
    
    @Test("删除错题成功")
    func testDelete_success() async throws {
        // Given
        let (sut, repository) = makeSUT()
        let item = makeSampleItem()
        repository.items = [item]
        
        // When
        try await sut.execute(id: item.id)
        
        // Then
        #expect(repository.deleteCalled == true)
        #expect(repository.items.isEmpty)
    }
    
    @Test("删除不存在的错题抛出错误")
    func testDelete_notFound_throws() async {
        // Given
        let (sut, repository) = makeSUT()
        repository.items = []
        let nonExistentId = UUID()
        
        // When/Then
        await #expect(throws: Error.self) {
            try await sut.execute(id: nonExistentId)
        }
    }
    
    // MARK: - Batch Delete Tests
    
    @Test("批量删除多个错题")
    func testDeleteBatch_success() async throws {
        // Given
        let (sut, repository) = makeSUT()
        let items = [makeSampleItem(), makeSampleItem(), makeSampleItem()]
        repository.items = items
        let idsToDelete = items.prefix(2).map { $0.id }
        
        // When
        try await sut.executeBatch(ids: Array(idsToDelete))
        
        // Then
        #expect(repository.items.count == 1)
    }
    
    @Test("批量删除空数组不执行操作")
    func testDeleteBatch_emptyArray_noOp() async throws {
        // Given
        let (sut, repository) = makeSUT()
        repository.items = [makeSampleItem()]
        
        // When
        try await sut.executeBatch(ids: [])
        
        // Then
        #expect(repository.items.count == 1)
        #expect(repository.deleteCalled == false)
    }
}
