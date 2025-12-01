//
//  ReviewModels.swift
//  NotBad
//
//  复习功能相关模型
//

import SwiftUI

// MARK: - ReviewMode

/// 复习模式
///
/// 定义不同的复习策略。
///
/// ## 使用示例
///
/// ```swift
/// let mode = ReviewMode.smart
/// print(mode.displayName)  // "智能推荐"
/// print(mode.description)  // "根据艾宾浩斯曲线智能排序"
/// ```
enum ReviewMode: String, CaseIterable, Identifiable {
    case smart
    case weakest
    case random
    case newest
    case overdue

    var id: String { rawValue }

    var displayName: String {
        String(localized: displayNameKey)
    }

    private var displayNameKey: String.LocalizationValue {
        switch self {
        case .smart: "review_mode_smart"
        case .weakest: "review_mode_weakest"
        case .random: "review_mode_random"
        case .newest: "review_mode_newest"
        case .overdue: "review_mode_overdue"
        }
    }

    var icon: String {
        switch self {
        case .smart: "brain"
        case .weakest: "exclamationmark.triangle"
        case .random: "shuffle"
        case .newest: "clock"
        case .overdue: "calendar.badge.exclamationmark"
        }
    }

    var description: String {
        String(localized: descriptionKey)
    }

    private var descriptionKey: String.LocalizationValue {
        switch self {
        case .smart: "review_mode_smart_desc"
        case .weakest: "review_mode_weakest_desc"
        case .random: "review_mode_random_desc"
        case .newest: "review_mode_newest_desc"
        case .overdue: "review_mode_overdue_desc"
        }
    }
}

// MARK: - ReviewSessionState

/// 复习会话状态
///
/// 表示复习会话的当前状态。
enum ReviewSessionState: Sendable {
    case idle
    case inProgress
    case paused
    case completed

    var isActive: Bool {
        self == .inProgress || self == .paused
    }
}

// MARK: - ReviewSessionStatistics

/// 复习会话统计
///
/// 记录一次复习会话的统计数据。
///
/// ## 使用示例
///
/// ```swift
/// let stats = ReviewSessionStatistics(
///     totalReviewed: 10,
///     elapsedSeconds: 300,
///     masteryResults: [.mastered: 3, .good: 5, .needsWork: 2]
/// )
/// print(stats.formattedDuration)  // "5 分 0 秒"
/// print(stats.masteryRateDescription)  // "80%"
/// ```
struct ReviewSessionStatistics: Sendable {
    let totalReviewed: Int
    let elapsedSeconds: Int
    let masteryResults: [MasteryLevel: Int]

    /// 格式化的用时
    var formattedDuration: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60

        if minutes > 0 {
            return String(localized: "review_stats_duration_minutes_seconds \(minutes) \(seconds)")
        } else {
            return String(localized: "review_stats_duration_seconds \(seconds)")
        }
    }

    /// 掌握率
    var masteryRate: Double {
        guard totalReviewed > 0 else { return 0 }
        let goodCount = (masteryResults[.mastered] ?? 0) + (masteryResults[.good] ?? 0)
        return Double(goodCount) / Double(totalReviewed)
    }

    /// 掌握率描述
    var masteryRateDescription: String {
        "\(Int(masteryRate * 100))%"
    }

    /// 是否表现良好
    var isGoodPerformance: Bool {
        masteryRate >= 0.6
    }

    /// 鼓励语
    var encouragement: String {
        switch masteryRate {
        case 0.8...: String(localized: "review_stats_encouragement_excellent")
        case 0.6..<0.8: String(localized: "review_stats_encouragement_good")
        case 0.4..<0.6: String(localized: "review_stats_encouragement_keep_going")
        default: String(localized: "review_stats_encouragement_practice_more")
        }
    }
}
