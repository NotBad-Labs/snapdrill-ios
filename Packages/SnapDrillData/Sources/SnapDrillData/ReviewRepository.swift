//
//  ReviewRepository.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
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
        do {
            try modelContext.save()
        } catch {
            // save 失败必须回滚，否则脏 delete 标记留在共享 mainContext，
            // 下次任意无关 save 会误提交这次删除（审计 #5）
            rollbackContext()
            throw error
        }
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
    
    // L3：countBySubject/Source/Grade + updateXxxUsage 已删（旧裸字符串字段去除）。
    // 维度值的引用计数走 CategoryValueModel.items?.count；重命名直接改 value.name（关系自动跟随）。

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
    public func fetchDueCount(excluding ids: Set<UUID> = []) throws -> Int {
        let now = Date.now
        // nextReviewAt 为非可选 Date（默认 distantPast = 立即到期），
        // 可直接使用 #Predicate 让 SQLite 完成过滤，避免全表扫描内存炸弹。
        let predicate = #Predicate<ReviewItemModel> { $0.nextReviewAt <= now }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        // 无待删除时走 SQLite COUNT 快路径；有待删除（5 秒撤销窗口的软删题）时
        // fetchCount 无法按 id 集合过滤，回退到取模型后内存排除（pending 数极小）。
        if ids.isEmpty {
            return try modelContext.fetchCount(descriptor)
        }
        return try modelContext.fetch(descriptor).filter { !ids.contains($0.id) }.count
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
        subjectValueIds: Set<UUID> = [],
        difficulties: Set<Int> = [],
        excluding ids: Set<UUID> = []
    ) throws -> [ReviewItemModel] {
        let difficultiesArray = Array(difficulties)

        // difficulty 走 DB #Predicate；学科是维度值（many-to-many）只能内存过滤，保持 SM-2 紧迫度排序后再截断
        let predicate = #Predicate<ReviewItemModel> { item in
            difficultiesArray.isEmpty || difficultiesArray.contains(item.difficulty)
        }

        var descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\.nextReviewAt, order: .forward),
                SortDescriptor(\.repetitions, order: .forward)
            ]
        )

        // 无学科过滤且无待删除排除时走 DB fetchLimit 快路径；
        // 一旦需要内存排除（pending 软删题），必须先取全量再排除/截断——
        // 否则 fetchLimit 会在排除前截断导致少选。
        if subjectValueIds.isEmpty && ids.isEmpty {
            descriptor.fetchLimit = limit
            return try modelContext.fetch(descriptor)
        }

        let all = try modelContext.fetch(descriptor)
        let filtered = all.filter { item in
            !ids.contains(item.id) &&
            (subjectValueIds.isEmpty ||
             !Set((item.categoryValues ?? []).map { $0.id }).isDisjoint(with: subjectValueIds))
        }
        return Array(filtered.prefix(limit))
    }

    // MARK: - Model-Tier API（直接返回 @Model，供 Features ViewModel 使用）

    /// 获取所有待复习条目的 SwiftData 模型
    public func fetchDueModels(excluding ids: Set<UUID> = []) throws -> [ReviewItemModel] {
        let now = Date.now
        // nextReviewAt 为非可选 Date（distantPast 表示立即到期），
        // 可直接使用 #Predicate 让 SQLite 完成过滤，避免全表扫描内存炸弹。
        let predicate = #Predicate<ReviewItemModel> { $0.nextReviewAt <= now }
        let descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let due = try modelContext.fetch(descriptor)
        // 排除处于 5 秒撤销窗口的软删题（DeletionScheduler.pendingDeletionIDs）——
        // 软删纯内存集合、DB 里仍在，必须由调用方传入 pending IDs 在此过滤。
        return ids.isEmpty ? due : due.filter { !ids.contains($0.id) }
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
    /// - 无维度值过滤：使用数据库级分页（高效路径）
    /// - 有维度值过滤：先从选中维度值的 inverse `items` 缩小候选题集合，再内存校验维度语义并分页。
    ///   SwiftData #Predicate 不支持 many-to-many 关联查询；直接用 fetchLimit + 内存过滤会导致分页数量不可控。
    public func fetchFilteredModels(
        searchText: String,
        valueIdsByDimension: [UUID: Set<UUID>],
        difficulties: Set<Int> = [],
        sortDescriptors: [SortDescriptor<ReviewItemModel>] = [SortDescriptor(\ReviewItemModel.createdAt, order: .reverse)],
        sortBySubjectName: Bool = false,
        limit: Int,
        offset: Int
    ) throws -> [ReviewItemModel] {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let difficultiesArray = Array(difficulties)

        // search + difficulty 走 DB 级 #Predicate；维度值（many-to-many）只能内存过滤（#Predicate 不支持关系）。
        // #Predicate 内禁止 force unwrap，用 ?.localizedStandardContains == true 替代。
        let predicate = #Predicate<ReviewItemModel> { item in
            (normalizedSearch.isEmpty || item.content?.localizedStandardContains(normalizedSearch) == true) &&
            (difficultiesArray.isEmpty || difficultiesArray.contains(item.difficulty))
        }

        // 维度值过滤或 subject 维度值名排序都需要内存处理；否则用 DB 级分页（高效路径）。
        let needsMemoryProcessing = !valueIdsByDimension.isEmpty || sortBySubjectName
        if !needsMemoryProcessing {
            var descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate, sortBy: sortDescriptors)
            descriptor.fetchLimit = limit
            descriptor.fetchOffset = offset
            return try modelContext.fetch(descriptor)
        }

        var matching: [ReviewItemModel]
        if valueIdsByDimension.isEmpty {
            let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate, sortBy: sortDescriptors)
            matching = try modelContext.fetch(descriptor)
        } else {
            // 维度过滤走候选集路径：先从选中维度值的 inverse `items` 取候选题 ID，
            // 再只对候选题做搜索 / 难度 / 关系排序。避免常见“点学科 chip”
            // 触发全量 ReviewItemModel fetch 后再内存过滤。
            let candidates = try fetchCandidateModels(
                valueIdsByDimension: valueIdsByDimension,
                sortDescriptors: sortDescriptors
            )
            matching = candidates.filter {
                matchesSearchAndDifficulty($0, normalizedSearch: normalizedSearch, difficulties: difficulties)
            }
        }

        // 维度间 AND、维度内 OR：每个被选中的维度，题目至少命中其一个选中值
        if !valueIdsByDimension.isEmpty && matching.isEmpty == false {
            matching = matching.filter { item in
                let itemValueIds = Set((item.categoryValues ?? []).map { $0.id })
                return valueIdsByDimension.values.allSatisfy { wanted in
                    !itemValueIds.isDisjoint(with: wanted)
                }
            }
        }

        // subject 维度值名排序（关系无法走 SortDescriptor），稳定 tiebreaker = createdAt 倒序
        if sortBySubjectName {
            matching.sort { lhs, rhs in
                let lName = lhs.subjectCategoryName ?? ""
                let rName = rhs.subjectCategoryName ?? ""
                if lName != rName { return lName < rName }
                return lhs.createdAt > rhs.createdAt
            }
        }

        guard offset < matching.count else { return [] }
        return Array(matching[offset..<min(offset + limit, matching.count)])
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

    private func fetchCandidateModels(
        valueIdsByDimension: [UUID: Set<UUID>],
        sortDescriptors: [SortDescriptor<ReviewItemModel>]
    ) throws -> [ReviewItemModel] {
        var candidateIDs: Set<UUID>?
        for wantedValueIDs in valueIdsByDimension.values {
            guard !wantedValueIDs.isEmpty else { return [] }
            let values = try fetchCategoryValues(by: wantedValueIDs)
            let itemIDs = Set(values.flatMap { ($0.items ?? []).map(\.id) })
            candidateIDs = candidateIDs.map { $0.intersection(itemIDs) } ?? itemIDs
            if candidateIDs?.isEmpty == true { return [] }
        }

        guard let ids = candidateIDs, !ids.isEmpty else { return [] }
        return try fetchModelsByIDs(ids, sortDescriptors: sortDescriptors)
    }

    private func fetchCategoryValues(by ids: Set<UUID>) throws -> [CategoryValueModel] {
        let targetIds = Array(ids)
        let predicate = #Predicate<CategoryValueModel> { value in
            targetIds.contains(value.id)
        }
        let descriptor = FetchDescriptor<CategoryValueModel>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }

    private func fetchModelsByIDs(
        _ ids: Set<UUID>,
        sortDescriptors: [SortDescriptor<ReviewItemModel>]
    ) throws -> [ReviewItemModel] {
        let targetIds = Array(ids)
        let predicate = #Predicate<ReviewItemModel> { item in
            targetIds.contains(item.id)
        }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate, sortBy: sortDescriptors)
        return try modelContext.fetch(descriptor)
    }

    private func matchesSearchAndDifficulty(
        _ item: ReviewItemModel,
        normalizedSearch: String,
        difficulties: Set<Int>
    ) -> Bool {
        (normalizedSearch.isEmpty || item.content?.localizedStandardContains(normalizedSearch) == true) &&
        (difficulties.isEmpty || difficulties.contains(item.difficulty))
    }

}
