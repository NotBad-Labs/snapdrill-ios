//
//  ReviewScheduler.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/03/02.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SM-2 间隔重复调度引擎，纯算法实现，不依赖任何实体模型。
//

import Foundation

/// SM-2 复习调度器
///
/// 实现 SuperMemo 2 (SM-2) 间隔重复算法：
/// - 根据用户评分动态调整难度因子（Ease Factor）
/// - 计算下一次复习的最优间隔
/// - 跟踪连续正确次数以优化学习曲线
///
/// ## 算法公式
/// - 新的 EF = EF + (0.1 - (5 - q) × (0.08 + (5 - q) × 0.02))
/// - 其中 q 为用户评分（0-5）
/// - EF 最小值为 1.3
///
/// ## 间隔计算
/// - 第 1 次复习：1 天
/// - 第 2 次复习：6 天
/// - 之后：interval × EF
public struct ReviewScheduler {

    // MARK: - Properties

    private let minEaseFactor: Double = 1.3
    /// 单次间隔上限（365 天），防止 SM-2 累乘后产生不切实际的超长周期
    private let maxInterval: Int = 365

    // MARK: - Initialization

    /// 创建 SM-2 调度器实例
    public init() {}

    // MARK: - Public API

    /// 根据评分计算下一次复习调度状态
    ///
    /// - Parameters:
    ///   - state: 当前 SM-2 状态
    ///   - rating: 用户评分
    /// - Returns: 更新后的 SM-2 状态
    public func scheduleNextReview(state: SM2State, rating: ReviewRating) -> SM2State {
        var result = state
        let now = Date()
        result.lastReviewedAt = now

        let q = Double(rating.rawValue)
        // efDelta 仅依赖评分 q，与 easeFactor 无关；在输出侧 clamp 而非输入侧，
        // 确保即使历史 easeFactor 偏低，增量仍基于真实历史值计算，保留完整学习曲线。
        let efDelta = 0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02)
        var newEF = state.easeFactor + efDelta
        newEF = max(newEF, minEaseFactor)
        result.easeFactor = newEF

        if rating == .again {
            result.repetitions = 0
            result.interval = 0
            result.nextReviewAt = now.addingTimeInterval(10 * 60)
        } else {
            result.repetitions = state.repetitions + 1

            let newInterval: Int
            switch result.repetitions {
            case 1:
                newInterval = 1
            case 2:
                newInterval = 6
            default:
                newInterval = min(Int(ceil(Double(state.interval) * newEF)), maxInterval)
            }

            result.interval = newInterval
            result.nextReviewAt = Calendar.current.date(byAdding: .day, value: newInterval, to: now)
        }

        return result
    }

    /// 获取评分对应的间隔描述（用于 UI 显示）
    ///
    /// - Parameters:
    ///   - rating: 用户评分
    ///   - state: 当前 SM-2 状态
    /// - Returns: 人类可读的间隔描述，如"明天"、"3天"、"2周"
    public func intervalDescription(for rating: ReviewRating, from state: SM2State) -> String {
        if rating == .again {
            return "10分钟"
        }

        let scheduled = scheduleNextReview(state: state, rating: rating)
        let interval = scheduled.interval

        if interval == 1 {
            return "明天"
        } else if interval < 7 {
            return "\(interval)天"
        } else if interval < 30 {
            // 四舍五入避免截断（如 13 天 = 1.86 周 → 显示"2周"而非"1周"）
            let weeks = max(1, Int((Double(interval) / 7.0).rounded()))
            return "\(weeks)周"
        } else {
            let months = max(1, Int((Double(interval) / 30.0).rounded()))
            return "\(months)个月"
        }
    }
}
