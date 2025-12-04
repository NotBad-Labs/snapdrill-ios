//
//  ReviewItemDataProviding.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//  Phase 2: Data Layer Abstraction
//

import Foundation

// MARK: - ReviewItemDataProviding

/// 错题数据提供协议
///
/// 为 View 层提供响应式数据访问的抽象接口，替代直接使用 `@Query`。
///
/// ## 设计目的
///
/// 1. **解耦 View 与 SwiftData**：View 不再直接依赖 `@Query`
/// 2. **提高可测试性**：可以注入 Mock 实现进行单元测试
/// 3. **统一数据访问**：所有数据访问通过此协议进行
///
/// ## 使用示例
///
/// ```swift
/// // 生产环境
/// let provider = SwiftDataReviewItemProvider(modelContext: context)
///
/// // 测试环境
/// let mockProvider = MockReviewItemProvider()
/// mockProvider.items = [ReviewItem.mock()]
///
/// // ViewModel 使用
/// let viewModel = LibraryViewModel(dataProvider: provider)
/// ```
///
/// ## 与 ReviewItemRepositoryProtocol 的区别
///
/// - `ReviewItemRepositoryProtocol`：面向领域层，提供 CRUD 操作
/// - `ReviewItemDataProviding`：面向展示层，提供响应式数据绑定
///
/// - Note: 实现类应为 `@Observable`，以支持 SwiftUI 自动更新
/// - Important: 所有方法都在 `@MainActor` 上下文中执行
@MainActor
protocol ReviewItemDataProviding: AnyObject, Sendable {

    // MARK: - Observable Properties

    /// 所有错题数据
    ///
    /// 实现类应将此属性标记为 `@Observable` 可观察属性，
    /// 以便 SwiftUI 视图能够自动响应数据变化。
    var items: [ReviewItem] { get }

    /// 是否正在加载数据
    var isLoading: Bool { get }

    /// 最后一次刷新时间
    var lastRefreshDate: Date? { get }

    // MARK: - Data Operations

    /// 刷新数据
    ///
    /// 从底层存储重新加载所有数据。
    /// 调用后 `items` 属性将更新为最新数据。
    func refresh()

    /// 保存错题
    ///
    /// - Parameter item: 要保存的错题
    /// - Throws: 保存失败时抛出错误
    func save(_ item: ReviewItem) throws

    /// 批量保存错题
    ///
    /// - Parameter items: 要保存的错题列表
    /// - Throws: 保存失败时抛出错误
    func save(_ items: [ReviewItem]) throws

    /// 删除错题
    ///
    /// - Parameter item: 要删除的错题
    /// - Throws: 删除失败时抛出错误
    func delete(_ item: ReviewItem) throws

    /// 批量删除错题
    ///
    /// - Parameter items: 要删除的错题列表
    /// - Throws: 删除失败时抛出错误
    func delete(_ items: [ReviewItem]) throws

    // MARK: - Query Operations

    /// 获取需要复习的错题
    ///
    /// - Returns: 需要复习的错题列表，按紧迫程度排序
    func fetchForReview() -> [ReviewItem]

    /// 获取今日需要复习的错题
    ///
    /// - Returns: 今日到期的错题列表
    func fetchDueToday() -> [ReviewItem]

    /// 获取指定学科的错题
    ///
    /// - Parameter subject: 学科
    /// - Returns: 该学科的所有错题
    func fetch(subject: Subject) -> [ReviewItem]

    /// 搜索错题
    ///
    /// - Parameter query: 搜索关键词
    /// - Returns: 匹配的错题列表
    func search(query: String) -> [ReviewItem]

    // MARK: - Statistics

    /// 获取统计数据
    ///
    /// - Returns: 错题统计信息
    func statistics() -> ReviewStatistics
}

// MARK: - ReviewItemDataProviding Default Implementations

extension ReviewItemDataProviding {

    /// 批量保存（默认实现）
    func save(_ items: [ReviewItem]) throws {
        for item in items {
            try save(item)
        }
    }

    /// 批量删除（默认实现）
    func delete(_ items: [ReviewItem]) throws {
        for item in items {
            try delete(item)
        }
    }

    /// 获取今日需要复习的错题（默认实现）
    func fetchDueToday() -> [ReviewItem] {
        fetchForReview().filter { $0.reviewInterval.isDueToday }
    }

    /// 获取指定学科的错题（默认实现）
    func fetch(subject: Subject) -> [ReviewItem] {
        items.filter { $0.subject == subject }
    }

    /// 搜索错题（默认实现）
    func search(query: String) -> [ReviewItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return items }

        let lowercasedQuery = trimmedQuery.lowercased()
        return items.filter { item in
            item.title.lowercased().contains(lowercasedQuery) ||
            item.knowledgePoints.matches(trimmedQuery) ||
            item.note.lowercased().contains(lowercasedQuery) ||
            item.subject.displayName.contains(trimmedQuery) ||
            item.reviewItemType.displayName.contains(trimmedQuery)
        }
    }

    /// 获取统计数据（默认实现）
    func statistics() -> ReviewStatistics {
        ReviewStatistics(from: items)
    }
}
