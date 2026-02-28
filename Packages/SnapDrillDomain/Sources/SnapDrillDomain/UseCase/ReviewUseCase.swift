//
//  ReviewUseCase.swift
//  SnapDrillDomain
//
//  Created by NotBad Labs on 2026/02/27.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  实现 ReviewUseCaseProtocol，处理题目的增删改查与复习调度。
//

import Foundation
import SnapDrillCore

/// 复习业务逻辑的默认实现
@MainActor
public final class ReviewUseCase: ReviewUseCaseProtocol {
    
    private let repository: ReviewRepositoryProtocol
    private let scheduler: ReviewScheduler = ReviewScheduler()
    
    public init(repository: ReviewRepositoryProtocol) {
        self.repository = repository
    }
    
    public func getDueItems() throws -> [ReviewItem] {
        try repository.fetchDueItems()
    }
    
    public func getDueCount() throws -> Int {
        try repository.fetchDueCount()
    }
    
    public func getTodayAddedCount() throws -> Int {
        try repository.fetchTodayCount()
    }
    
    public func getTotalItemCount() throws -> Int {
        try repository.totalItemCount()
    }
    
    public func getTodayReviewedCount() throws -> Int {
        try repository.fetchTodayReviewedCount()
    }
    
    public func captureNewItem(_ item: ReviewItem) throws {
        // 业务规则：题目文字和图片至少有一个
        guard item.content != nil || item.imagePath != nil else {
            throw DomainError.invalidContent
        }
        try repository.save(item)
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
    }

    public func updateItem(_ item: ReviewItem) throws {
        // 业务规则：题目文字和图片至少有一个
        guard item.content != nil || item.imagePath != nil else {
            throw DomainError.invalidContent
        }
        try repository.save(item)
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
    }
    
    public func submitReviewResult(id: UUID, rating: ReviewRating) throws {
        guard let item = try repository.fetchById(id) else {
            SnapDrillLogger.generic.warning("尝试复习不存在的条目: \(id)")
            return
        }

        // 使用核心调度引擎计算
        let updatedItem = scheduler.scheduleNextReview(for: item, rating: rating)

        // 持久化更新
        try repository.save(updatedItem)
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
    }
    
    public func searchLibrary(
        query: String,
        subjects: Set<String>,
        tags: Set<String>,
        page: Int,
        pageSize: Int
    ) throws -> [ReviewItem] {
        let offset = page * pageSize
        return try repository.fetchFiltered(
            searchText: query,
            subjects: subjects,
            tags: tags,
            limit: pageSize,
            offset: offset
        )
    }

    public func deleteItem(id: UUID) throws {
        try repository.delete(id: id)
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
    }

    public func deleteAllData() throws {
        try repository.deleteAll()
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
    }
    
    public func fetchAllItems() throws -> [ReviewItem] {
        try repository.fetchAll()
    }
    
    public func fetchItemsByIds(_ ids: Set<UUID>) throws -> [ReviewItem] {
        try repository.fetchByIds(ids)
    }
}
