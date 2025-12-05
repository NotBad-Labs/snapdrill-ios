//
//  DashboardModels.swift
//  NotBad
//
//  Created by LIAOYIMING on 2025/6/5.
//

import SwiftUI

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
    
    /// 图表颜色 - 使用渐变灰度区分，不依赖颜色传达信息
    var color: Color {
        // 通过透明度区分难度级别
        Color.accentColor.opacity(0.4 + Double(difficulty.rawValue) * 0.15)
    }
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
