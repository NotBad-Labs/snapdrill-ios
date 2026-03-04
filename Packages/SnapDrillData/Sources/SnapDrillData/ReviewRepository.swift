//
//  ReviewRepository.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  复习条目的 SwiftData 仓库实现，提供 CRUD、SM-2 调度辅助及分页查询。
//

import Foundation
import SwiftData
import SnapDrillCore

/// 复习数据仓库的 SwiftData 实现
@MainActor
public final class ReviewRepository {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public API

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

    public func fetchDueCount() throws -> Int {
        let now = Date.now
        // #Predicate 对 Optional<Date> 的 force-unwrap 在当前 SwiftData 版本中
        // SQLite 转译行为不可靠，改为全量 fetch 后内存过滤，确保结果正确。
        let all = try modelContext.fetch(FetchDescriptor<ReviewItemModel>())
        return all.filter { item in
            guard let date = item.nextReviewAt else { return true }
            return date <= now
        }.count
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
        // 同 fetchDueCount，避免 #Predicate + Optional force-unwrap 的转译问题。
        let all = try modelContext.fetch(FetchDescriptor<ReviewItemModel>())
        return all.filter { item in
            guard let date = item.lastReviewedAt else { return false }
            return date >= startOfToday
        }.count
    }

    public func totalItemCount() throws -> Int {
        try totalCount()
    }

    // MARK: - Model-Tier API（直接返回 @Model，供 Features ViewModel 使用）

    /// 获取所有待复习条目的 SwiftData 模型
    public func fetchDueModels() throws -> [ReviewItemModel] {
        let now = Date.now
        // #Predicate 对 Optional<Date> 的 force-unwrap 在当前 SwiftData 版本中
        // SQLite 转译行为不可靠（nilnil 条目能正确命中，但非 nil 的过期日期无法命中），
        // 改为全量 fetch 后内存过滤，彻底规避该 bug。
        let all = try modelContext.fetch(
            FetchDescriptor<ReviewItemModel>(sortBy: [SortDescriptor(\.createdAt, order: .forward)])
        )
        return all.filter { item in
            guard let date = item.nextReviewAt else { return true }
            return date <= now
        }
    }

    /// 按 ID 获取单个 ReviewItemModel
    public func fetchModel(by id: UUID) throws -> ReviewItemModel? {
        try fetchModelById(id)
    }

    /// 按多个 ID 获取 ReviewItemModel 列表
    public func fetchModels(by ids: Set<UUID>) throws -> [ReviewItemModel] {
        let targetIds = Array(ids)
        let predicate = #Predicate<ReviewItemModel> { item in
            targetIds.contains(item.id)
        }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }

    /// 全量获取所有 ReviewItemModel
    public func fetchAllModels() throws -> [ReviewItemModel] {
        let descriptor = FetchDescriptor<ReviewItemModel>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    /// 按筛选条件分页获取 ReviewItemModel
    public func fetchFilteredModels(
        searchText: String,
        subjects: Set<String>,
        tags: Set<String>,
        limit: Int,
        offset: Int
    ) throws -> [ReviewItemModel] {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let subjectsArray = Array(subjects)

        // swiftlint:disable force_unwrapping
        let predicate = #Predicate<ReviewItemModel> { item in
            (normalizedSearch.isEmpty || (item.content != nil && item.content!.localizedStandardContains(normalizedSearch))) &&
            (subjectsArray.isEmpty || subjectsArray.contains(item.subjectRawValue))
        }
        // swiftlint:enable force_unwrapping

        var descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset

        let models = try modelContext.fetch(descriptor)

        if !tags.isEmpty {
            return models.filter { model in
                let itemTagNames = Set((model.tags ?? []).map { $0.name })
                return !itemTagNames.isDisjoint(with: tags)
            }
        }

        return models
    }

    /// 直接插入 ReviewItemModel 并保存
    public func insertAndSave(_ model: ReviewItemModel) throws {
        modelContext.insert(model)
        try modelContext.save()
    }

    /// 保存 ModelContext（直接修改 @Model 属性后调用）
    public func saveContext() throws {
        try modelContext.save()
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

}
