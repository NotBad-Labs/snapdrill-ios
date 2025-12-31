//
//  ReviewRepository.swift
//  NotBadData
//
//  Created by Yiming Liao on 2025/12/29.
//  Copyright © 2025 NotBad Team. All rights reserved.
//

import Foundation
import SwiftData
import NotBadCore

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
public class ReviewRepository {
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
    public func save(_ item: ReviewItem, subject: String = "其他") {
        let model = ReviewItemModel(
            id: item.id,
            content: item.content,
            imagePath: item.imagePath,
            createdAt: item.createdAt,
            lastReviewedAt: item.lastReviewedAt,
            nextReviewAt: item.nextReviewAt,
            subject: subject,
            source: item.source,
            tags: [], // Tags handling needs improvement in Repository if used
            answerText: item.answerText,
            answerImagePath: item.answerImagePath,
            difficulty: item.difficulty,
            grade: item.grade
        )
        modelContext.insert(model)
        // Auto-save logic if needed, or rely on autosave
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
    
    /// 删除条目
    public func delete(_ model: ReviewItemModel) {
        modelContext.delete(model)
    }
}
