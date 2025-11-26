//
//  ReviewItemRepositoryProtocol.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import Foundation

// MARK: - ReviewItemRepositoryProtocol

/// 错题仓库协议
///
/// 定义错题数据的 CRUD 操作接口。
///
/// ## 设计原则
///
/// - **依赖倒置**：上层模块依赖此抽象接口，而非具体实现
/// - **可测试性**：可以注入 Mock 实现进行单元测试
/// - **可替换性**：未来可以替换底层存储方案（SwiftData → Core Data → SQLite）
///
/// ## 使用示例
///
/// ```swift
/// // 依赖注入
/// class ReviewViewModel {
///     private let repository: ReviewItemRepositoryProtocol
///
///     init(repository: ReviewItemRepositoryProtocol) {
///         self.repository = repository
///     }
///
///     func loadItems() {
///         let items = repository.fetchForReview()
///     }
/// }
/// ```
///
/// - Note: 所有方法都在 `@MainActor` 上下文中执行
/// - Important: 实现类需要处理 SwiftData 的并发限制
@MainActor
protocol ReviewItemRepositoryProtocol: AnyObject, Sendable {
    
    // MARK: - Fetch Operations
    
    /// 获取所有错题
    ///
    /// - Returns: 所有错题列表，按创建时间降序排列
    func fetchAll() -> [ReviewItem]
    
    /// 根据条件筛选错题
    ///
    /// 支持组合筛选，参数为 `nil` 时忽略该条件。
    ///
    /// - Parameters:
    ///   - subject: 学科筛选，`nil` 表示不限
    ///   - mastery: 掌握程度筛选，`nil` 表示不限
    /// - Returns: 符合条件的错题列表
    func fetch(subject: Subject?, mastery: MasteryLevel?) -> [ReviewItem]
    
    /// 获取需要复习的错题
    ///
    /// 返回 `nextReviewDate <= 当前时间` 的错题，按紧迫程度排序。
    ///
    /// - Returns: 需要复习的错题列表，越紧急的排在前面
    func fetchForReview() -> [ReviewItem]
    
    /// 获取指定学科需要复习的错题
    ///
    /// - Parameter subject: 学科
    /// - Returns: 该学科需要复习的错题列表
    func fetchForReview(subject: Subject) -> [ReviewItem]
    
    /// 获取今日需要复习的错题
    ///
    /// - Returns: 今日到期的错题列表
    func fetchDueToday() -> [ReviewItem]
    
    /// 获取本周需要复习的错题
    ///
    /// - Returns: 本周到期的错题列表
    func fetchDueThisWeek() -> [ReviewItem]
    
    /// 获取已逾期的错题
    ///
    /// - Returns: 已逾期的错题列表，按逾期天数降序排列
    func fetchOverdue() -> [ReviewItem]
    
    // MARK: - Search Operations
    
    /// 搜索错题
    ///
    /// 在标题、笔记、知识点中搜索关键词。
    ///
    /// - Parameter query: 搜索关键词
    /// - Returns: 匹配的错题列表
    func search(query: String) -> [ReviewItem]
    
    /// 按知识点搜索
    ///
    /// - Parameter knowledgePoint: 知识点关键词
    /// - Returns: 包含该知识点的错题列表
    func search(byKnowledgePoint knowledgePoint: String) -> [ReviewItem]
    
    // MARK: - CRUD Operations
    
    /// 保存错题
    ///
    /// 新增或更新错题记录。
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
    
    /// 删除所有错题
    ///
    /// - Warning: 此操作不可逆，请谨慎使用
    /// - Throws: 删除失败时抛出错误
    func deleteAll() throws
    
    // MARK: - Statistics
    
    /// 获取统计数据
    ///
    /// - Returns: 错题统计信息
    func statistics() -> ReviewStatistics
    
    /// 获取指定学科的统计数据
    ///
    /// - Parameter subject: 学科
    /// - Returns: 该学科的统计信息
    func statistics(for subject: Subject) -> ReviewStatistics
    
    // MARK: - Count Operations
    
    /// 获取错题总数
    ///
    /// - Returns: 错题总数
    func count() -> Int
    
    /// 获取需要复习的错题数量
    ///
    /// - Returns: 需要复习的数量
    func countForReview() -> Int
    
    /// 获取指定学科的错题数量
    ///
    /// - Parameter subject: 学科
    /// - Returns: 该学科的错题数量
    func count(for subject: Subject) -> Int
}

// MARK: - ReviewItemRepositoryProtocol Default Implementations

extension ReviewItemRepositoryProtocol {
    
    /// 获取指定学科需要复习的错题（默认实现）
    func fetchForReview(subject: Subject) -> [ReviewItem] {
        fetchForReview().filter { $0.subject == subject }
    }
    
    /// 获取今日需要复习的错题（默认实现）
    func fetchDueToday() -> [ReviewItem] {
        fetchForReview().filter { $0.reviewInterval.isDueToday }
    }
    
    /// 获取本周需要复习的错题（默认实现）
    func fetchDueThisWeek() -> [ReviewItem] {
        fetchAll().filter { $0.reviewInterval.isDueThisWeek }
    }
    
    /// 获取已逾期的错题（默认实现）
    func fetchOverdue() -> [ReviewItem] {
        fetchForReview()
            .filter { $0.isOverdue }
            .sorted { $0.reviewInterval.overdueByDays > $1.reviewInterval.overdueByDays }
    }
    
    /// 按知识点搜索（默认实现）
    func search(byKnowledgePoint knowledgePoint: String) -> [ReviewItem] {
        fetchAll().filter { $0.knowledgePoints.contains(knowledgePoint) }
    }
    
    /// 批量保存（默认实现）
    func save(_ items: [ReviewItem]) throws {
        for item in items {
            try save(item)
        }
    }
    
    /// 获取指定学科的统计数据（默认实现）
    func statistics(for subject: Subject) -> ReviewStatistics {
        let items = fetch(subject: subject, mastery: nil)
        return ReviewStatistics(from: items)
    }
    
    /// 获取错题总数（默认实现）
    func count() -> Int {
        fetchAll().count
    }
    
    /// 获取需要复习的错题数量（默认实现）
    func countForReview() -> Int {
        fetchForReview().count
    }
    
    /// 获取指定学科的错题数量（默认实现）
    func count(for subject: Subject) -> Int {
        fetch(subject: subject, mastery: nil).count
    }
}

// MARK: - ReviewStatistics

/// 错题统计数据
///
/// 包含错题的各维度统计信息。
///
/// ## 统计维度
///
/// - 总数与完成情况
/// - 掌握程度分布
/// - 学科分布
/// - 时间相关统计
struct ReviewStatistics: Sendable, Equatable {
    
    // MARK: - Count Statistics
    
    /// 错题总数
    let totalCount: Int
    
    /// 已掌握数量（掌握程度 >= good）
    let masteredCount: Int
    
    /// 本周新增数量
    let weeklyNewCount: Int
    
    /// 累计复习次数
    let totalReviewCount: Int
    
    /// 需要复习的数量
    let pendingReviewCount: Int
    
    /// 已逾期数量
    let overdueCount: Int
    
    // MARK: - Distribution Statistics
    
    /// 各掌握程度分布
    let masteryDistribution: [MasteryLevel: Int]
    
    /// 各学科分布
    let subjectDistribution: [Subject: Int]
    
    /// 各难度分布
    let difficultyDistribution: [Difficulty: Int]
    
    // MARK: - Computed Properties
    
    /// 掌握率（0.0 - 1.0）
    nonisolated var masteryRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(masteredCount) / Double(totalCount)
    }
    
    /// 掌握率百分比
    nonisolated var masteryPercentage: Int {
        Int(masteryRate * 100)
    }
    
    /// 完成率描述
    nonisolated var masteryDescription: String {
        "\(masteredCount)/\(totalCount) 已掌握 (\(masteryPercentage)%)"
    }
    
    /// 是否有待复习
    nonisolated var hasPendingReview: Bool {
        pendingReviewCount > 0
    }
    
    /// 是否有逾期
    nonisolated var hasOverdue: Bool {
        overdueCount > 0
    }
    
    /// 主要学科（错题最多的学科）
    nonisolated var primarySubject: Subject? {
        subjectDistribution.max(by: { $0.value < $1.value })?.key
    }
    
    /// 主要薄弱点（掌握程度最低的比例最高）
    nonisolated var weakestMastery: MasteryLevel? {
        masteryDistribution
            .filter { $0.key != .mastered && $0.key != .good }
            .max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - ReviewStatistics Initialization

extension ReviewStatistics {
    
    /// 空统计数据
    static let empty = ReviewStatistics(
        totalCount: 0,
        masteredCount: 0,
        weeklyNewCount: 0,
        totalReviewCount: 0,
        pendingReviewCount: 0,
        overdueCount: 0,
        masteryDistribution: [:],
        subjectDistribution: [:],
        difficultyDistribution: [:]
    )
    
    /// 从错题列表创建统计数据
    ///
    /// - Parameter items: 错题列表
    init(from items: [ReviewItem]) {
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        
        self.totalCount = items.count
        self.masteredCount = items.filter { $0.isMastered }.count
        self.weeklyNewCount = items.filter { $0.createdAt >= weekAgo }.count
        self.totalReviewCount = items.reduce(0) { $0 + $1.reviewCount }
        self.pendingReviewCount = items.filter { $0.needsReview }.count
        self.overdueCount = items.filter { $0.isOverdue }.count
        
        // 掌握程度分布
        var masteryDist: [MasteryLevel: Int] = [:]
        for level in MasteryLevel.allCases {
            masteryDist[level] = items.filter { $0.mastery == level }.count
        }
        self.masteryDistribution = masteryDist
        
        // 学科分布
        var subjectDist: [Subject: Int] = [:]
        for subject in Subject.allCases {
            let count = items.filter { $0.subject == subject }.count
            if count > 0 {
                subjectDist[subject] = count
            }
        }
        self.subjectDistribution = subjectDist
        
        // 难度分布
        var difficultyDist: [Difficulty: Int] = [:]
        for difficulty in Difficulty.allCases {
            difficultyDist[difficulty] = items.filter { $0.difficulty == difficulty }.count
        }
        self.difficultyDistribution = difficultyDist
    }
}
