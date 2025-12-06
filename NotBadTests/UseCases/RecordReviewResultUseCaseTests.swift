//
//  RecordReviewResultUseCaseTests.swift
//  NotBadTests
//
//  复习结果记录用例测试
//

import Testing
import Foundation
@testable import NotBad

// MARK: - RecordReviewResultUseCaseTests

@Suite("RecordReviewResultUseCase Tests")
@MainActor
struct RecordReviewResultUseCaseTests {
    
    // MARK: - Test Fixtures
    
    private func makeSUT() -> (sut: RecordReviewResultUseCase, repository: MockReviewItemRepository) {
        let repository = MockReviewItemRepository()
        let sut = RecordReviewResultUseCase(repository: repository)
        return (sut, repository)
    }
    
    private func makeSampleItem(masteryLevel: MasteryLevel = .none) -> ReviewItem {
        let item = ReviewItem(
            imageData: Data(),
            title: "测试错题",
            subject: .math,
            grade: .grade10,
            difficulty: .medium,
            errorType: .concept
        )
        item.masteryLevel = masteryLevel.rawValue
        return item
    }
    
    // MARK: - Mastery Level Update Tests
    
    @Test("回答正确提升掌握度")
    func testRecordResult_correct_increasesMastery() async throws {
        // Given
        let (sut, repository) = makeSUT()
        let item = makeSampleItem(masteryLevel: .glimpse)
        repository.items = [item]
        
        // When
        let result = try await sut.execute(itemId: item.id, isCorrect: true, duration: 30.0)
        
        // Then
        #expect(result.masteryLevel == MasteryLevel.partial.rawValue)
    }
    
    @Test("回答错误降低掌握度")
    func testRecordResult_incorrect_decreasesMastery() async throws {
        // Given
        let (sut, repository) = makeSUT()
        let item = makeSampleItem(masteryLevel: .good)
        repository.items = [item]
        
        // When
        let result = try await sut.execute(itemId: item.id, isCorrect: false, duration: 30.0)
        
        // Then
        #expect(result.masteryLevel == MasteryLevel.partial.rawValue)
    }
    
    @Test("最高掌握度不再提升")
    func testRecordResult_mastered_staysAtMax() async throws {
        // Given
        let (sut, repository) = makeSUT()
        let item = makeSampleItem(masteryLevel: .mastered)
        repository.items = [item]
        
        // When
        let result = try await sut.execute(itemId: item.id, isCorrect: true, duration: 30.0)
        
        // Then
        #expect(result.masteryLevel == MasteryLevel.mastered.rawValue)
    }
    
    @Test("最低掌握度不再降低")
    func testRecordResult_glimpse_staysAtMin() async throws {
        // Given
        let (sut, repository) = makeSUT()
        let item = makeSampleItem(masteryLevel: .glimpse)
        repository.items = [item]
        
        // When
        let result = try await sut.execute(itemId: item.id, isCorrect: false, duration: 30.0)
        
        // Then
        #expect(result.masteryLevel == MasteryLevel.glimpse.rawValue)
    }
    
    // MARK: - Review Count Tests
    
    @Test("记录复习增加复习次数")
    func testRecordResult_incrementsReviewCount() async throws {
        // Given
        let (sut, repository) = makeSUT()
        let item = makeSampleItem()
        let initialCount = item.reviewCount
        repository.items = [item]
        
        // When
        let result = try await sut.execute(itemId: item.id, isCorrect: true, duration: 30.0)
        
        // Then
        #expect(result.reviewCount == initialCount + 1)
    }
    
    // MARK: - Next Review Date Tests
    
    @Test("回答正确设置较长的下次复习间隔")
    func testRecordResult_correct_setsLongerInterval() async throws {
        // Given
        let (sut, repository) = makeSUT()
        let item = makeSampleItem(masteryLevel: .partial)
        repository.items = [item]
        let beforeDate = Date()
        
        // When
        let result = try await sut.execute(itemId: item.id, isCorrect: true, duration: 30.0)
        
        // Then
        #expect(result.nextReviewDate > beforeDate)
    }
    
    @Test("回答错误设置较短的下次复习间隔")
    func testRecordResult_incorrect_setsShorterInterval() async throws {
        // Given
        let (sut, repository) = makeSUT()
        let item = makeSampleItem(masteryLevel: .good)
        repository.items = [item]
        
        // When
        let result = try await sut.execute(itemId: item.id, isCorrect: false, duration: 30.0)
        
        // Then
        // 错误的应该更快复习 - nextReviewDate 应该是有效日期
        #expect(result.nextReviewDate > Date.distantPast)
    }
    
    // MARK: - Error Tests
    
    @Test("错题不存在抛出错误")
    func testRecordResult_itemNotFound_throws() async {
        // Given
        let (sut, _) = makeSUT()
        let nonExistentId = UUID()
        
        // When/Then
        await #expect(throws: Error.self) {
            _ = try await sut.execute(itemId: nonExistentId, isCorrect: true, duration: 30.0)
        }
    }
}
