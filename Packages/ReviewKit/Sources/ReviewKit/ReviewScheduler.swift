// ReviewKit - 复习算法核心库
// 纯 Swift 实现，无 UIKit/SwiftUI 依赖
// 可在 iOS, macOS, watchOS, CLI 等任何环境运行

import Foundation

/// 复习表现评级
public enum ReviewPerformance: Int, Sendable {
    case forgot = 0      // 完全忘记
    case hard = 1        // 勉强记得
    case good = 2        // 正常掌握
    case easy = 3        // 轻松掌握
}

/// 复习调度器
///
/// 基于艾宾浩斯遗忘曲线的间隔重复算法实现。
/// 这是 NotBad 的核心算法，完全独立于 UI 层。
///
/// ## 使用示例
///
/// ```swift
/// let scheduler = ReviewScheduler()
/// let nextDate = scheduler.calculateNextReviewDate(
///     currentMastery: 2,
///     reviewCount: 3
/// )
/// ```
public struct ReviewScheduler: Sendable {
    
    /// 基础间隔配置（天）
    private let baseIntervals: [Int]
    
    /// 掌握程度对应的倍率
    private let masteryMultipliers: [Int: Double]
    
    /// 创建调度器（使用默认配置）
    public init() {
        self.baseIntervals = [1, 2, 4, 7, 14, 30, 60]
        self.masteryMultipliers = [
            0: 0.5,   // 完全不会，缩短间隔
            1: 0.75,  // 部分掌握
            2: 1.0,   // 大部分掌握
            3: 1.5    // 完全掌握，延长间隔
        ]
    }
    
    /// 创建调度器（自定义配置）
    /// - Parameters:
    ///   - baseIntervals: 基础间隔数组（天）
    ///   - masteryMultipliers: 掌握程度倍率映射
    public init(baseIntervals: [Int], masteryMultipliers: [Int: Double]) {
        self.baseIntervals = baseIntervals
        self.masteryMultipliers = masteryMultipliers
    }
    
    /// 计算下次复习日期
    /// - Parameters:
    ///   - currentMastery: 当前掌握程度 (0-3)
    ///   - reviewCount: 已复习次数
    ///   - from: 起始日期（默认今天）
    /// - Returns: 下次复习日期
    public func calculateNextReviewDate(
        currentMastery: Int,
        reviewCount: Int,
        from date: Date = Date()
    ) -> Date {
        let calendar = Calendar.current
        
        // 获取掌握程度倍率
        let multiplier = masteryMultipliers[currentMastery] ?? 1.0
        
        // 取对应的基础间隔
        let index = min(reviewCount, baseIntervals.count - 1)
        let baseInterval = baseIntervals[index]
        
        // 计算实际间隔（至少 1 天）
        let actualInterval = max(1, Int(Double(baseInterval) * multiplier))
        
        return calendar.date(byAdding: .day, value: actualInterval, to: date) ?? date
    }
    
    /// 根据复习表现计算下次复习日期
    /// - Parameters:
    ///   - performance: 复习表现
    ///   - reviewCount: 已复习次数
    ///   - from: 起始日期
    /// - Returns: 下次复习日期
    public func calculateNextReviewDate(
        performance: ReviewPerformance,
        reviewCount: Int,
        from date: Date = Date()
    ) -> Date {
        calculateNextReviewDate(
            currentMastery: performance.rawValue,
            reviewCount: reviewCount,
            from: date
        )
    }
    
    /// 计算间隔天数（不返回日期，用于预览）
    /// - Parameters:
    ///   - currentMastery: 掌握程度
    ///   - reviewCount: 复习次数
    /// - Returns: 间隔天数
    public func calculateIntervalDays(currentMastery: Int, reviewCount: Int) -> Int {
        let multiplier = masteryMultipliers[currentMastery] ?? 1.0
        let index = min(reviewCount, baseIntervals.count - 1)
        let baseInterval = baseIntervals[index]
        return max(1, Int(Double(baseInterval) * multiplier))
    }
}

// MARK: - Convenience Extensions

public extension ReviewScheduler {
    
    /// 默认共享实例
    static let shared = ReviewScheduler()
    
    /// 静态方法：计算下次复习日期
    ///
    /// 便利方法，供 ReviewItemModel.recordReview() 调用
    /// - Parameters:
    ///   - currentMastery: 掌握程度 (0-3)
    ///   - reviewCount: 复习次数
    /// - Returns: 下次复习日期
    static func calculateNextReviewDate(currentMastery: Int, reviewCount: Int) -> Date {
        shared.calculateNextReviewDate(
            currentMastery: currentMastery,
            reviewCount: reviewCount
        )
    }
}
