//
//  ReviewService.swift
//  ReviewKit
//
//  复习业务服务
//
//  从 ReviewItemModel 中抽离业务逻辑，保持模型轻量。
//  提供复习记录、进度重置、批量操作等功能。
//

import Foundation
import ReviewKitCore
import ReviewKitModels

// MARK: - ReviewService

/// 复习业务服务
///
/// 处理复习相关的业务逻辑，与 ReviewScheduler 配合使用。
/// 遵循"贫血模型 + 领域服务"模式，便于测试和维护。
///
/// - Important: 此服务必须在主线程调用，因为 SwiftData Model 不是 Sendable。
///
/// ## 使用示例
///
/// ```swift
/// let service = ReviewService()
///
/// // 记录复习
/// service.recordReview(for: item, performance: .basic)
///
/// // 重置进度
/// service.resetProgress(for: item)
///
/// // 批量标记已掌握
/// service.markAsMastered(items: [item1, item2])
/// ```
@MainActor
/// 复习业务服务（主线程调用）
public struct ReviewService {
    
    private let scheduler: ReviewScheduler
    
    /// 创建复习服务（使用默认调度器）
    public init() {
        self.scheduler = ReviewScheduler()
    }
    
    /// 创建复习服务（自定义调度器）
    public init(scheduler: ReviewScheduler) {
        self.scheduler = scheduler
    }
    
    // MARK: - Record Review
    
    /// 记录一次复习
    ///
    /// - Parameters:
    ///   - item: 复习项
    ///   - performance: 复习表现
    ///   - date: 复习日期（默认当前时间）
    public func recordReview(
        for item: ReviewItemModel,
        performance: ReviewPerformance,
        on date: Date = Date()
    ) {
        recordReview(for: item, performance: performance.rawValue, on: date)
    }
    
    /// 记录一次复习（使用原始值）
    ///
    /// - Parameters:
    ///   - item: 复习项
    ///   - performance: 掌握程度 (0-4)
    ///   - date: 复习日期
    public func recordReview(
        for item: ReviewItemModel,
        performance: Int,
        on date: Date = Date()
    ) {
        let clampedPerformance = max(0, min(4, performance))
        item.masteryLevel = clampedPerformance
        item.reviewCount += 1
        item.updatedAt = date
        
        item.nextReviewDate = scheduler.calculateNextReviewDate(
            currentMastery: clampedPerformance,
            reviewCount: item.reviewCount,
            from: date
        )
    }

    /// 记录一次复习（严格校验版，超出范围会抛出错误）
    public func recordReviewValidated(
        for item: ReviewItemModel,
        performance: Int,
        on date: Date = Date()
    ) throws {
        guard (0...4).contains(performance) else {
            throw ReviewError.invalidPerformance(value: performance)
        }
        recordReview(for: item, performance: performance, on: date)
    }
    
    // MARK: - Reset Progress
    
    /// 重置复习进度
    ///
    /// - Parameter item: 复习项
    public func resetProgress(for item: ReviewItemModel) {
        item.masteryLevel = 0
        item.reviewCount = 0
        item.nextReviewDate = Date()
        item.updatedAt = Date()
    }
    
    /// 批量重置进度
    ///
    /// - Parameter items: 复习项数组
    public func resetProgress(for items: [ReviewItemModel]) {
        for item in items {
            resetProgress(for: item)
        }
    }
    
    // MARK: - Batch Operations
    
    /// 批量标记为已掌握
    ///
    /// - Parameter items: 复习项数组
    public func markAsMastered(items: [ReviewItemModel]) {
        let now = Date()
        for item in items {
            item.masteryLevel = MasteryLevel.mastered.rawValue
            item.reviewCount += 1
            item.updatedAt = now
            item.nextReviewDate = scheduler.calculateNextReviewDate(
                currentMastery: MasteryLevel.mastered.rawValue,
                reviewCount: item.reviewCount,
                from: now
            )
        }
    }
    
    /// 批量标记为需要复习
    ///
    /// - Parameter items: 复习项数组
    public func markForReview(items: [ReviewItemModel]) {
        let now = Date()
        for item in items {
            item.nextReviewDate = now
            item.updatedAt = now
        }
    }
    
    // MARK: - Query Helpers
    
    /// 获取今日待复习项
    ///
    /// - Parameters:
    ///   - items: 所有复习项
    ///   - date: 参考日期（默认当前时间，便于测试）
    /// - Returns: 今日需要复习的项
    public func itemsDueToday(from items: [ReviewItemModel], on date: Date = Date()) -> [ReviewItemModel] {
        let today = Calendar.current.startOfDay(for: date)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return items.filter { item in
            item.nextReviewDate >= today && item.nextReviewDate < tomorrow
        }
    }
    
    /// 获取逾期项
    ///
    /// - Parameters:
    ///   - items: 所有复习项
    ///   - date: 参考日期（默认当前时间，便于测试）
    /// - Returns: 已逾期的项
    public func overdueItems(from items: [ReviewItemModel], on date: Date = Date()) -> [ReviewItemModel] {
        let today = Calendar.current.startOfDay(for: date)
        return items.filter { $0.nextReviewDate < today }
    }
    
    /// 判断是否需要复习
    ///
    /// - Parameters:
    ///   - item: 复习项
    ///   - date: 参考日期（默认当前时间，便于测试）
    /// - Returns: 是否需要复习
    public func needsReview(for item: ReviewItemModel, on date: Date = Date()) -> Bool {
        item.nextReviewDate <= date
    }
    
    /// 判断是否已逾期
    ///
    /// - Parameters:
    ///   - item: 复习项
    ///   - date: 参考日期（默认当前时间，便于测试）
    /// - Returns: 是否已逾期
    public func isOverdue(for item: ReviewItemModel, on date: Date = Date()) -> Bool {
        let today = Calendar.current.startOfDay(for: date)
        return item.nextReviewDate < today
    }
    
    /// 获取已掌握项
    ///
    /// - Parameter items: 所有复习项
    /// - Returns: 已掌握的项
    public func masteredItems(from items: [ReviewItemModel]) -> [ReviewItemModel] {
        items.filter { $0.masteryLevel >= MasteryLevel.mastered.rawValue }
    }
    
    // MARK: - Statistics
    
    /// 计算掌握率
    ///
    /// - Parameter items: 复习项数组
    /// - Returns: 掌握率 (0.0 - 1.0)
    public func masteryRate(for items: [ReviewItemModel]) -> Double {
        guard !items.isEmpty else { return 0 }
        let mastered = items.filter { $0.masteryLevel >= MasteryLevel.mastered.rawValue }.count
        return Double(mastered) / Double(items.count)
    }
    
    /// 计算平均复习次数
    ///
    /// - Parameter items: 复习项数组
    /// - Returns: 平均复习次数
    public func averageReviewCount(for items: [ReviewItemModel]) -> Double {
        guard !items.isEmpty else { return 0 }
        let total = items.reduce(0) { $0 + $1.reviewCount }
        return Double(total) / Double(items.count)
    }
}

// MARK: - Shared Instance

/// ReviewService 的共享实例封装
public extension ReviewService {
    /// 共享实例
    static let shared = ReviewService()
}
