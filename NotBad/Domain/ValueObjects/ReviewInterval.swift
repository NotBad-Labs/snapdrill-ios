//
//  ReviewInterval.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import Foundation

// MARK: - ReviewInterval

/// 复习间隔计算器
///
/// 基于艾宾浩斯遗忘曲线，结合掌握程度动态调整复习间隔。
/// 遵循值对象原则：完全不可变，相同输入产生相同输出。
///
/// ## 遗忘曲线原理
///
/// 艾宾浩斯遗忘曲线表明，记忆随时间呈指数衰减：
/// - 20分钟后：遗忘 42%
/// - 1小时后：遗忘 56%
/// - 1天后：遗忘 74%
/// - 1周后：遗忘 77%
/// - 1个月后：遗忘 79%
///
/// ## 间隔重复策略
///
/// 通过在最佳时机复习，可以将遗忘曲线"重置"：
/// ```
/// 标准间隔序列：1, 2, 4, 7, 15, 30, 60, 120, 180, 365 天
/// ```
///
/// ## 使用示例
///
/// ```swift
/// // 创建首次复习间隔
/// let firstInterval = ReviewInterval.firstReview(mastery: .none)
///
/// // 计算下次复习日期
/// let nextDate = firstInterval.nextReviewDate
///
/// // 检查紧迫程度
/// if firstInterval.isDueToday {
///     print("今天需要复习")
/// }
///
/// // 创建后续复习间隔
/// let nextInterval = ReviewInterval.next(from: firstInterval, newMastery: .partial)
/// ```
///
/// - Note: 此值对象是不可变的，所有属性都是 `let` 声明
/// - Important: 记忆保持率计算基于科学研究，但仅供参考
struct ReviewInterval: Sendable, Equatable, Codable, Hashable, Identifiable {

    // MARK: - Properties

    /// 复习次数
    ///
    /// 从 0 开始计数，表示已完成的复习次数。
    /// 影响标准间隔的选择。
    let reviewCount: Int

    /// 掌握程度
    ///
    /// 影响复习间隔的调整系数：
    /// - 掌握程度越高，间隔越长
    /// - 掌握程度越低，间隔越短
    let mastery: MasteryLevel

    /// 基准日期
    ///
    /// 用于计算下次复习日期的起始日期。
    /// 通常为上次复习日期或录入日期。
    let baseDate: Date

    // MARK: - Identifiable

    /// 唯一标识符
    ///
    /// 组合复习次数、掌握程度和基准日期生成。
    nonisolated var id: String {
        "\(reviewCount)-\(mastery.rawValue)-\(baseDate.timeIntervalSince1970)"
    }
}

// MARK: - ReviewInterval Ebbinghaus Constants

extension ReviewInterval {

    /// 标准复习间隔序列（天）
    ///
    /// 基于艾宾浩斯遗忘曲线的最佳复习时机：
    /// - 第1次：1天后
    /// - 第2次：2天后
    /// - 第3次：4天后
    /// - 第4次：1周后
    /// - 第5次：2周后
    /// - 第6次：1个月后
    /// - 第7次：2个月后
    /// - 第8次：4个月后
    /// - 第9次：半年后
    /// - 第10次：1年后
    nonisolated static var standardIntervals: [Int] {
        [1, 2, 4, 7, 15, 30, 60, 120, 180, 365]
    }

    /// 遗忘曲线稳定性系数
    ///
    /// 用于记忆保持率计算。此值基于 SuperMemo SM-2 算法的简化版本，
    /// 结合艾宾浩斯遗忘曲线的研究调整。
    ///
    /// - Note: 原始艾宾浩斯研究使用无意义音节，实际学习效果会更好。
    ///   此系数经过调整以适应 K12 教育场景中的有意义学习材料。
    /// - SeeAlso: Pimsleur, P. (1967). A memory schedule.
    nonisolated static var stabilityCoefficient: Double { 1.84 }
}

// MARK: - ReviewInterval Interval Calculation

extension ReviewInterval {

    /// 计算下次复习间隔天数
    ///
    /// 根据复习次数获取基础间隔，再根据掌握程度调整：
    /// - 完全掌握：间隔 × 2.0
    /// - 基本掌握：间隔 × 1.5
    /// - 部分掌握：间隔 × 1.0
    /// - 一知半解：间隔 × 0.5
    /// - 完全不会：间隔 × 0.25
    ///
    /// - Returns: 调整后的复习间隔天数，最小为 1 天
    nonisolated var intervalDays: Int {
        let baseInterval = Self.standardIntervals[safe: reviewCount] ?? 365
        let multiplier = mastery.intervalMultiplier
        return max(1, Int(Double(baseInterval) * multiplier))
    }

    /// 计算下次复习日期
    ///
    /// 基于 `baseDate` 加上 `intervalDays` 计算。
    ///
    /// - Returns: 下次应该复习的日期
    nonisolated var nextReviewDate: Date {
        Calendar.current.date(byAdding: .day, value: intervalDays, to: baseDate) ?? baseDate
    }
}

// MARK: - ReviewInterval Time Status

extension ReviewInterval {

    /// 距离下次复习的天数
    ///
    /// - 正数：还有几天需要复习
    /// - 零：今天需要复习
    /// - 负数：已逾期几天
    nonisolated var daysUntilReview: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let reviewDay = calendar.startOfDay(for: nextReviewDate)
        return calendar.dateComponents([.day], from: today, to: reviewDay).day ?? 0
    }

    /// 是否已逾期
    nonisolated var isOverdue: Bool { daysUntilReview < 0 }

    /// 逾期天数
    ///
    /// 如果未逾期返回 0。
    nonisolated var overdueByDays: Int { max(0, -daysUntilReview) }

    /// 是否今天需要复习
    ///
    /// 包括已逾期的情况。
    nonisolated var isDueToday: Bool { daysUntilReview <= 0 }

    /// 是否本周内需要复习
    nonisolated var isDueThisWeek: Bool { daysUntilReview <= 7 }

    /// 是否本月内需要复习
    nonisolated var isDueThisMonth: Bool { daysUntilReview <= 30 }
}

// MARK: - ReviewInterval Memory Retention

extension ReviewInterval {

    /// 估算当前记忆保持率
    ///
    /// 基于简化的遗忘曲线模型：R = e^(-t / (S × M))
    /// 其中：
    /// - R：记忆保持率（0.0 - 1.0）
    /// - t：距离上次学习的天数
    /// - S：基础稳定性系数（`stabilityCoefficient`）
    /// - M：掌握程度调整因子（`masteryStabilityFactor`）
    ///
    /// 与标准艾宾浩斯公式 R = e^(-t/S) 的区别：
    /// 本实现添加了掌握程度因子，使得掌握越好衰减越慢。
    ///
    /// - Returns: 0.0 到 1.0 之间的保持率
    nonisolated var estimatedRetention: Double {
        let daysSinceBase = max(0, -daysUntilReview + intervalDays)
        guard daysSinceBase > 0 else { return 1.0 }

        let adjustedStability = Self.stabilityCoefficient * masteryStabilityFactor
        let retention = exp(-Double(daysSinceBase) / adjustedStability)
        return min(1.0, max(0.0, retention))
    }

    /// 掌握程度对记忆稳定性的影响因子
    ///
    /// 掌握程度越高，记忆越稳定，衰减越慢。
    nonisolated private var masteryStabilityFactor: Double {
        mastery.stabilityFactor
    }

    /// 记忆保持率百分比
    nonisolated var retentionPercentage: Int {
        Int(estimatedRetention * 100)
    }

    /// 记忆保持率描述
    nonisolated var retentionDescription: String {
        switch retentionPercentage {
        case 90...100: "记忆清晰"
        case 70..<90: "记忆良好"
        case 50..<70: "记忆模糊"
        case 30..<50: "即将遗忘"
        default: "可能已遗忘"
        }
    }
}

// MARK: - ReviewInterval Urgency

extension ReviewInterval {

    /// 复习紧迫程度等级
    ///
    /// 1-5 级，数字越大越紧急：
    /// - 5：已逾期
    /// - 4：今天
    /// - 3：近期（1-3天）
    /// - 2：本周（4-7天）
    /// - 1：较远（7天以上）
    nonisolated var urgencyLevel: Int {
        switch daysUntilReview {
        case ..<0: 5
        case 0: 4
        case 1...3: 3
        case 4...7: 2
        default: 1
        }
    }

    /// 复习紧迫程度描述
    nonisolated var urgencyDescription: String {
        switch daysUntilReview {
        case ..<(-7): "严重逾期"
        case (-7)..<0: "已逾期"
        case 0: "今天复习"
        case 1: "明天复习"
        case 2...3: "近期复习"
        case 4...7: "本周复习"
        case 8...30: "本月复习"
        default: "已掌握"
        }
    }

    /// 复习紧迫程度简短描述
    nonisolated var urgencyShortDescription: String {
        switch daysUntilReview {
        case ..<0: "逾期\(overdueByDays)天"
        case 0: "今天"
        case 1: "明天"
        default: "\(daysUntilReview)天后"
        }
    }

    /// 是否紧急（需要立即关注）
    nonisolated var isUrgent: Bool { urgencyLevel >= 4 }
}

// MARK: - ReviewInterval Factory Methods

extension ReviewInterval {

    /// 创建首次复习间隔
    ///
    /// 用于新录入的错题，复习次数为 0。
    ///
    /// - Parameter mastery: 初始掌握程度，默认为 `.none`
    /// - Returns: 首次复习间隔实例
    nonisolated static func firstReview(mastery: MasteryLevel = .none) -> ReviewInterval {
        ReviewInterval(reviewCount: 0, mastery: mastery, baseDate: Date())
    }

    /// 根据复习历史计算间隔
    ///
    /// - Parameters:
    ///   - reviewCount: 已完成的复习次数
    ///   - mastery: 当前掌握程度
    /// - Returns: 计算后的复习间隔实例
    nonisolated static func calculate(reviewCount: Int, mastery: MasteryLevel) -> ReviewInterval {
        ReviewInterval(reviewCount: reviewCount, mastery: mastery, baseDate: Date())
    }

    /// 根据复习历史和指定日期计算间隔
    ///
    /// 主要用于测试或历史数据导入。
    ///
    /// - Parameters:
    ///   - reviewCount: 已完成的复习次数
    ///   - mastery: 当前掌握程度
    ///   - date: 基准日期
    /// - Returns: 计算后的复习间隔实例
    nonisolated static func calculate(
        reviewCount: Int,
        mastery: MasteryLevel,
        from date: Date
    ) -> ReviewInterval {
        ReviewInterval(reviewCount: reviewCount, mastery: mastery, baseDate: date)
    }

    /// 从上次复习记录创建下一次复习间隔
    ///
    /// 自动递增复习次数，更新基准日期为当前时间。
    ///
    /// - Parameters:
    ///   - previous: 上次复习间隔
    ///   - newMastery: 新的掌握程度
    /// - Returns: 下一次复习间隔实例
    nonisolated static func next(
        from previous: ReviewInterval,
        newMastery: MasteryLevel
    ) -> ReviewInterval {
        ReviewInterval(
            reviewCount: previous.reviewCount + 1,
            mastery: newMastery,
            baseDate: Date()
        )
    }
}

// MARK: - ReviewInterval Comparable

extension ReviewInterval: Comparable {

    /// 按紧迫程度排序
    ///
    /// 越紧急（daysUntilReview 越小）越靠前。
    nonisolated static func < (lhs: ReviewInterval, rhs: ReviewInterval) -> Bool {
        lhs.daysUntilReview < rhs.daysUntilReview
    }
}

// MARK: - ReviewInterval CustomStringConvertible

extension ReviewInterval: CustomStringConvertible {

    /// 调试描述
    nonisolated var description: String {
        "\(urgencyDescription) (保持率: \(retentionPercentage)%)"
    }
}

// MARK: - MasteryLevel Interval Extensions

private extension MasteryLevel {

    /// 间隔调整倍数
    nonisolated var intervalMultiplier: Double {
        switch self {
        case .mastered: 2.0
        case .good: 1.5
        case .partial: 1.0
        case .glimpse: 0.5
        case .none: 0.25
        }
    }

    /// 记忆稳定性因子
    nonisolated var stabilityFactor: Double {
        switch self {
        case .mastered: 2.0
        case .good: 1.5
        case .partial: 1.0
        case .glimpse: 0.7
        case .none: 0.5
        }
    }
}

// MARK: - Array Safe Access

private extension Array {

    /// 安全下标访问
    ///
    /// 避免数组越界崩溃。
    ///
    /// - Parameter index: 要访问的索引
    /// - Returns: 索引对应的元素，如果越界则返回 `nil`
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
