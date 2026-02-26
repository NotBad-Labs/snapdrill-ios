//
//  ReviewSessionManager.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  复习会话的数据与业务逻辑管理器，隔离 ViewModel 与底层 Repository 的直接耦合。
//

import Foundation
import SnapDrillCore
import SnapDrillData

@MainActor
public protocol ReviewSessionManagerProtocol {
    /// 加载今日待复习条目
    func loadDueItems() throws -> [ReviewItemModel]
    
    /// 获取今日已复习数量
    func loadTodayReviewedCount() throws -> Int
    
    /// 获取题库总数
    func loadTotalItemsCount() throws -> Int
    
    /// 处理卡片滑动结果（SM-2 调度并保存）
    func processSwipeResult(for item: ReviewItemModel, rating: ReviewRating) throws
    
    /// 保存任何其他挂起的更改
    func saveChanges() throws
}

@MainActor
public final class ReviewSessionManager: ReviewSessionManagerProtocol {
    
    private let repository: ReviewRepositoryProtocol
    private let scheduler: ReviewScheduler
    
    // MARK: - Initialization
    
    public init(
        repository: ReviewRepositoryProtocol,
        scheduler: ReviewScheduler = ReviewScheduler()
    ) {
        self.repository = repository
        self.scheduler = scheduler
    }
    
    // MARK: - Public API
    
    public func loadDueItems() throws -> [ReviewItemModel] {
        return try repository.fetchDueItems()
    }
    
    public func loadTodayReviewedCount() throws -> Int {
        return try repository.fetchTodayReviewedCount()
    }
    
    public func loadTotalItemsCount() throws -> Int {
        return try repository.totalItemCount()
    }
    
    public func processSwipeResult(for item: ReviewItemModel, rating: ReviewRating) throws {
        // 使用引擎计算下一次时间
        let entity = item.toEntity()
        let updatedEntity = scheduler.scheduleNextReview(for: entity, rating: rating)
        
        // 更新模型
        item.lastReviewedAt = updatedEntity.lastReviewedAt
        item.nextReviewAt = updatedEntity.nextReviewAt
        item.easeFactor = updatedEntity.easeFactor
        item.interval = updatedEntity.interval
        item.repetitions = updatedEntity.repetitions
        
        // 保存到数据库
        try repository.save()
    }
    
    public func saveChanges() throws {
        try repository.save()
    }
}
