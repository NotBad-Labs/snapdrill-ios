//
//  DashboardViewModel.swift
//  NotBad
//
//  Created for NotBad K12 错题本
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
/// ## 使用示例
///
/// ```swift
/// struct DashboardView: View {
///     @Query private var items: [ReviewItem]
///     @State private var viewModel = DashboardViewModel()
///
///     var body: some View {
///         let stats = viewModel.computeStatistics(from: items)
///         Text("已掌握: \(stats.masteredCount)")
///     }
/// }
/// ```
///
/// - Note: 使用 `@Observable` 宏支持 SwiftUI 自动更新
/// - Important: 所有方法都是纯函数，基于传入的数据计算结果
@MainActor
@Observable
final class DashboardViewModel {
    
    // MARK: - State
    
    /// 选中的时间范围
    var selectedTimeRange: TimeRange = .week
    
    /// 选中的学科（用于筛选）
    var selectedSubject: Subject?
    
    // MARK: - Computed Statistics
    
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
    
    // MARK: - Chart Data
    
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
    
    // MARK: - Insights
    
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

// MARK: - TimeRange

/// 时间范围选项
enum TimeRange: String, CaseIterable, Identifiable {
    case week = "本周"
    case month = "本月"
    case quarter = "本季度"
    case year = "今年"
    case all = "全部"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var startDate: Date? {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now)
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now)
        case .quarter:
            return calendar.date(byAdding: .month, value: -3, to: now)
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now)
        case .all:
            return nil
        }
    }
}

// MARK: - DashboardStatistics

/// 仪表盘统计数据
struct DashboardStatistics: Sendable, Equatable {
    let totalCount: Int
    let masteredCount: Int
    let weeklyNewCount: Int
    let totalReviewCount: Int
    let pendingReviewCount: Int
    let overdueCount: Int
    let masteryRate: Double
    let averageReviewCount: Double
    
    /// 掌握率百分比描述
    var masteryPercentageText: String {
        "\(Int(masteryRate * 100))%"
    }
    
    /// 是否有待复习
    var hasPendingReview: Bool {
        pendingReviewCount > 0
    }
    
    /// 是否有逾期
    var hasOverdue: Bool {
        overdueCount > 0
    }
    
    /// 空统计数据
    static let empty = DashboardStatistics(
        totalCount: 0,
        masteredCount: 0,
        weeklyNewCount: 0,
        totalReviewCount: 0,
        pendingReviewCount: 0,
        overdueCount: 0,
        masteryRate: 0,
        averageReviewCount: 0
    )
}

// MARK: - Chart Data Models

/// 掌握程度图表数据
struct MasteryChartData: Identifiable, Sendable {
    let level: MasteryLevel
    let count: Int
    let percentage: Double
    
    var id: Int { level.rawValue }
    var label: String { level.displayName }
    var color: Color { level.color }
}

/// 学科图表数据
struct SubjectChartData: Identifiable, Sendable {
    let subject: Subject
    let count: Int
    let percentage: Double
    
    var id: String { subject.rawValue }
    var displayName: String { subject.displayName }
    var color: Color { subject.color }
}

/// 难度图表数据
struct DifficultyChartData: Identifiable, Sendable {
    let difficulty: Difficulty
    let count: Int
    
    var id: Int { difficulty.rawValue }
    var label: String { difficulty.displayName }
    var color: Color { difficulty.color }
}

/// 每日趋势数据
struct DailyTrendData: Identifiable, Sendable {
    let date: Date
    let newCount: Int
    let reviewedCount: Int
    
    var id: Date { date }
    
    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - Learning Insight

/// 学习洞察
struct LearningInsight: Identifiable, Sendable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    
    enum InsightType: Sendable {
        case success
        case warning
        case info
        
        var icon: String {
            switch self {
            case .success: "checkmark.circle.fill"
            case .warning: "exclamationmark.triangle.fill"
            case .info: "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: .green
            case .warning: .orange
            case .info: .blue
            }
        }
    }
}

// MARK: - Legacy Compatibility

/// 兼容旧版 MasteryData
typealias MasteryData = MasteryChartData

/// 兼容旧版 SubjectData
struct SubjectData: Sendable {
    let subject: String
    let count: Int
    
    init(subject: String, count: Int) {
        self.subject = subject
        self.count = count
    }
    
    init(from chartData: SubjectChartData) {
        self.subject = chartData.subject.displayName
        self.count = chartData.count
    }
}
