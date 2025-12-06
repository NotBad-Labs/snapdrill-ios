//
//  GetStatisticsUseCaseTests.swift
//  NotBadTests
//
//  统计用例测试
//

import Testing
import Foundation
@testable import NotBad

// MARK: - GetStatisticsUseCaseTests

@Suite("GetStatisticsUseCase Tests")
@MainActor
struct GetStatisticsUseCaseTests {
    
    // MARK: - Test Fixtures
    
    private func makeSUT() -> (sut: GetStatisticsUseCase, repository: MockReviewItemRepository) {
        let repository = MockReviewItemRepository()
        let sut = GetStatisticsUseCase(repository: repository)
        return (sut, repository)
    }
    
    private func makeSampleItems() -> [ReviewItem] {
        let item1 = ReviewItem(
            imageData: Data(),
            title: "数学错题1",
            subject: .math,
            grade: .grade10,
            difficulty: .medium,
            errorType: .concept
        )
        item1.masteryLevel = MasteryLevel.mastered.rawValue
        
        let item2 = ReviewItem(
            imageData: Data(),
            title: "物理错题1",
            subject: .physics,
            grade: .grade10,
            difficulty: .hard,
            errorType: .calculation
        )
        item2.masteryLevel = MasteryLevel.partial.rawValue
        
        let item3 = ReviewItem(
            imageData: Data(),
            title: "数学错题2",
            subject: .math,
            grade: .grade11,
            difficulty: .easy,
            errorType: .careless
        )
        item3.masteryLevel = MasteryLevel.none.rawValue
        
        return [item1, item2, item3]
    }
    
    // MARK: - Overview Statistics Tests
    
    @Test("获取总览统计")
    func testExecuteOverview_returnsCorrectStats() async throws {
        // Given
        let (sut, repository) = makeSUT()
        repository.items = makeSampleItems()
        
        // When
        let result = await sut.executeOverview()
        
        // Then
        #expect(result.totalCount == 3)
    }
    
    @Test("空仓库返回零统计")
    func testExecuteOverview_emptyRepository_returnsZeroStats() async throws {
        // Given
        let (sut, repository) = makeSUT()
        repository.items = []
        
        // When
        let result = await sut.executeOverview()
        
        // Then
        #expect(result.totalCount == 0)
    }
    
    // MARK: - Subject Statistics Tests
    
    @Test("按科目统计")
    func testExecuteBySubject_returnsCorrectDistribution() async throws {
        // Given
        let (sut, repository) = makeSUT()
        repository.items = makeSampleItems()
        
        // When
        let result = await sut.executeBySubject()
        
        // Then
        #expect(result.count == 2)  // math 和 physics
        
        let mathStats = result.first { $0.subject == .math }
        #expect(mathStats?.totalCount == 2)
        
        let physicsStats = result.first { $0.subject == .physics }
        #expect(physicsStats?.totalCount == 1)
    }
    
    // MARK: - Mastery Distribution Tests
    
    @Test("掌握度分布统计")
    func testMasteryDistribution() async throws {
        // Given
        let (sut, repository) = makeSUT()
        repository.items = makeSampleItems()
        
        // When
        let result = await sut.executeOverview()
        
        // Then
        // 1 mastered, 1 partial, 1 none
        #expect(result.masteryDistribution[.mastered] == 1)
        #expect(result.masteryDistribution[.partial] == 1)
        #expect(result.masteryDistribution[.none] == 1)
    }
    
    // MARK: - Trend Statistics Tests
    
    @Test("获取趋势统计")
    func testExecuteTrend_returns7DaysTrend() async throws {
        // Given
        let (sut, repository) = makeSUT()
        repository.items = makeSampleItems()
        
        // When
        let result = await sut.executeTrend(days: 7)
        
        // Then
        #expect(result.count == 7)
    }
    
    // MARK: - Today Progress Tests
    
    @Test("获取今日进度")
    func testExecuteTodayProgress() async throws {
        // Given
        let (sut, repository) = makeSUT()
        repository.items = makeSampleItems()
        
        // When
        let result = await sut.executeTodayProgress()
        
        // Then
        #expect(result.targetCount >= 0)
        #expect(result.completedCount >= 0)
    }
}
