//
//  ReviewItemRepository.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import Foundation
import SwiftData

// MARK: - ReviewItemRepository

/// 错题仓库实现
///
/// 基于 SwiftData 的具体存储实现。
///
/// ## 职责
///
/// - 封装 SwiftData 的 `ModelContext` 操作
/// - 实现 `ReviewItemRepositoryProtocol` 定义的所有方法
/// - 提供高效的查询和统计功能
///
/// ## 使用示例
///
/// ```swift
/// // 创建仓库实例
/// let repository = ReviewItemRepository(modelContext: modelContext)
///
/// // 获取需要复习的错题
/// let reviewItems = repository.fetchForReview()
///
/// // 保存新错题
/// let newItem = ReviewItem(title: "新错题", subject: .math)
/// try repository.save(newItem)
/// ```
///
/// - Note: 所有操作都在 `@MainActor` 上下文中执行
/// - Important: 确保 `modelContext` 的生命周期正确管理
@MainActor
final class ReviewItemRepository: ReviewItemRepositoryProtocol {

    // MARK: - Properties

    /// SwiftData 模型上下文
    private let modelContext: ModelContext

    // MARK: - Initialization

    /// 创建仓库实例
    ///
    /// - Parameter modelContext: SwiftData 模型上下文
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch All

    /// 获取所有错题
    ///
    /// 按创建时间降序排列（最新的在前）。
    func fetchAll() -> [ReviewItem] {
        let descriptor = FetchDescriptor<ReviewItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Filtered Fetch

    /// 根据条件筛选错题
    func fetch(subject: Subject?, mastery: MasteryLevel?) -> [ReviewItem] {
        var items = fetchAll()

        if let subject {
            items = items.filter { $0.subject == subject }
        }

        if let mastery {
            items = items.filter { $0.mastery == mastery }
        }

        return items
    }

    // MARK: - Review Fetch

    /// 获取需要复习的错题
    ///
    /// 排序规则：
    /// 1. 已逾期的优先（逾期天数多的在前）
    /// 2. 掌握程度低的优先
    /// 3. 复习次数少的优先
    func fetchForReview() -> [ReviewItem] {
        let now = Date()

        return fetchAll()
            .filter { $0.nextReviewDate <= now }
            .sorted { item1, item2 in
                // 已逾期的优先
                let overdue1 = item1.reviewInterval.overdueByDays
                let overdue2 = item2.reviewInterval.overdueByDays
                if overdue1 != overdue2 {
                    return overdue1 > overdue2
                }

                // 掌握程度低的优先
                if item1.masteryLevel != item2.masteryLevel {
                    return item1.masteryLevel < item2.masteryLevel
                }

                // 复习次数少的优先
                return item1.reviewCount < item2.reviewCount
            }
    }

    // MARK: - Search

    /// 搜索错题
    ///
    /// 在标题、笔记、知识点中搜索，不区分大小写。
    func search(query: String) -> [ReviewItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return fetchAll() }

        let lowercasedQuery = trimmedQuery.lowercased()
        return fetchAll().filter { item in
            item.title.lowercased().contains(lowercasedQuery) ||
            item.knowledgePoints.matches(trimmedQuery) ||
            item.note.lowercased().contains(lowercasedQuery) ||
            item.subject.displayName.contains(trimmedQuery) ||
            item.questionType.displayName.contains(trimmedQuery)
        }
    }

    // MARK: - Save Operations

    /// 保存错题
    ///
    /// 如果是新对象会插入，已存在则更新。
    func save(_ item: ReviewItem) throws {
        modelContext.insert(item)
        try modelContext.save()
    }

    // MARK: - Delete Operations

    /// 删除错题
    func delete(_ item: ReviewItem) throws {
        modelContext.delete(item)
        try modelContext.save()
    }

    /// 批量删除错题
    func delete(_ items: [ReviewItem]) throws {
        for item in items {
            modelContext.delete(item)
        }
        try modelContext.save()
    }

    /// 删除所有错题
    ///
    /// - Warning: 此操作不可逆
    func deleteAll() throws {
        let items = fetchAll()
        for item in items {
            modelContext.delete(item)
        }
        try modelContext.save()
    }

    // MARK: - Statistics

    /// 获取统计数据
    func statistics() -> ReviewStatistics {
        ReviewStatistics(from: fetchAll())
    }
}

// MARK: - ReviewItemRepository Convenience Methods

extension ReviewItemRepository {

    /// 获取指定 ID 的错题
    ///
    /// - Parameter id: 错题 ID
    /// - Returns: 匹配的错题，如果不存在返回 `nil`
    func fetch(byId id: UUID) -> ReviewItem? {
        fetchAll().first { $0.id == id }
    }

    /// 获取最近添加的错题
    ///
    /// - Parameter limit: 返回数量限制
    /// - Returns: 最近添加的错题列表
    func fetchRecent(limit: Int = 10) -> [ReviewItem] {
        Array(fetchAll().prefix(limit))
    }

    /// 获取指定学科的错题
    ///
    /// - Parameter subject: 学科
    /// - Returns: 该学科的所有错题
    func fetch(subject: Subject) -> [ReviewItem] {
        fetch(subject: subject, mastery: nil)
    }

    /// 获取指定难度的错题
    ///
    /// - Parameter difficulty: 难度等级
    /// - Returns: 该难度的所有错题
    func fetch(difficulty: Difficulty) -> [ReviewItem] {
        fetchAll().filter { $0.difficulty == difficulty }
    }

    /// 获取指定来源的错题
    ///
    /// - Parameter source: 题目来源
    /// - Returns: 该来源的所有错题
    func fetch(source: Source) -> [ReviewItem] {
        fetchAll().filter { $0.source == source }
    }

    /// 获取高优先级复习项
    ///
    /// 逾期或今天需要复习的错题。
    ///
    /// - Parameter limit: 返回数量限制
    /// - Returns: 高优先级错题列表
    func fetchHighPriority(limit: Int = 20) -> [ReviewItem] {
        Array(fetchForReview().filter { $0.reviewInterval.isUrgent }.prefix(limit))
    }

    /// 判断是否存在指定 ID 的错题
    ///
    /// - Parameter id: 错题 ID
    /// - Returns: 是否存在
    func exists(id: UUID) -> Bool {
        fetch(byId: id) != nil
    }
}
