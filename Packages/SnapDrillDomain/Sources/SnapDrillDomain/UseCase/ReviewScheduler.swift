//
//  ReviewScheduler.swift
//  SnapDrillDomain
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  复习调度引擎，实现 SM-2 间隔重复算法（迁移自 SnapDrillCore）。
//

import Foundation

/// 复习评分等级 (SM-2 标准等级)
///
/// SM-2 算法使用 0-5 的评分，此处简化为四级：
/// - `again` (0): 完全忘记
/// - `hard` (2): 记得但很吃力
/// - `good` (3): 记得但有些犹豫
/// - `easy` (5): 非常容易记住
public enum ReviewRating: Int {
    case again = 0  // 忘记了
    case hard = 2   // 很难
    case good = 3   // 还行
    case easy = 5   // 简单
}

/// SM-2 复习调度器
///
/// 实现 SuperMemo 2 (SM-2) 间隔重复算法：
/// - 根据用户评分动态调整难度因子 (Ease Factor)
/// - 计算下一次复习的最优间隔
/// - 跟踪连续正确次数以优化学习曲线
///
/// ## 算法公式
/// - 新的 EF = EF + (0.1 - (5 - q) × (0.08 + (5 - q) × 0.02))
/// - 其中 q 为用户评分 (0-5)
/// - EF 最小值为 1.3
///
/// ## 间隔计算
/// - 第 1 次复习: 1 天
/// - 第 2 次复习: 6 天
/// - 之后: interval × EF
public struct ReviewScheduler {
    
    // MARK: - Properties
    
    /// 最小难度因子
    private let minEaseFactor: Double = 1.3
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public API
    
    /// 根据评分计算下一次复习时间
    ///
    /// - Parameters:
    ///   - item: 当前复习条目
    ///   - rating: 用户评分
    /// - Returns: 更新后的复习条目（包含新的调度信息）
    public func scheduleNextReview(for item: ReviewItem, rating: ReviewRating) -> ReviewItem {
        var newItem = item
        let now = Date()
        newItem.lastReviewedAt = now
        
        let q = Double(rating.rawValue)
        
        // 计算新的 Ease Factor
        // EF' = EF + (0.1 - (5 - q) × (0.08 + (5 - q) × 0.02))
        let efDelta = 0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02)
        var newEF = item.easeFactor + efDelta
        
        // 确保 EF 不低于最小值
        newEF = max(newEF, minEaseFactor)
        newItem.easeFactor = newEF
        
        // 根据评分更新间隔和重复次数
        if rating == .again {
            // 忘记了，重置进度
            newItem.repetitions = 0
            newItem.interval = 0
            // 10 分钟后重新复习
            newItem.nextReviewAt = now.addingTimeInterval(10 * 60)
        } else {
            // 记住了，增加重复次数
            newItem.repetitions = item.repetitions + 1
            
            // 计算新间隔
            let newInterval: Int
            switch newItem.repetitions {
            case 1:
                newInterval = 1 // 1 天
            case 2:
                newInterval = 6 // 6 天
            default:
                // interval × EF
                newInterval = Int(ceil(Double(item.interval) * newEF))
            }
            
            newItem.interval = newInterval
            newItem.nextReviewAt = Calendar.current.date(byAdding: .day, value: newInterval, to: now)
        }
        
        return newItem
    }
    
    /// 获取评分对应的描述（用于 UI 显示）
    public func intervalDescription(for rating: ReviewRating, from item: ReviewItem) -> String {
        let scheduledItem = scheduleNextReview(for: item, rating: rating)
        
        if rating == .again {
            return "10分钟"
        }
        
        let interval = scheduledItem.interval
        if interval == 1 {
            return "明天"
        } else if interval < 7 {
            return "\(interval)天"
        } else if interval < 30 {
            let weeks = interval / 7
            return "\(weeks)周"
        } else {
            let months = interval / 30
            return "\(months)个月"
        }
    }
}
