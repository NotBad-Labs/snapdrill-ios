//
//  CategoryValueRepository.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  维度值数据仓库（SwiftData 实现）。合并旧 Subject/Source/Grade/Tag 的值级操作。
//

import Foundation
import SwiftData
import SnapDrillCore

/// 维度值数据仓库
public final class CategoryValueRepository {

    private let modelContext: ModelContext

    /// 创建维度值仓库（推荐路径）
    public init(executor: DataExecutor) {
        self.modelContext = executor.container.mainContext
    }

    /// 创建维度值仓库（测试/Preview 路径）
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// 获取某维度下的全部值（按 sortOrder 升序，同序按 createdAt 兜底）。
    /// 走 `dimension.values` 关系反查——避免对 to-one 关系做 #Predicate 过滤的坑。
    public func fetchAllModels(in dimension: CategoryDimensionModel) -> [CategoryValueModel] {
        let values = dimension.values ?? []
        return values.sorted {
            $0.sortOrder != $1.sortOrder ? $0.sortOrder < $1.sortOrder : $0.createdAt < $1.createdAt
        }
    }

    /// 在指定维度内按名称查找值（跨维度允许同名，故限定在维度内）
    public func fetchModel(byName name: String, in dimension: CategoryDimensionModel) -> CategoryValueModel? {
        (dimension.values ?? []).first { $0.name == name }
    }

    /// 纯内存插入；调用方统一 saveContext()
    public func insert(_ model: CategoryValueModel) {
        modelContext.insert(model)
    }

    /// 插入并保存（维度内 name 唯一性校验；跨维度允许同名）
    public func insertAndSave(_ model: CategoryValueModel) throws {
        let name = model.name
        let siblings = model.dimension?.values ?? []
        if siblings.contains(where: { $0.name == name && $0.id != model.id }) {
            throw DataError.duplicateName(name: name, entityType: "CategoryValue")
        }
        modelContext.insert(model)
        try modelContext.save()
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
    }

    /// 在维度内查找或创建值（纯内存，不 save）。
    /// 已存在则返回；否则 insert 但不 save，调用方统一 saveContext()。
    /// 标签维度 + 录入页「现场新增值」走此方法（替代旧 TagRepository.fetchOrCreateModel）。
    public func fetchOrCreate(name: String, in dimension: CategoryDimensionModel, colorHex: String = "#808080") -> CategoryValueModel {
        if let existing = fetchModel(byName: name, in: dimension) {
            return existing
        }
        let value = CategoryValueModel(name: name, colorHex: colorHex, dimension: dimension)
        modelContext.insert(value)
        return value
    }

    /// 删除值。显式从引用它的题目 categoryValues 中移除（deleteRule .nullify 之外的防御，
    /// 显式-save 路径不盲信框架自动解关联）。
    public func delete(id: UUID) throws {
        guard let model = try fetchModelById(id) else { return }
        for item in model.items ?? [] {
            item.categoryValues?.removeAll { $0.id == model.id }
        }
        modelContext.delete(model)
        do {
            try modelContext.save()
        } catch {
            rollbackContext()
            throw error
        }
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
    }

    /// 保存 ModelContext
    public func saveContext() throws {
        try modelContext.save()
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
    }

    /// 回滚未持久化变更
    public func rollbackContext() {
        modelContext.rollback()
    }

    /// 纯内存：标记删除所有维度值
    public func deleteAll() throws {
        try modelContext.delete(model: CategoryValueModel.self)
    }

    // MARK: - Private Helpers

    private func fetchModelById(_ id: UUID) throws -> CategoryValueModel? {
        let target = id
        let predicate = #Predicate<CategoryValueModel> { $0.id == target }
        var descriptor = FetchDescriptor<CategoryValueModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
