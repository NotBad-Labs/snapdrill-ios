//
//  DashboardViewModel.swift
//  NotBad
//
//  Created by LIAOYIMING on 2025/6/5.
//  Phase 4: Use Case Integration
//

import SwiftUI
import SwiftData

// MARK: - DashboardViewModel

/// 数据看板 ViewModel
///
/// 负责处理首页仪表盘的数据统计和展示逻辑。
///
/// ## 职责
///
/// - 计算错题统计数据（总数、已掌握、本周新增等）
/// - 生成图表所需的数据结构
/// - 提供复习建议和学习洞察
///
/// ## 依赖注入（推荐方式）
///
/// ```swift
/// // 使用 DependencyFactory
/// let factory = dependencies.factory
/// let viewModel = factory.makeDashboardViewModel()
/// await viewModel.loadData()
/// ```
@MainActor
@Observable
final class DashboardViewModel {

    // MARK: - Dependencies (Use Cases)

    /// 获取错题用例
    private var fetchItemsUseCase: FetchReviewItemsUseCaseProtocol?
    
    /// 统计用例
    private var statisticsUseCase: GetStatisticsUseCaseProtocol?
    
    // MARK: - Data State
    
    /// 从 Use Case 加载的数据
    private(set) var loadedItems: [ReviewItem] = []
    
    /// 数据是否正在加载
    private(set) var isLoading = false

    // MARK: - State

    /// 选中的时间范围
    var selectedTimeRange: TimeRange = .week

    /// 选中的学科（用于筛选）
    var selectedSubject: Subject?

    // MARK: - Initialization

    /// 默认初始化
    init() {}
    
    /// Use Case 依赖注入初始化（推荐）
    ///
    /// - Parameters:
    ///   - fetchItemsUseCase: 获取错题用例
    ///   - statisticsUseCase: 统计用例
    init(
        fetchItemsUseCase: FetchReviewItemsUseCaseProtocol,
        statisticsUseCase: GetStatisticsUseCaseProtocol
    ) {
        self.fetchItemsUseCase = fetchItemsUseCase
        self.statisticsUseCase = statisticsUseCase
    }
    
    // MARK: - Data Loading
    
    /// 加载数据（使用 Use Case）
    ///
    /// - Parameter forceRefresh: 强制刷新，忽略缓存
    func loadData(forceRefresh: Bool = false) async {
        guard let fetchItemsUseCase else { return }
        
        // 如果已有数据且不强制刷新，跳过加载
        guard forceRefresh || loadedItems.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        loadedItems = await fetchItemsUseCase.execute()
    }
    
    /// 刷新数据（强制重新加载）
    func refresh() async {
        await loadData(forceRefresh: true)
    }

    // MARK: - Data Access

    /// 获取所有错题
    var items: [ReviewItem] {
        loadedItems
    }

    // MARK: - Private Helpers

    /// 根据筛选条件过滤错题
    private func filterItems(_ items: [ReviewItem]) -> [ReviewItem] {
        var filtered = items

        // 按学科筛选
        if let subject = selectedSubject {
            filtered = filtered.filter { $0.subject == subject }
        }

        // 按时间范围筛选
        if let startDate = selectedTimeRange.startDate {
            filtered = filtered.filter { $0.createdAt >= startDate }
        }

        return filtered
    }
}

// MARK: - Statistics

extension DashboardViewModel {
    /// 计算综合统计数据
    ///
    /// - Parameter items: 错题列表
    /// - Returns: 统计数据结构
    func computeStatistics(from items: [ReviewItem]) -> DashboardStatistics {
        let filteredItems = filterItems(items)

        return DashboardStatistics(
            totalCount: filteredItems.count,
            masteredCount: masteredCount(from: filteredItems),
            weeklyNewCount: weeklyNewCount(from: filteredItems),
            totalReviewCount: totalReviewCount(from: filteredItems),
            pendingReviewCount: pendingReviewCount(from: filteredItems),
            overdueCount: overdueCount(from: filteredItems),
            masteryRate: masteryRate(from: filteredItems),
            averageReviewCount: averageReviewCount(from: filteredItems)
        )
    }

    /// 已掌握数量
    func masteredCount(from items: [ReviewItem]) -> Int {
        items.filter { $0.isMastered }.count
    }

    /// 本周新增数量
    func weeklyNewCount(from items: [ReviewItem]) -> Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return items.filter { $0.createdAt >= weekAgo }.count
    }

    /// 累计复习次数
    func totalReviewCount(from items: [ReviewItem]) -> Int {
        items.reduce(0) { $0 + $1.reviewCount }
    }

    /// 待复习数量
    func pendingReviewCount(from items: [ReviewItem]) -> Int {
        items.filter { $0.needsReview }.count
    }

    /// 已逾期数量
    func overdueCount(from items: [ReviewItem]) -> Int {
        items.filter { $0.isOverdue }.count
    }

    /// 掌握率
    func masteryRate(from items: [ReviewItem]) -> Double {
        guard !items.isEmpty else { return 0 }
        return Double(masteredCount(from: items)) / Double(items.count)
    }

    /// 平均复习次数
    func averageReviewCount(from items: [ReviewItem]) -> Double {
        guard !items.isEmpty else { return 0 }
        return Double(totalReviewCount(from: items)) / Double(items.count)
    }
}

// MARK: - Chart Data

extension DashboardViewModel {
    /// 掌握程度分布数据
    func masteryData(from items: [ReviewItem]) -> [MasteryChartData] {
        let filteredItems = filterItems(items)

        return MasteryLevel.allCases.compactMap { level in
            let count = filteredItems.filter { $0.mastery == level }.count
            guard count > 0 else { return nil }
            return MasteryChartData(
                level: level,
                count: count,
                percentage: Double(count) / Double(max(1, filteredItems.count))
            )
        }
    }

    /// 学科分布数据
    func subjectData(from items: [ReviewItem]) -> [SubjectChartData] {
        let filteredItems = filterItems(items)
        let total = filteredItems.count

        return Dictionary(grouping: filteredItems, by: { $0.subject })
            .map { subject, subjectItems in
                SubjectChartData(
                    subject: subject,
                    count: subjectItems.count,
                    percentage: Double(subjectItems.count) / Double(max(1, total))
                )
            }
            .sorted { $0.count > $1.count }
    }

    /// 难度分布数据
    func difficultyData(from items: [ReviewItem]) -> [DifficultyChartData] {
        let filteredItems = filterItems(items)

        return Difficulty.allCases.compactMap { difficulty in
            let count = filteredItems.filter { $0.difficulty == difficulty }.count
            guard count > 0 else { return nil }
            return DifficultyChartData(
                difficulty: difficulty,
                count: count
            )
        }
    }

    /// 每日趋势数据（最近7天）
    func dailyTrendData(from items: [ReviewItem]) -> [DailyTrendData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let nextDate = calendar.date(byAdding: .day, value: 1, to: date)!

            let newCount = items.filter {
                $0.createdAt >= date && $0.createdAt < nextDate
            }.count

            let reviewedCount = items.filter {
                $0.reviewCount > 0 && $0.updatedAt >= date && $0.updatedAt < nextDate
            }.count

            return DailyTrendData(
                date: date,
                newCount: newCount,
                reviewedCount: reviewedCount
            )
        }
    }
}

// MARK: - Insights

extension DashboardViewModel {
    /// 生成学习洞察
    func generateInsights(from items: [ReviewItem]) -> [LearningInsight] {
        var insights: [LearningInsight] = []

        let stats = computeStatistics(from: items)

        // 逾期提醒
        if stats.overdueCount > 0 {
            insights.append(LearningInsight(
                type: .warning,
                title: "有 \(stats.overdueCount) 道题已逾期",
                message: "建议尽快复习，避免遗忘"
            ))
        }

        // 掌握率提示
        if stats.masteryRate >= 0.8 {
            insights.append(LearningInsight(
                type: .success,
                title: "掌握率很棒！",
                message: "已掌握 \(Int(stats.masteryRate * 100))% 的错题"
            ))
        } else if stats.masteryRate < 0.3 && stats.totalCount > 10 {
            insights.append(LearningInsight(
                type: .info,
                title: "继续加油",
                message: "多复习可以提高掌握率"
            ))
        }

        // 薄弱学科
        let subjectStats = subjectData(from: items)
        if let weakest = subjectStats.first, weakest.count > 5 {
            insights.append(LearningInsight(
                type: .info,
                title: "\(weakest.subject.displayName) 错题最多",
                message: "共 \(weakest.count) 道题，建议重点复习"
            ))
        }

        return insights
    }
}
