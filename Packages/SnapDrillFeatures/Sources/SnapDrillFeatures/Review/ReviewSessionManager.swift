//
//  ReviewSessionManager.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  复习会话的数据与业务逻辑管理器，隔离 ViewModel 与底层 Repository 的直接耦合。
//

import Foundation
import SnapDrillCore
import SnapDrillData
import SnapDrillDomain

@MainActor
public protocol ReviewSessionManagerProtocol {
    /// 加载今日待复习条目
    func loadDueItems() throws -> [ReviewItem]
    
    /// 获取今日已复习数量
    func loadTodayReviewedCount() throws -> Int
    
    /// 获取题库总数
    func loadTotalItemsCount() throws -> Int
    
    /// 处理卡片滑动结果（SM-2 调度并保存）
    func processSwipeResult(for item: ReviewItem, rating: ReviewRating) throws
}

@MainActor
public final class ReviewSessionManager: ReviewSessionManagerProtocol {
    
    private let useCase: ReviewUseCaseProtocol
    
    // MARK: - Initialization
    
    public init(useCase: ReviewUseCaseProtocol) {
        self.useCase = useCase
    }
    
    // MARK: - Public API
    
    public func loadDueItems() throws -> [ReviewItem] {
        return try useCase.getDueItems()
    }
    
    public func loadTodayReviewedCount() throws -> Int {
        return try useCase.getTodayReviewedCount()
    }
    
    public func loadTotalItemsCount() throws -> Int {
        return try useCase.getTotalItemCount()
    }
    
    public func processSwipeResult(for item: ReviewItem, rating: ReviewRating) throws {
        // 下推业务逻辑至 UseCase
        try useCase.submitReviewResult(id: item.id, rating: rating)
    }
}
