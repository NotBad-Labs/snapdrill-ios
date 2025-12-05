//
//  GetStatisticsUseCaseProtocol.swift
//  NotBad
//
//  Domain Layer - Use Case Protocol
//

import Foundation

// MARK: - GetStatisticsUseCaseProtocol

/// 获取统计数据用例协议
///
/// 负责计算和返回各类统计数据：
/// - 总览统计
/// - 学科统计
/// - 时间趋势
/// - 复习进度
///
/// ## 使用示例
///
/// ```swift
/// let useCase = dependencies.makeGetStatisticsUseCase()
/// let overview = try await useCase.executeOverview()
/// print("总题目数: \(overview.totalCount)")
/// ```
@MainActor
protocol GetStatisticsUseCaseProtocol: Sendable {
    
    /// 获取总览统计
    ///
    /// - Returns: 总览统计数据
    func executeOverview() async -> OverviewStatistics
    
    /// 获取学科统计
    ///
    /// - Returns: 各学科统计数据
    func executeBySubject() async -> [SubjectStatistics]
    
    /// 获取指定学科的详细统计
    ///
    /// - Parameter subject: 学科
    /// - Returns: 该学科的详细统计
    func execute(subject: Subject) async -> SubjectStatistics
    
    /// 获取复习趋势
    ///
    /// - Parameter days: 天数
    /// - Returns: 每日复习数据
    func executeTrend(days: Int) async -> [DailyStatistics]
    
    /// 获取今日进度
    ///
    /// - Returns: 今日复习进度
    func executeTodayProgress() async -> TodayProgress
}

// MARK: - OverviewStatistics

/// 总览统计数据
struct OverviewStatistics: Sendable {
    
    /// 总题目数
    let totalCount: Int
    
    /// 需要复习的题目数
    let dueCount: Int
    
    /// 今日到期数
    let dueTodayCount: Int
    
    /// 逾期数
    let overdueCount: Int
    
    /// 已掌握数
    let masteredCount: Int
    
    /// 各掌握程度分布
    let masteryDistribution: [MasteryLevel: Int]
    
    /// 各学科分布
    let subjectDistribution: [Subject: Int]
    
    /// 本周复习次数
    let weeklyReviewCount: Int
    
    /// 本月复习次数
    let monthlyReviewCount: Int
    
    /// 平均正确率
    let averageCorrectRate: Double
    
    /// 连续复习天数
    let streakDays: Int
    
    // MARK: - Computed Properties
    
    /// 掌握率
    var masteryRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(masteredCount) / Double(totalCount)
    }
    
    /// 是否有逾期题目
    var hasOverdue: Bool {
        overdueCount > 0
    }
    
    /// 是否需要复习
    var needsReview: Bool {
        dueCount > 0
    }
}

// MARK: - SubjectStatistics

/// 学科统计数据
struct SubjectStatistics: Identifiable, Sendable {
    
    /// 学科
    let subject: Subject
    
    /// 总题目数
    let totalCount: Int
    
    /// 需要复习的题目数
    let dueCount: Int
    
    /// 已掌握数
    let masteredCount: Int
    
    /// 各掌握程度分布
    let masteryDistribution: [MasteryLevel: Int]
    
    /// 各难度分布
    let difficultyDistribution: [Difficulty: Int]
    
    /// 平均正确率
    let averageCorrectRate: Double
    
    /// 总复习次数
    let totalReviewCount: Int
    
    // MARK: - Identifiable
    
    var id: String { subject.rawValue }
    
    // MARK: - Computed Properties
    
    /// 掌握率
    var masteryRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(masteredCount) / Double(totalCount)
    }
}

// MARK: - DailyStatistics

/// 每日统计数据
struct DailyStatistics: Identifiable, Sendable {
    
    /// 日期
    let date: Date
    
    /// 复习题目数
    let reviewedCount: Int
    
    /// 正确数
    let correctCount: Int
    
    /// 新增题目数
    let addedCount: Int
    
    // MARK: - Identifiable
    
    var id: Date { date }
    
    // MARK: - Computed Properties
    
    /// 正确率
    var correctRate: Double {
        guard reviewedCount > 0 else { return 0 }
        return Double(correctCount) / Double(reviewedCount)
    }
    
    /// 日期字符串（用于显示）
    var dateString: String {
        date.formatted(.dateTime.month().day())
    }
}

// MARK: - TodayProgress

/// 今日进度
struct TodayProgress: Sendable {
    
    /// 今日目标数
    let targetCount: Int
    
    /// 已完成数
    let completedCount: Int
    
    /// 剩余数
    let remainingCount: Int
    
    /// 正确数
    let correctCount: Int
    
    /// 总用时（秒）
    let totalDuration: TimeInterval
    
    // MARK: - Computed Properties
    
    /// 完成进度
    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(1.0, Double(completedCount) / Double(targetCount))
    }
    
    /// 是否完成
    var isCompleted: Bool {
        completedCount >= targetCount
    }
    
    /// 正确率
    var correctRate: Double {
        guard completedCount > 0 else { return 0 }
        return Double(correctCount) / Double(completedCount)
    }
    
    /// 用时描述
    var durationDescription: String {
        let minutes = Int(totalDuration / 60)
        if minutes < 60 {
            return "\(minutes) 分钟"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours) 小时 \(remainingMinutes) 分钟"
        }
    }
}
