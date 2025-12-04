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
    ///
    /// 使用 SwiftData Predicate 进行数据库级查询。
    ///
    /// - Parameters:
    ///   - subject: 学科筛选，为 nil 时不筛选
    ///   - mastery: 掌握程度筛选，为 nil 时不筛选
    ///   - limit: 返回数量限制，默认 200
    /// - Returns: 筛选后的错题列表
    func fetch(subject: Subject?, mastery: MasteryLevel?, limit: Int = 200) -> [ReviewItem] {
        // 根据不同的筛选条件构建 Predicate
        var descriptor: FetchDescriptor<ReviewItem>
        
        if let subject, let mastery {
            let subjectValue = subject.rawValue
            let masteryValue = mastery.rawValue
            let predicate = #Predicate<ReviewItem> { item in
                item.subjectRaw == subjectValue && item.masteryLevel == masteryValue
            }
            descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\ReviewItem.createdAt, order: .reverse)])
        } else if let subject {
            let subjectValue = subject.rawValue
            let predicate = #Predicate<ReviewItem> { item in
                item.subjectRaw == subjectValue
            }
            descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\ReviewItem.createdAt, order: .reverse)])
        } else if let mastery {
            let masteryValue = mastery.rawValue
            let predicate = #Predicate<ReviewItem> { item in
                item.masteryLevel == masteryValue
            }
            descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\ReviewItem.createdAt, order: .reverse)])
        } else {
            descriptor = FetchDescriptor(sortBy: [SortDescriptor(\ReviewItem.createdAt, order: .reverse)])
        }
        
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Review Fetch

    /// 获取需要复习的错题
    ///
    /// 使用 SwiftData Predicate 进行数据库级查询。
    ///
    /// 排序规则：
    /// 1. 已逾期的优先（逾期天数多的在前）
    /// 2. 掌握程度低的优先
    /// 3. 复习次数少的优先
    ///
    /// - Parameter limit: 返回数量限制，默认 100
    /// - Returns: 需要复习的错题列表
    func fetchForReview(limit: Int = 100) -> [ReviewItem] {
        let now = Date()
        
        // 使用 Predicate 查询到期需要复习的项目
        let predicate = #Predicate<ReviewItem> { item in
            item.nextReviewDate <= now
        }
        
        // 按复习日期升序（最早到期的在前），然后按掌握程度升序
        var descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\ReviewItem.nextReviewDate, order: .forward),
                SortDescriptor(\ReviewItem.masteryLevel, order: .forward),
                SortDescriptor(\ReviewItem.reviewCount, order: .forward)
            ]
        )
        descriptor.fetchLimit = limit
        
        let items = (try? modelContext.fetch(descriptor)) ?? []
        
        // 进一步按逾期天数排序（需要计算属性，在内存中处理）
        return items.sorted { item1, item2 in
            let overdue1 = item1.reviewInterval.overdueByDays
            let overdue2 = item2.reviewInterval.overdueByDays
            if overdue1 != overdue2 {
                return overdue1 > overdue2
            }
            if item1.masteryLevel != item2.masteryLevel {
                return item1.masteryLevel < item2.masteryLevel
            }
            return item1.reviewCount < item2.reviewCount
        }
    }

    // MARK: - Search

    /// 搜索错题
    ///
    /// 使用 SwiftData Predicate 进行数据库级搜索，避免内存遍历。
    /// 在标题、笔记、知识点中搜索，不区分大小写。
    ///
    /// - Parameter query: 搜索关键词
    /// - Parameter limit: 最大返回数量，默认 100
    /// - Returns: 匹配的错题列表
    func search(query: String, limit: Int = 100) -> [ReviewItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 空查询返回最近记录，而不是全量
        guard !trimmedQuery.isEmpty else {
            return fetchRecent(limit: limit)
        }

        // 使用 SwiftData Predicate 进行数据库级搜索
        let predicate = #Predicate<ReviewItem> { item in
            item.title.localizedStandardContains(trimmedQuery) ||
            item.note.localizedStandardContains(trimmedQuery) ||
            item.knowledgePointsRaw.localizedStandardContains(trimmedQuery) ||
            item.subjectRaw.localizedStandardContains(trimmedQuery)
        }
        
        var descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\ReviewItem.createdAt, order: .reverse)])
        descriptor.fetchLimit = limit
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Save Operations

    /// 保存错题
    ///
    /// 如果是新对象会插入，已存在则更新。
    /// 具备幂等性，重复调用不会重复插入。
    func save(_ item: ReviewItem) throws {
        // 只有新对象才需要 insert
        if item.modelContext == nil {
            modelContext.insert(item)
        }
        try modelContext.save()
    }

    // MARK: - Delete Operations

    /// 删除错题
    ///
    /// - Parameter item: 要删除的错题
    /// - Throws: 删除失败时抛出错误
    /// - Note: 安全处理已删除或僵尸对象
    func delete(_ item: ReviewItem) throws {
        // 检查 item 是否已被删除或不在 context 中
        guard !item.isDeleted, let context = item.modelContext else {
            // item 已被删除或不在任何 context 中，跳过
            return
        }
        context.delete(item)
        try context.save()
    }

    /// 批量删除错题
    ///
    /// - Parameter items: 要删除的错题列表
    /// - Returns: 实际删除的数量
    /// - Throws: 删除失败时抛出错误
    @discardableResult
    func delete(_ items: [ReviewItem]) throws -> Int {
        var deletedCount = 0
        for item in items {
            if item.modelContext != nil {
                modelContext.delete(item)
                deletedCount += 1
            }
        }
        if deletedCount > 0 {
            try modelContext.save()
        }
        return deletedCount
    }

    /// 删除所有错题
    ///
    /// - Returns: 删除的错题数量
    /// - Warning: 此操作不可逆
    @discardableResult
    func deleteAll() throws -> Int {
        let items = fetchAll()
        let count = items.count
        
        guard count > 0 else { return 0 }
        
        for item in items {
            modelContext.delete(item)
        }
        try modelContext.save()
        
        return count
    }

    // MARK: - Statistics

    /// 获取完整统计数据
    ///
    /// ⚠️ 此方法会加载所有数据计算统计信息，适合在后台调用或数据量较小时使用。
    /// 对于仅需要计数的场景，请使用 `quickStatistics()` 获取轻量级统计。
    ///
    /// - Returns: 完整统计信息
    func statistics() -> ReviewStatistics {
        ReviewStatistics(from: fetchAll())
    }
    
    /// 获取轻量级统计数据
    ///
    /// 使用 fetchCount 进行高效计数，避免加载全部实体。
    /// 适合首页等需要快速显示统计的场景。
    ///
    /// - Returns: 快速统计信息（总数、待复习数、掌握数）
    func quickStatistics() -> (total: Int, pendingReview: Int, mastered: Int) {
        let total = count()
        
        // 待复习数量
        let now = Date()
        let pendingPredicate = #Predicate<ReviewItem> { item in
            item.nextReviewDate <= now
        }
        let pendingDescriptor = FetchDescriptor(predicate: pendingPredicate)
        let pendingReview = (try? modelContext.fetchCount(pendingDescriptor)) ?? 0
        
        // 已掌握数量 (mastery >= 3, 即 .good 或 .mastered)
        let masteredPredicate = #Predicate<ReviewItem> { item in
            item.masteryLevel >= 3
        }
        let masteredDescriptor = FetchDescriptor(predicate: masteredPredicate)
        let mastered = (try? modelContext.fetchCount(masteredDescriptor)) ?? 0
        
        return (total, pendingReview, mastered)
    }
}

// MARK: - ReviewItemRepository Convenience Methods

extension ReviewItemRepository {

    /// 获取指定 ID 的错题
    ///
    /// 使用 Predicate 进行数据库级查询，避免全量加载。
    ///
    /// - Parameter id: 错题 ID
    /// - Returns: 匹配的错题，如果不存在返回 `nil`
    func fetch(byId id: UUID) -> ReviewItem? {
        let predicate = #Predicate<ReviewItem> { item in
            item.id == id
        }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    /// 获取最近添加的错题
    ///
    /// 使用 fetchLimit 进行数据库级分页，避免全量加载。
    ///
    /// - Parameter limit: 返回数量限制，默认 50
    /// - Returns: 最近添加的错题列表
    func fetchRecent(limit: Int = 50) -> [ReviewItem] {
        var descriptor = FetchDescriptor<ReviewItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// 获取指定学科的错题
    ///
    /// - Parameter subject: 学科
    /// - Parameter limit: 返回数量限制，默认 100
    /// - Returns: 该学科的错题
    func fetch(subject: Subject, limit: Int = 100) -> [ReviewItem] {
        let subjectValue = subject.rawValue
        let predicate = #Predicate<ReviewItem> { item in
            item.subjectRaw == subjectValue
        }
        var descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\ReviewItem.createdAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// 获取指定难度的错题
    ///
    /// - Parameter difficulty: 难度等级
    /// - Parameter limit: 返回数量限制，默认 100
    /// - Returns: 该难度的错题
    func fetch(difficulty: Difficulty, limit: Int = 100) -> [ReviewItem] {
        let difficultyValue = difficulty.rawValue
        let predicate = #Predicate<ReviewItem> { item in
            item.difficultyRaw == difficultyValue
        }
        var descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\ReviewItem.createdAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// 获取指定来源的错题
    ///
    /// - Parameter source: 题目来源
    /// - Parameter limit: 返回数量限制，默认 100
    /// - Returns: 该来源的错题
    func fetch(source: Source, limit: Int = 100) -> [ReviewItem] {
        let sourceValue = source.rawValue
        let predicate = #Predicate<ReviewItem> { item in
            item.sourceRaw == sourceValue
        }
        var descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\ReviewItem.createdAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
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
    /// 使用 Predicate 进行数据库级查询。
    ///
    /// - Parameter id: 错题 ID
    /// - Returns: 是否存在
    func exists(id: UUID) -> Bool {
        fetch(byId: id) != nil
    }
    
    /// 获取错题总数
    ///
    /// 使用 fetchCount 进行高效计数，无需加载实体。
    ///
    /// - Returns: 错题总数
    func count() -> Int {
        let descriptor = FetchDescriptor<ReviewItem>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}
