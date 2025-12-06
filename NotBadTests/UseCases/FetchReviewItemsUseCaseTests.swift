//
//  FetchReviewItemsUseCaseTests.swift
//  NotBadTests
//
//  Use Case 单元测试
//

import Testing
import Foundation
@testable import NotBad

// MARK: - FetchReviewItemsUseCaseTests

@Suite("FetchReviewItemsUseCase Tests")
@MainActor
struct FetchReviewItemsUseCaseTests {
    
    // MARK: - Test Fixtures
    
    private func makeSUT() -> (sut: FetchReviewItemsUseCase, repository: MockReviewItemRepository) {
        let repository = MockReviewItemRepository()
        let sut = FetchReviewItemsUseCase(repository: repository)
        return (sut, repository)
    }
    
    private func makeSampleItems() -> [ReviewItem] {
        [
            ReviewItem(
                imageData: Data(),
                title: "数学错题1",
                subject: .math,
                grade: .grade10,
                difficulty: .medium,
                errorType: .concept
            ),
            ReviewItem(
                imageData: Data(),
                title: "物理错题1",
                subject: .physics,
                grade: .grade10,
                difficulty: .hard,
                errorType: .calculation
            ),
            ReviewItem(
                imageData: Data(),
                title: "数学错题2",
                subject: .math,
                grade: .grade11,
                difficulty: .easy,
                errorType: .careless
            )
        ]
    }
    
    // MARK: - FetchAll Tests
    
    @Test("获取所有错题")
    func testFetchAll_returnsAllItems() async throws {
        // Given
        let (sut, repository) = makeSUT()
        repository.items = makeSampleItems()
        
        // When
        let result = try await sut.execute()
        
        // Then
        #expect(result.count == 3)
        #expect(repository.fetchAllCalled == true)
    }
    
    @Test("空仓库返回空数组")
    func testFetchAll_emptyRepository_returnsEmptyArray() async throws {
        // Given
        let (sut, repository) = makeSUT()
        repository.items = []
        
        // When
        let result = try await sut.execute()
        
        // Then
        #expect(result.isEmpty)
    }
    
    // MARK: - Filter Tests
    
    @Test("按科目过滤")
    func testFetch_filterBySubject() async throws {
        // Given
        let (sut, repository) = makeSUT()
        repository.items = makeSampleItems()
        let filter = ReviewItemFilter(subject: .math)
        
        // When
        let result = await sut.execute(filter: filter)
        
        // Then
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.subject == .math })
    }
    
    @Test("按年级过滤")
    func testFetch_filterByGrade() async throws {
        // Given
        let (sut, repository) = makeSUT()
        repository.items = makeSampleItems()
        let filter = ReviewItemFilter(grade: .grade10)
        
        // When
        let result = await sut.execute(filter: filter)
        
        // Then
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.grade == .grade10 })
    }
    
    @Test("按难度过滤")
    func testFetch_filterByDifficulty() async throws {
        // Given
        let (sut, repository) = makeSUT()
        repository.items = makeSampleItems()
        let filter = ReviewItemFilter(difficulty: .hard)
        
        // When
        let result = await sut.execute(filter: filter)
        
        // Then
        #expect(result.count == 1)
        #expect(result.first?.difficulty == .hard)
    }
    
    @Test("组合过滤条件")
    func testFetch_combinedFilters() async throws {
        // Given
        let (sut, repository) = makeSUT()
        repository.items = makeSampleItems()
        let filter = ReviewItemFilter(subject: .math, grade: .grade10)
        
        // When
        let result = await sut.execute(filter: filter)
        
        // Then
        #expect(result.count == 1)
        #expect(result.first?.title == "数学错题1")
    }
    
    // MARK: - Sorting Tests
    
    @Test("按创建时间降序排列")
    func testFetch_sortedByCreatedDateDescending() async throws {
        // Given
        let (sut, repository) = makeSUT()
        let items = makeSampleItems()
        repository.items = items
        let filter = ReviewItemFilter(sortBy: .createdAt, ascending: false)
        
        // When
        let result = await sut.execute(filter: filter)
        
        // Then
        #expect(result.count == 3)
        // 最新的在前面
        for i in 0..<(result.count - 1) {
            #expect(result[i].createdAt >= result[i + 1].createdAt)
        }
    }
}
