//
//  SwiftDataReviewItemProvider.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//  Phase 2: Data Layer Abstraction
//

import Foundation
import SwiftData
import Observation

// MARK: - SwiftDataReviewItemProvider

/// SwiftData 数据提供者实现
///
/// 基于 SwiftData 的 `ReviewItemDataProviding` 具体实现，
/// 为 View 层提供响应式的错题数据访问。
///
/// ## 功能特性
///
/// - 自动从 SwiftData 加载数据
/// - 支持手动刷新
/// - 支持增删改操作
/// - 提供统计信息
///
/// ## 使用示例
///
/// ```swift
/// // 创建实例
/// let provider = SwiftDataReviewItemProvider(modelContext: modelContext)
///
/// // 在 View 中使用
/// struct LibraryView: View {
///     @State private var provider: SwiftDataReviewItemProvider
///
///     var body: some View {
///         List(provider.items) { item in
///             Text(item.title)
///         }
///         .onAppear {
///             provider.refresh()
///         }
///     }
/// }
/// ```
///
/// ## 线程安全
///
/// 所有操作都在 `@MainActor` 上下文中执行，确保与 SwiftUI 的线程一致性。
///
/// - Note: 实例应该在应用启动时创建，并通过环境注入到 View 层
@MainActor
@Observable
final class SwiftDataReviewItemProvider: ReviewItemDataProviding {

    // MARK: - Observable Properties

    /// 所有错题数据（按创建时间倒序）
    private(set) var items: [ReviewItem] = []

    /// 是否正在加载数据
    private(set) var isLoading = false

    /// 最后一次刷新时间
    private(set) var lastRefreshDate: Date?

    // MARK: - Private Properties

    /// SwiftData 模型上下文
    private let modelContext: ModelContext

    /// 底层仓库（复用现有逻辑）
    private let repository: ReviewItemRepository

    // MARK: - Initialization

    /// 创建数据提供者实例
    ///
    /// - Parameter modelContext: SwiftData 模型上下文
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.repository = ReviewItemRepository(modelContext: modelContext)

        // 初始加载数据
        refresh()
    }

    // MARK: - Data Operations

    /// 刷新数据
    ///
    /// 从 SwiftData 重新加载所有错题数据。
    func refresh() {
        isLoading = true
        defer {
            isLoading = false
            lastRefreshDate = Date()
        }

        items = repository.fetchAll()
    }

    /// 保存错题
    ///
    /// - Parameter item: 要保存的错题
    /// - Throws: 保存失败时抛出错误
    func save(_ item: ReviewItem) throws {
        try repository.save(item)
        refresh()
    }

    /// 删除错题
    ///
    /// - Parameter item: 要删除的错题
    /// - Throws: 删除失败时抛出错误
    func delete(_ item: ReviewItem) throws {
        try repository.delete(item)
        refresh()
    }

    // MARK: - Query Operations

    /// 获取需要复习的错题
    ///
    /// - Returns: 需要复习的错题列表，按紧迫程度排序
    func fetchForReview() -> [ReviewItem] {
        repository.fetchForReview()
    }

    /// 搜索错题
    ///
    /// - Parameter query: 搜索关键词
    /// - Returns: 匹配的错题列表
    func search(query: String) -> [ReviewItem] {
        repository.search(query: query)
    }

    // MARK: - Statistics

    /// 获取统计数据
    ///
    /// - Returns: 错题统计信息
    func statistics() -> ReviewStatistics {
        repository.statistics()
    }
}

// MARK: - SwiftDataReviewItemProvider Convenience Methods

extension SwiftDataReviewItemProvider {

    /// 获取指定 ID 的错题
    ///
    /// - Parameter id: 错题 ID
    /// - Returns: 匹配的错题，如果不存在返回 `nil`
    func fetch(byId id: UUID) -> ReviewItem? {
        items.first { $0.id == id }
    }

    /// 获取最近添加的错题
    ///
    /// - Parameter limit: 返回数量限制
    /// - Returns: 最近添加的错题列表
    func fetchRecent(limit: Int = 10) -> [ReviewItem] {
        Array(items.prefix(limit))
    }

    /// 获取高优先级复习项
    ///
    /// - Parameter limit: 返回数量限制
    /// - Returns: 高优先级错题列表
    func fetchHighPriority(limit: Int = 20) -> [ReviewItem] {
        Array(fetchForReview().filter { $0.reviewInterval.isUrgent }.prefix(limit))
    }

    /// 获取已逾期的错题
    ///
    /// - Returns: 已逾期的错题列表
    func fetchOverdue() -> [ReviewItem] {
        fetchForReview()
            .filter { $0.isOverdue }
            .sorted { $0.reviewInterval.overdueByDays > $1.reviewInterval.overdueByDays }
    }

    /// 获取本周需要复习的错题
    ///
    /// - Returns: 本周到期的错题列表
    func fetchDueThisWeek() -> [ReviewItem] {
        items.filter { $0.reviewInterval.isDueThisWeek }
    }
}
