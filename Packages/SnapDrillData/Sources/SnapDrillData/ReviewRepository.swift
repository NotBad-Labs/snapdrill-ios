//
//  ReviewRepository.swift
//  SnapDrillData
//
//  Created by SnapDrill Labs on 2025/12/30.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  错题数据的增删改查仓库，封装 SwiftData 上下文操作。
//

import Foundation
import SwiftData
import SnapDrillCore

/// 复习数据仓库
///
/// 封装了基于 SwiftData 的 CRUD 操作，对外提供简洁的数据访问接口。
///
/// ## 职责
/// - **隔离**: 隐藏 `ModelContext` 和 `FetchDescriptor` 的复杂性。
/// - **转换**: 处理 `ReviewItem` (Core) 到 `ReviewItemModel` (Data) 的转换（虽目前通过外部转换，但逻辑属于此层）。
///
/// - Important: 此类必须在 `@MainActor` 线程上使用，因为 SwiftData 的 `ModelContext` 通常绑定在主线程。
@MainActor
public class ReviewRepository: ReviewRepositoryProtocol {
    private let modelContext: ModelContext
    
    /// 初始化仓库
    /// - Parameter modelContext: SwiftData 上下文，通常来自 `PersistenceController.shared.container.mainContext`
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// 保存新的复习条目
    ///
    /// 将 Core 层的 `ReviewItem` 创建并插入到数据库。
    /// - Parameters:
    ///   - item: 核心条目数据
    ///   - subject: 学科分类（临时参数，未来应包含在 item 中）
    /// - Throws: `DataError.duplicateItem` 如果 ID 已存在
    public func save(_ item: ReviewItem, subject: String = "其他") throws {
        // 检查唯一性
        if let existing = try? fetchById(item.id), existing != nil {
            throw DataError.duplicateItem(id: item.id)
        }
        
        let model = ReviewItemModel(
            id: item.id,
            content: item.content,
            imagePath: item.imagePath,
            createdAt: item.createdAt,
            lastReviewedAt: item.lastReviewedAt,
            nextReviewAt: item.nextReviewAt,
            subject: subject,
            source: item.source,
            tags: [],
            answerText: item.answerText,
            answerImagePath: item.answerImagePath,
            difficulty: item.difficulty,
            grade: item.grade
        )
        modelContext.insert(model)
    }
    
    /// 获取所有复习条目
    public func fetchAll() throws -> [ReviewItemModel] {
        let descriptor = FetchDescriptor<ReviewItemModel>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取待复习条目数量
    /// - Returns: `nextReviewAt` 早于或等于当前时间的条目数
    public func fetchDueCount() throws -> Int {
        let now = Date()
        let descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: #Predicate<ReviewItemModel> { item in
                // swiftlint:disable:next force_unwrapping
                item.nextReviewAt != nil && item.nextReviewAt! <= now
            }
        )
        return try modelContext.fetchCount(descriptor)
    }
    
    /// 获取总条目数量
    public func totalItemCount() throws -> Int {
        let descriptor = FetchDescriptor<ReviewItemModel>()
        return try modelContext.fetchCount(descriptor)
    }
    
    /// 根据 ID 查找条目
    /// - Parameter id: 条目 ID
    /// - Returns: 找到的条目，如果不存在则返回 nil
    public func fetchById(_ id: UUID) throws -> ReviewItemModel? {
        let descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: #Predicate<ReviewItemModel> { item in
                item.id == id
            }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    /// 更新条目
    /// - Parameter item: 要更新的条目
    /// - Throws: `DataError.notFound` 如果条目不存在
    public func update(_ item: ReviewItem) throws {
        guard let existing = try fetchById(item.id) else {
            throw DataError.notFound(id: item.id, entityType: "ReviewItem")
        }
        
        // 更新字段
        existing.content = item.content
        existing.imagePath = item.imagePath
        existing.lastReviewedAt = item.lastReviewedAt
        existing.nextReviewAt = item.nextReviewAt
        existing.answerText = item.answerText
        existing.answerImagePath = item.answerImagePath
        existing.difficulty = item.difficulty
        existing.grade = item.grade
        existing.easeFactor = item.easeFactor
        existing.interval = item.interval
        existing.repetitions = item.repetitions
    }
    
    /// 删除条目
    public func delete(_ model: ReviewItemModel) {
        modelContext.delete(model)
    }
    
    /// 保存上下文更改
    public func save() throws {
        try modelContext.save()
    }
}
