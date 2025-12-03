//
//  MockReviewItemProvider.swift
//  NotBadTests
//
//  Created for NotBad K12 错题本
//  Phase 2: Data Layer Abstraction - Mock Implementation
//

import Foundation
@testable import NotBad

// MARK: - MockReviewItemProvider

/// Mock 数据提供者
///
/// 用于单元测试的 `ReviewItemDataProviding` Mock 实现。
///
/// ## 功能特性
///
/// - 可配置的错题数据
/// - 调用追踪（验证方法是否被调用）
/// - 可配置的错误抛出
/// - 支持异步操作模拟
///
/// ## 使用示例
///
/// ```swift
/// @Test("筛选逻辑正确")
/// @MainActor
/// func filterLogic() {
///     let mockProvider = MockReviewItemProvider()
///     mockProvider.items = [
///         ReviewItem.mock(subject: .math),
///         ReviewItem.mock(subject: .physics)
///     ]
///
///     let viewModel = LibraryViewModel(dataProvider: mockProvider)
///     viewModel.selectedSubject = .math
///
///     #expect(viewModel.filteredItems.count == 1)
/// }
/// ```
@MainActor
@Observable
public final class MockReviewItemProvider: ReviewItemDataProviding {

    // MARK: - Observable Properties

    /// 错题数据（可直接设置用于测试）
    public var items: [ReviewItem] = []

    /// 是否正在加载
    public var isLoading = false

    /// 最后刷新时间
    public var lastRefreshDate: Date?

    // MARK: - Call Tracking

    /// refresh() 调用次数
    public var refreshCallCount = 0

    /// save(_:) 调用次数
    public var saveCallCount = 0

    /// delete(_:) 调用次数
    public var deleteCallCount = 0

    /// fetchForReview() 调用次数
    public var fetchForReviewCallCount = 0

    /// search(query:) 调用次数
    public var searchCallCount = 0

    /// 最后一次搜索的关键词
    public var lastSearchQuery: String?

    /// 最后一次保存的错题
    public var lastSavedItem: ReviewItem?

    /// 最后一次删除的错题
    public var lastDeletedItem: ReviewItem?

    // MARK: - Error Simulation

    /// 是否在 save 时抛出错误
    public var shouldThrowOnSave = false

    /// 是否在 delete 时抛出错误
    public var shouldThrowOnDelete = false

    /// 自定义错误
    public var customError: Error?

    // MARK: - Configurable Behaviors

    /// 自定义 fetchForReview 返回值
    public var reviewItems: [ReviewItem]?

    /// 自定义 search 返回值
    public var searchResults: [ReviewItem]?

    /// 自定义统计数据
    public var customStatistics: ReviewStatistics?

    // MARK: - Initialization

    /// 创建 Mock 实例
    ///
    /// - Parameter items: 初始错题数据
    public init(items: [ReviewItem] = []) {
        self.items = items
    }

    // MARK: - Data Operations

    /// 刷新数据
    public func refresh() {
        refreshCallCount += 1
        lastRefreshDate = Date()
    }

    /// 保存错题
    public func save(_ item: ReviewItem) throws {
        saveCallCount += 1
        lastSavedItem = item

        if shouldThrowOnSave {
            throw customError ?? MockError.saveFailed
        }

        // 如果 items 中已存在相同 ID 的项，更新它；否则添加新项
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        } else {
            items.insert(item, at: 0)
        }
    }

    /// 删除错题
    public func delete(_ item: ReviewItem) throws {
        deleteCallCount += 1
        lastDeletedItem = item

        if shouldThrowOnDelete {
            throw customError ?? MockError.deleteFailed
        }

        items.removeAll { $0.id == item.id }
    }

    // MARK: - Query Operations

    /// 获取需要复习的错题
    public func fetchForReview() -> [ReviewItem] {
        fetchForReviewCallCount += 1

        if let reviewItems {
            return reviewItems
        }

        let now = Date()
        return items
            .filter { $0.nextReviewDate <= now }
            .sorted { $0.masteryLevel < $1.masteryLevel }
    }

    /// 搜索错题
    public func search(query: String) -> [ReviewItem] {
        searchCallCount += 1
        lastSearchQuery = query

        if let searchResults {
            return searchResults
        }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return items }

        let lowercasedQuery = trimmedQuery.lowercased()
        return items.filter { item in
            item.title.lowercased().contains(lowercasedQuery) ||
            item.note.lowercased().contains(lowercasedQuery)
        }
    }

    /// 获取统计数据
    public func statistics() -> ReviewStatistics {
        if let customStatistics {
            return customStatistics
        }
        return ReviewStatistics(from: items)
    }

    // MARK: - Test Helpers

    /// 重置所有调用追踪
    public func resetCallTracking() {
        refreshCallCount = 0
        saveCallCount = 0
        deleteCallCount = 0
        fetchForReviewCallCount = 0
        searchCallCount = 0
        lastSearchQuery = nil
        lastSavedItem = nil
        lastDeletedItem = nil
    }

    /// 重置所有配置
    public func resetConfiguration() {
        shouldThrowOnSave = false
        shouldThrowOnDelete = false
        customError = nil
        reviewItems = nil
        searchResults = nil
        customStatistics = nil
    }

    /// 完全重置
    public func reset() {
        items = []
        isLoading = false
        lastRefreshDate = nil
        resetCallTracking()
        resetConfiguration()
    }
}

// Note: MockError is defined in MockReviewItemRepository.swift
