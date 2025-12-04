//
//  MockDataProvider.swift
//  NotBadTests
//
//  数据提供者的 Mock 实现
//

import Foundation
@testable import NotBad

// MARK: - MockDataProvider

/// 数据提供者的 Mock 实现
///
/// 用于单元测试 ViewModel，提供可控的数据源。
///
/// ## 使用示例
///
/// ```swift
/// @Test("ViewModel 加载数据")
/// @MainActor
/// func testLoadData() {
///     let mock = MockDataProvider()
///     mock.items = [ReviewItem.mock()]
///     
///     let viewModel = LibraryViewModel(dataProvider: mock)
///     
///     #expect(viewModel.items.count == 1)
/// }
/// ```
@MainActor
@Observable
final class MockDataProvider {
    
    // MARK: - Data
    
    /// 模拟的错题数据
    var items: [ReviewItem] = []
    
    /// 是否正在加载
    var isLoading = false
    
    // MARK: - Call Tracking
    
    /// refresh 被调用的次数
    var refreshCallCount = 0
    
    /// save 被调用的次数
    var saveCallCount = 0
    
    /// delete 被调用的次数
    var deleteCallCount = 0
    
    /// 最后保存的错题
    var lastSavedItem: ReviewItem?
    
    /// 最后删除的错题
    var lastDeletedItem: ReviewItem?
    
    // MARK: - Error Simulation
    
    /// 是否模拟保存错误
    var shouldThrowOnSave = false
    
    /// 是否模拟删除错误
    var shouldThrowOnDelete = false
    
    // MARK: - Methods
    
    /// 刷新数据
    func refresh() {
        refreshCallCount += 1
        // Mock 实现不需要实际刷新
    }
    
    /// 保存错题
    func save(_ item: ReviewItem) throws {
        saveCallCount += 1
        lastSavedItem = item
        
        if shouldThrowOnSave {
            throw MockError.saveFailed
        }
        
        if !items.contains(where: { $0.id == item.id }) {
            items.append(item)
        }
    }
    
    /// 删除错题
    func delete(_ item: ReviewItem) throws {
        deleteCallCount += 1
        lastDeletedItem = item
        
        if shouldThrowOnDelete {
            throw MockError.deleteFailed
        }
        
        items.removeAll { $0.id == item.id }
    }
    
    /// 获取需要复习的错题
    func fetchForReview() -> [ReviewItem] {
        return items.filter { $0.needsReview }
    }
    
    // MARK: - Reset
    
    /// 重置所有状态
    func reset() {
        items = []
        isLoading = false
        refreshCallCount = 0
        saveCallCount = 0
        deleteCallCount = 0
        lastSavedItem = nil
        lastDeletedItem = nil
        shouldThrowOnSave = false
        shouldThrowOnDelete = false
    }
}

// MARK: - ReviewItem Mock Extension

extension ReviewItem {
    /// 创建用于测试的 Mock ReviewItem
    ///
    /// - Parameters:
    ///   - title: 标题，默认 "测试错题"
    ///   - subject: 学科，默认 .math
    ///   - mastery: 掌握程度，默认 .partial
    ///   - difficulty: 难度，默认 .medium
    /// - Returns: 配置好的 ReviewItem
    static func mock(
        title: String = "测试错题",
        subject: Subject = .math,
        mastery: MasteryLevel = .partial,
        difficulty: Difficulty = .medium,
        needsReview: Bool = false
    ) -> ReviewItem {
        let reviewItem = ReviewItem(
            title: title,
            mastery: mastery,
            subject: subject,
            difficulty: difficulty,
            source: .homework
        )
        
        if needsReview {
            reviewItem.nextReviewDate = Date()
        } else {
            reviewItem.nextReviewDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        }
        
        return reviewItem
    }
}
