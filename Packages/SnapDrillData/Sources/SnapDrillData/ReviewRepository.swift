//
//  ReviewRepository.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  实现 ReviewRepositoryProtocol，基于 SwiftData 持久化复习条目。
//

import Foundation
import SwiftData
import SnapDrillCore
import SnapDrillDomain

/// 复习数据仓库的 SwiftData 实现
///
/// 职责：
/// - 实现 `ReviewRepositoryProtocol`，使用领域实体 `ReviewItem` 进行通信。
/// - 执行 SwiftData 的 CRUD 操作。
/// - 负责 `ReviewItem` (Domain) 与 `ReviewItemModel` (Data) 之间的映射转换。
@MainActor
public final class ReviewRepository: ReviewRepositoryProtocol {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - ReviewRepositoryProtocol
    
    public func save(_ item: ReviewItem) throws {
        if let existing = try fetchModelById(item.id) {
            // 更新现有模型
            try updateModel(existing, from: item)
        } else {
            // 创建新模型，解析并关联 TagModel
            let tagModels = try item.tags.map { try fetchOrCreateTagModel(name: $0) }
            let model = ReviewItemModel(
                id: item.id,
                content: item.content,
                imagePath: item.imagePath,
                createdAt: item.createdAt,
                lastReviewedAt: item.lastReviewedAt,
                nextReviewAt: item.nextReviewAt,
                subject: item.subject,
                source: item.source,
                tags: tagModels,
                answerText: item.answerText,
                answerImagePath: item.answerImagePath,
                difficulty: item.difficulty.rawValue,
                grade: item.grade,
                easeFactor: item.easeFactor,
                interval: item.interval,
                repetitions: item.repetitions
            )
            modelContext.insert(model)
        }
        try modelContext.save()
    }
    
    public func fetchById(_ id: UUID) throws -> ReviewItem? {
        try fetchModelById(id)?.toEntity()
    }
    
    public func fetchByIds(_ ids: Set<UUID>) throws -> [ReviewItem] {
        let targetIds = Array(ids)
        let predicate = #Predicate<ReviewItemModel> { item in
            targetIds.contains(item.id)
        }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }
    
    public func fetchAll() throws -> [ReviewItem] {
        let descriptor = FetchDescriptor<ReviewItemModel>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }
    
    public func fetchFiltered(
        searchText: String,
        subjects: Set<String>,
        tags: Set<String>,
        limit: Int,
        offset: Int
    ) throws -> [ReviewItem] {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let subjectsArray = Array(subjects)
        
        let predicate = #Predicate<ReviewItemModel> { item in
            (normalizedSearch.isEmpty || (item.content ?? "").localizedStandardContains(normalizedSearch)) &&
            (subjectsArray.isEmpty || subjectsArray.contains(item.subjectRawValue))
        }
        
        var descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        
        let models = try modelContext.fetch(descriptor)
        
        // 内存端过滤标签（SwiftData 目前对多对多 Predicate 支持有限）
        if !tags.isEmpty {
            return models.filter { model in
                let itemTagNames = Set((model.tags ?? []).map { $0.name })
                return !itemTagNames.isDisjoint(with: tags)
            }.map { $0.toEntity() }
        }
        
        return models.map { $0.toEntity() }
    }
    
    public func totalCount() throws -> Int {
        let descriptor = FetchDescriptor<ReviewItemModel>()
        return try modelContext.fetchCount(descriptor)
    }
    
    public func delete(id: UUID) throws {
        if let model = try fetchModelById(id) {
            modelContext.delete(model)
            try modelContext.save()
        }
    }
    
    public func countBySubject(name: String) throws -> Int {
        let targetName = name
        let predicate = #Predicate<ReviewItemModel> { $0.subjectRawValue == targetName }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }
    
    public func updateSubjectUsage(from oldName: String, to newName: String) throws {
        let targetOldName = oldName
        let predicate = #Predicate<ReviewItemModel> { $0.subjectRawValue == targetOldName }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        let itemsToUpdate = try modelContext.fetch(descriptor)
        
        for item in itemsToUpdate {
            item.subjectRawValue = newName
        }
        try modelContext.save()
    }
    
    public func countBySource(name: String) throws -> Int {
        let targetName = name
        let predicate = #Predicate<ReviewItemModel> { $0.sourceRawValue == targetName }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }
    
    public func updateSourceUsage(from oldName: String, to newName: String) throws {
        let targetOldName = oldName
        let predicate = #Predicate<ReviewItemModel> { $0.sourceRawValue == targetOldName }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        let itemsToUpdate = try modelContext.fetch(descriptor)
        
        for item in itemsToUpdate {
            item.sourceRawValue = newName
        }
        try modelContext.save()
    }
    
    public func countByGrade(name: String) throws -> Int {
        let targetName = name
        let predicate = #Predicate<ReviewItemModel> { $0.grade == targetName }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }

    public func updateGradeUsage(from oldName: String, to newName: String) throws {
        let targetOldName = oldName
        let predicate = #Predicate<ReviewItemModel> { $0.grade == targetOldName }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        let itemsToUpdate = try modelContext.fetch(descriptor)

        for item in itemsToUpdate {
            item.grade = newName
        }
        try modelContext.save()
    }

    public func deleteAll() throws {
        try modelContext.delete(model: ReviewItemModel.self)
        try modelContext.save()
    }

    // MARK: - Performance-Optimized Query Methods

    public func fetchDueItems() throws -> [ReviewItem] {
        let now = Date.now
        // nil coalescing: 从未复习（nil）→ epoch <= now → true（属于待复习）
        let epoch = Date(timeIntervalSince1970: 0)
        let predicate = #Predicate<ReviewItemModel> { item in
            (item.nextReviewAt ?? epoch) <= now
        }
        let descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    public func fetchDueCount() throws -> Int {
        let now = Date.now
        let epoch = Date(timeIntervalSince1970: 0)
        let predicate = #Predicate<ReviewItemModel> { item in
            (item.nextReviewAt ?? epoch) <= now
        }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }

    public func fetchTodayCount() throws -> Int {
        let startOfToday = Calendar.current.startOfDay(for: Date.now)
        let predicate = #Predicate<ReviewItemModel> { item in
            item.createdAt >= startOfToday
        }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }

    public func fetchTodayReviewedCount() throws -> Int {
        let startOfToday = Calendar.current.startOfDay(for: Date.now)
        // nil coalescing: 从未复习（nil）→ epoch >= startOfToday → false
        let epoch = Date(timeIntervalSince1970: 0)
        let predicate = #Predicate<ReviewItemModel> { item in
            (item.lastReviewedAt ?? epoch) >= startOfToday
        }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }

    public func totalItemCount() throws -> Int {
        try totalCount()
    }

    // MARK: - Private Helpers

    /// 内部获取 SwiftData 模型，带性能优化
    private func fetchModelById(_ id: UUID) throws -> ReviewItemModel? {
        let targetId = id
        let predicate = #Predicate<ReviewItemModel> { item in
            item.id == targetId
        }
        var descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        descriptor.fetchLimit = 1 // P0 优化：确保只取一条，防止全表扫描
        return try modelContext.fetch(descriptor).first
    }

    /// 按 name 查找已有 TagModel，若不存在则创建并插入
    private func fetchOrCreateTagModel(name: String) throws -> TagModel {
        let targetName = name
        let predicate = #Predicate<TagModel> { $0.name == targetName }
        var descriptor = FetchDescriptor<TagModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        let newTag = TagModel(name: name)
        modelContext.insert(newTag)
        return newTag
    }

    private func updateModel(_ model: ReviewItemModel, from item: ReviewItem) throws {
        model.content = item.content
        model.imagePath = item.imagePath
        model.lastReviewedAt = item.lastReviewedAt
        model.nextReviewAt = item.nextReviewAt
        model.subjectRawValue = item.subject
        model.sourceRawValue = item.source
        model.tags = try item.tags.map { try fetchOrCreateTagModel(name: $0) }
        model.answerText = item.answerText
        model.answerImagePath = item.answerImagePath
        model.difficulty = item.difficulty.rawValue
        model.grade = item.grade
        model.easeFactor = item.easeFactor
        model.interval = item.interval
        model.repetitions = item.repetitions
    }
}
