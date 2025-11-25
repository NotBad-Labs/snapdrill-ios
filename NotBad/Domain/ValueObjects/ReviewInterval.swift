//
//  ReviewInterval.swift
//  NotBad
//
//  复习间隔值对象 - 基于艾宾浩斯遗忘曲线
//

import Foundation

/// 复习间隔计算器
///
/// 遵循值对象原则：完全不可变，相同输入产生相同输出
/// 基于艾宾浩斯遗忘曲线，结合掌握程度动态调整复习间隔
struct ReviewInterval: Equatable, Codable, Hashable {
    /// 复习次数
    let reviewCount: Int
    /// 掌握程度
    let mastery: MasteryLevel
    /// 基准日期（用于计算下次复习日期）
    let baseDate: Date
    
    // MARK: - 艾宾浩斯遗忘曲线参数
    
    /// 标准复习间隔序列（天）
    /// 基于艾宾浩斯遗忘曲线：1, 2, 4, 7, 15, 30, 60, 120...
    private static let standardIntervals = [1, 2, 4, 7, 15, 30, 60, 120, 180, 365]
    
    /// 遗忘曲线系数（用于计算记忆保持率）
    /// R = e^(-t/S)，其中 S 为稳定性系数
    private static let stabilityCoefficient: Double = 1.84
    
    // MARK: - 间隔计算
    
    /// 计算下次复习间隔天数
    var intervalDays: Int {
        let baseInterval = Self.standardIntervals[safe: reviewCount] ?? 365
        
        let multiplier: Double = {
            switch mastery {
            case .mastered: return 2.0   // 完全掌握：间隔翻倍
            case .good: return 1.5       // 基本掌握：间隔延长
            case .partial: return 1.0    // 似懂非懂：标准间隔
            case .glimpse: return 0.5    // 一知半解：间隔缩短
            case .none: return 0.25      // 完全不会：立即复习
            }
        }()
        
        return max(1, Int(Double(baseInterval) * multiplier))
    }
    
    /// 计算下次复习日期
    var nextReviewDate: Date {
        Calendar.current.date(byAdding: .day, value: intervalDays, to: baseDate) ?? baseDate
    }
    
    // MARK: - 时间状态
    
    /// 距离下次复习的天数（正数=还有几天，负数=已逾期几天）
    var daysUntilReview: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let reviewDay = calendar.startOfDay(for: nextReviewDate)
        return calendar.dateComponents([.day], from: today, to: reviewDay).day ?? 0
    }
    
    /// 是否已逾期
    var isOverdue: Bool {
        daysUntilReview < 0
    }
    
    /// 逾期天数（如果未逾期返回0）
    var overdueByDays: Int {
        max(0, -daysUntilReview)
    }
    
    /// 是否今天需要复习
    var isDueToday: Bool {
        daysUntilReview <= 0
    }
    
    /// 是否本周内需要复习
    var isDueThisWeek: Bool {
        daysUntilReview <= 7
    }
    
    // MARK: - 记忆保持率
    
    /// 估算当前记忆保持率（0.0 - 1.0）
    /// 基于艾宾浩斯遗忘曲线: R = e^(-t/S)
    var estimatedRetention: Double {
        let daysSinceBase = max(0, -daysUntilReview + intervalDays)
        guard daysSinceBase > 0 else { return 1.0 }
        
        // 根据掌握程度调整稳定性系数
        let adjustedStability = Self.stabilityCoefficient * masteryStabilityFactor
        let retention = exp(-Double(daysSinceBase) / (adjustedStability * Double(intervalDays)))
        return min(1.0, max(0.0, retention))
    }
    
    /// 掌握程度对记忆稳定性的影响因子
    private var masteryStabilityFactor: Double {
        switch mastery {
        case .mastered: return 2.0
        case .good: return 1.5
        case .partial: return 1.0
        case .glimpse: return 0.7
        case .none: return 0.5
        }
    }
    
    /// 记忆保持率百分比描述
    var retentionDescription: String {
        let percentage = Int(estimatedRetention * 100)
        switch percentage {
        case 90...100: return "记忆清晰"
        case 70..<90: return "记忆良好"
        case 50..<70: return "记忆模糊"
        case 30..<50: return "即将遗忘"
        default: return "可能已遗忘"
        }
    }
    
    // MARK: - 紧迫程度
    
    /// 复习紧迫程度（1-5，越高越紧急）
    var urgencyLevel: Int {
        switch daysUntilReview {
        case ..<0: return 5      // 已逾期
        case 0: return 4         // 今天
        case 1...3: return 3     // 近期
        case 4...7: return 2     // 本周
        default: return 1        // 较远
        }
    }
    
    /// 复习紧迫程度描述
    var urgencyDescription: String {
        switch daysUntilReview {
        case ..<(-7): return "严重逾期"
        case (-7)..<0: return "已逾期"
        case 0: return "今天复习"
        case 1: return "明天复习"
        case 2...3: return "近期复习"
        case 4...7: return "本周复习"
        case 8...30: return "本月复习"
        default: return "已掌握"
        }
    }
    
    /// 复习紧迫程度简短描述
    var urgencyShortDescription: String {
        switch daysUntilReview {
        case ..<0: return "逾期\(overdueByDays)天"
        case 0: return "今天"
        case 1: return "明天"
        case 2...7: return "\(daysUntilReview)天后"
        default: return "\(daysUntilReview)天后"
        }
    }
    
    // MARK: - 静态工厂方法
    
    /// 首次复习（新录入的错题）
    static func firstReview(mastery: MasteryLevel = .none) -> ReviewInterval {
        ReviewInterval(reviewCount: 0, mastery: mastery, baseDate: Date())
    }
    
    /// 根据复习历史计算
    static func calculate(reviewCount: Int, mastery: MasteryLevel) -> ReviewInterval {
        ReviewInterval(reviewCount: reviewCount, mastery: mastery, baseDate: Date())
    }
    
    /// 根据复习历史和指定日期计算（用于测试或特殊场景）
    static func calculate(reviewCount: Int, mastery: MasteryLevel, from date: Date) -> ReviewInterval {
        ReviewInterval(reviewCount: reviewCount, mastery: mastery, baseDate: date)
    }
    
    /// 从上次复习记录创建下一次复习间隔
    static func next(from previous: ReviewInterval, newMastery: MasteryLevel) -> ReviewInterval {
        ReviewInterval(
            reviewCount: previous.reviewCount + 1,
            mastery: newMastery,
            baseDate: Date()
        )
    }
}

// MARK: - Comparable

extension ReviewInterval: Comparable {
    /// 按紧迫程度排序（越紧急越靠前）
    static func < (lhs: ReviewInterval, rhs: ReviewInterval) -> Bool {
        lhs.daysUntilReview < rhs.daysUntilReview
    }
}

// MARK: - CustomStringConvertible

extension ReviewInterval: CustomStringConvertible {
    var description: String {
        "\(urgencyDescription) (保持率: \(Int(estimatedRetention * 100))%)"
    }
}

// MARK: - Array Safe Access

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
