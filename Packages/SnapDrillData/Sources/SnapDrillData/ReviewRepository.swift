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
public final class ReviewRepository {
    
    // MARK: - Properties

    private let modelContext: ModelContext
    private let imageStorageFactory: (() -> ImageStorage)?

    // MARK: - Initialization

    /// 创建复习数据仓库（推荐路径）
    /// - Parameters:
    ///   - executor: DataExecutor，从其 mainContext 获取 SwiftData 上下文
    ///   - imageStorageFactory: 可选的 ImageStorage 工厂闭包（用于 Profile 隔离的图片删除）
    public init(executor: DataExecutor, imageStorageFactory: (() -> ImageStorage)? = nil) {
        self.modelContext = executor.container.mainContext
        self.imageStorageFactory = imageStorageFactory
    }

    /// 创建复习数据仓库（向后兼容，Phase 2 移除）
    /// - Parameter modelContext: 当前上下文
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.imageStorageFactory = nil
    }
    
    // MARK: - Public API

    /// 返回数据库中所有题目总数
    /// - Throws: SwiftData fetch 错误
    public func totalCount() throws -> Int {
        let descriptor = FetchDescriptor<ReviewItemModel>()
        return try modelContext.fetchCount(descriptor)
    }
    
    /// 删除指定题目及其关联图片文件
    /// - Parameter id: 要删除的题目 UUID
    /// - Throws: 图片删除或数据库 save 失败时抛出
    /// - Note: async 是因为内部包含文件 I/O（删除图片），避免阻塞主线程
    public func delete(id: UUID) async throws {
        guard let model = try fetchModelById(id) else { return }
        // 先保存路径再删 DB，确保 DB 操作成功后才清理图片文件；
        // 如果先删图片再 save DB 失败，会出现 DB 记录在但图片已删的孤儿状态
        let imagePath = model.imagePath
        let answerImagePath = model.answerImagePath
        modelContext.delete(model)
        try modelContext.save()
        // DB 删除成功后清理图片文件（best-effort：文件删除失败不影响数据一致性）
        let imageStorage = imageStorageFactory?() ?? ImageStorage(baseDirectory: FileManager.default.temporaryDirectory)
        if let path = imagePath {
            do {
                try await imageStorage.deleteImage(path: path)
            } catch {
                // best-effort: 图片清理失败不回滚 DB，仅记录便于排查孤儿文件
                SnapDrillLogger.data.warning("图片清理失败（\(path)）: \(error.localizedDescription)")
            }
        }
        if let path = answerImagePath {
            do {
                try await imageStorage.deleteImage(path: path)
            } catch {
                SnapDrillLogger.data.warning("答案图清理失败（\(path)）: \(error.localizedDescription)")
            }
        }
    }
    
    /// 返回指定学科的题目数量
    /// - Parameter name: 学科名称
    /// - Throws: SwiftData fetch 错误
    public func countBySubject(name: String) throws -> Int {
        let targetName = name
        let predicate = #Predicate<ReviewItemModel> { $0.subjectRawValue == targetName }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }
    
    /// 将所有题目的 subjectRawValue 从旧名改为新名（纯内存操作，调用方负责 saveContext）
    public func updateSubjectUsage(from oldName: String, to newName: String) throws {
        let targetOldName = oldName
        let predicate = #Predicate<ReviewItemModel> { $0.subjectRawValue == targetOldName }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        let itemsToUpdate = try modelContext.fetch(descriptor)
        for item in itemsToUpdate {
            item.subjectRawValue = newName
        }
    }
    
    /// 返回指定来源的题目数量
    /// - Parameter name: 来源名称
    /// - Throws: SwiftData fetch 错误
    public func countBySource(name: String) throws -> Int {
        let targetName = name
        let predicate = #Predicate<ReviewItemModel> { $0.sourceRawValue == targetName }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }
    
    /// 将所有题目的 sourceRawValue 从旧名改为新名（纯内存操作，调用方负责 saveContext）
    public func updateSourceUsage(from oldName: String, to newName: String) throws {
        let targetOldName = oldName
        let predicate = #Predicate<ReviewItemModel> { $0.sourceRawValue == targetOldName }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        let itemsToUpdate = try modelContext.fetch(descriptor)
        for item in itemsToUpdate {
            item.sourceRawValue = newName
        }
    }
    
    /// 返回指定年级的题目数量
    /// - Parameter name: 年级名称
    /// - Throws: SwiftData fetch 错误
    public func countByGrade(name: String) throws -> Int {
        let targetName = name
        let predicate = #Predicate<ReviewItemModel> { $0.grade == targetName }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }

    /// 将所有题目的 grade 从旧名改为新名（纯内存操作，调用方负责 saveContext）
    public func updateGradeUsage(from oldName: String, to newName: String) throws {
        let targetOldName = oldName
        let predicate = #Predicate<ReviewItemModel> { $0.grade == targetOldName }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        let itemsToUpdate = try modelContext.fetch(descriptor)
        for item in itemsToUpdate {
            item.grade = newName
        }
    }

    /// 收集所有题目的图片路径，供调用方在 saveContext 成功后清理磁盘文件
    public func collectAllImagePaths() throws -> [String] {
        let allModels = try fetchAllModels()
        var paths: [String] = []
        for model in allModels {
            if let path = model.imagePath { paths.append(path) }
            if let path = model.answerImagePath { paths.append(path) }
        }
        return paths
    }

    /// 纯内存操作：将所有题目标记为待删除。调用方负责 saveContext()，
    /// saveContext 成功后再调用 ImageStorage.deleteImage 清理图片文件。
    public func deleteAll() throws {
        try modelContext.delete(model: ReviewItemModel.self)
    }

    // MARK: - Performance-Optimized Query Methods

    /// 返回当前到期待复习的题目数量
    /// - Throws: SwiftData fetch 错误
    public func fetchDueCount() throws -> Int {
        let now = Date.now
        // nextReviewAt 为非可选 Date（默认 distantPast = 立即到期），
        // 可直接使用 #Predicate 让 SQLite 完成过滤，避免全表扫描内存炸弹。
        let predicate = #Predicate<ReviewItemModel> { $0.nextReviewAt <= now }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }

    /// 返回今日新增的题目数量
    /// - Throws: SwiftData fetch 错误
    public func fetchTodayCount() throws -> Int {
        let startOfToday = Calendar.current.startOfDay(for: Date.now)
        let predicate = #Predicate<ReviewItemModel> { item in
            item.createdAt >= startOfToday
        }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }

    /// 返回今日已复习的题目数量
    /// - Throws: SwiftData fetch 错误
    public func fetchTodayReviewedCount() throws -> Int {
        let startOfToday = Calendar.current.startOfDay(for: Date.now)
        // lastReviewedAt 为非可选 Date（distantPast 表示从未复习），
        // distantPast < startOfToday，自动排除未复习条目，可直接使用数据库级过滤。
        let predicate = #Predicate<ReviewItemModel> { item in
            item.lastReviewedAt >= startOfToday
        }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }

    /// 返回数据库中所有题目总数（`totalCount()` 的别名）
    /// - Throws: SwiftData fetch 错误
    public func totalItemCount() throws -> Int {
        try totalCount()
    }

    // MARK: - Smart Selection（智能选题，供组卷排版打印使用）

    /// 基于 SM-2 紧迫度智能选题：优先选逾期和不熟练的题目
    ///
    /// 排序策略：nextReviewAt ASC（越早到期越优先）→ repetitions ASC（越不熟练越优先）。
    /// `nextReviewAt == .distantPast` 表示从未复习，排在最前面。
    /// - Parameters:
    ///   - limit: 最大选题数量
    ///   - subjects: 学科筛选（空 = 不限）
    ///   - difficulties: 难度筛选（空 = 不限）
    /// - Returns: 按紧迫度排序的题目列表
    public func fetchSmartSelection(
        limit: Int,
        subjects: Set<String> = [],
        difficulties: Set<Int> = []
    ) throws -> [ReviewItemModel] {
        let subjectsArray = Array(subjects)
        let difficultiesArray = Array(difficulties)

        let predicate = #Predicate<ReviewItemModel> { item in
            (subjectsArray.isEmpty || subjectsArray.contains(item.subjectRawValue)) &&
            (difficultiesArray.isEmpty || difficultiesArray.contains(item.difficulty))
        }

        var descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\.nextReviewAt, order: .forward),
                SortDescriptor(\.repetitions, order: .forward)
            ]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Model-Tier API（直接返回 @Model，供 Features ViewModel 使用）

    /// 获取所有待复习条目的 SwiftData 模型
    public func fetchDueModels() throws -> [ReviewItemModel] {
        let now = Date.now
        // nextReviewAt 为非可选 Date（distantPast 表示立即到期），
        // 可直接使用 #Predicate 让 SQLite 完成过滤，避免全表扫描内存炸弹。
        let predicate = #Predicate<ReviewItemModel> { $0.nextReviewAt <= now }
        let descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
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
    ///
    /// - 无 tag 过滤：使用数据库级分页（高效路径）
    /// - 有 tag 过滤：全量加载 search+subject 匹配项后内存过滤 tag，再按 offset/limit 切片。
    ///   SwiftData #Predicate 不支持 many-to-many 关联查询，必须内存端处理；
    ///   使用数据库 fetchLimit + 内存 tag 过滤会导致分页数量不可控，用户"找不到"已有题目。
    public func fetchFilteredModels(
        searchText: String,
        subjects: Set<String>,
        tags: Set<String>,
        difficulties: Set<Int> = [],
        sortDescriptors: [SortDescriptor<ReviewItemModel>] = [SortDescriptor(\ReviewItemModel.createdAt, order: .reverse)],
        limit: Int,
        offset: Int
    ) throws -> [ReviewItemModel] {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let subjectsArray = Array(subjects)
        let difficultiesArray = Array(difficulties)

        // #Predicate 内禁止 force unwrap（! 在 SQLite 转译语义未定义）；
        // 用可选链 ?.localizedStandardContains == true 替代，行为等价且安全。
        let predicate = #Predicate<ReviewItemModel> { item in
            (normalizedSearch.isEmpty || item.content?.localizedStandardContains(normalizedSearch) == true) &&
            (subjectsArray.isEmpty || subjectsArray.contains(item.subjectRawValue)) &&
            (difficultiesArray.isEmpty || difficultiesArray.contains(item.difficulty))
        }

        if tags.isEmpty {
            // 无 tag 过滤：直接使用数据库分页
            var descriptor = FetchDescriptor<ReviewItemModel>(
                predicate: predicate,
                sortBy: sortDescriptors
            )
            descriptor.fetchLimit = limit
            descriptor.fetchOffset = offset
            return try modelContext.fetch(descriptor)
        } else {
            // 有 tag 过滤：全量拉取 search+subject 匹配项，内存过滤 tag，再切片分页
            let descriptor = FetchDescriptor<ReviewItemModel>(
                predicate: predicate,
                sortBy: sortDescriptors
            )
            let allMatching = try modelContext.fetch(descriptor)
            let tagFiltered = allMatching.filter { model in
                let itemTagNames = Set((model.tags ?? []).map { $0.name })
                return !itemTagNames.isDisjoint(with: tags)
            }
            guard offset < tagFiltered.count else { return [] }
            return Array(tagFiltered[offset..<min(offset + limit, tagFiltered.count)])
        }
    }

    /// 纯内存操作：将 ReviewItemModel 插入 context 但不 save。
    /// 调用方在所有内存操作完成后统一调用 saveContext()，失败时 rollbackContext() 清除脏数据。
    public func insert(_ model: ReviewItemModel) {
        modelContext.insert(model)
    }

    /// 插入 ReviewItemModel 并立即保存（单步原子操作，适用于独立保存场景）
    public func insertAndSave(_ model: ReviewItemModel) throws {
        modelContext.insert(model)
        try modelContext.save()
    }

    /// 保存 ModelContext（直接修改 @Model 属性后调用）
    public func saveContext() throws {
        try modelContext.save()
    }

    /// 回滚 ModelContext 中所有未持久化的变更（saveContext 失败时调用）
    public func rollbackContext() {
        modelContext.rollback()
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
