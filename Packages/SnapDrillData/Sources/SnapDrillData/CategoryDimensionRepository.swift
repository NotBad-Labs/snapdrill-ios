//
//  CategoryDimensionRepository.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  分类维度数据仓库（SwiftData 实现）。管理维度本身（低频，藏「管理分类」二级界面）。
//

import Foundation
import SwiftData
import SnapDrillCore

/// 分类维度数据仓库
public final class CategoryDimensionRepository {

    private let modelContext: ModelContext

    /// 创建维度仓库（推荐路径）
    public init(executor: DataExecutor) {
        self.modelContext = executor.container.mainContext
    }

    /// 创建维度仓库（测试/Preview 路径）
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// 获取全部维度，按 sortOrder 升序（同序按 name 兜底，保证确定性）
    public func fetchAllModels() throws -> [CategoryDimensionModel] {
        let descriptor = FetchDescriptor<CategoryDimensionModel>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 按稳定 systemKey 查找内置维度（消费链识别 / seed 幂等用）。
    /// systemKey 是标量字符串，可安全进 #Predicate（非关系过滤）。
    public func fetchDimension(bySystemKey systemKey: String) throws -> CategoryDimensionModel? {
        let target = systemKey
        let predicate = #Predicate<CategoryDimensionModel> { $0.systemKey == target }
        var descriptor = FetchDescriptor<CategoryDimensionModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// 维度总数
    public func totalCount() throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<CategoryDimensionModel>())
    }

    /// 纯内存插入；调用方统一 saveContext()
    public func insert(_ model: CategoryDimensionModel) {
        modelContext.insert(model)
    }

    /// 插入并保存（带 name 唯一性校验）
    public func insertAndSave(_ model: CategoryDimensionModel) throws {
        let name = model.name
        let predicate = #Predicate<CategoryDimensionModel> { $0.name == name }
        if try modelContext.fetchCount(FetchDescriptor<CategoryDimensionModel>(predicate: predicate)) > 0 {
            throw DataError.duplicateName(name: name, entityType: "CategoryDimension")
        }
        modelContext.insert(model)
        try modelContext.save()
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
    }

    /// 删除维度（仅非内置）。显式遍历删除其所有值后再删维度——
    /// 本库走显式 save（非 autosave），框架 cascade 在显式-save 路径不可靠（FB13640004）。
    public func delete(id: UUID) throws {
        guard let model = try fetchModelById(id) else { return }
        // 防御：内置维度不可删（UI 层管理界面不提供删除入口）
        guard !model.isBuiltIn else { return }
        for value in model.values ?? [] {
            modelContext.delete(value)
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

    /// 保存 ModelContext（直接改 @Model 属性后调用）
    public func saveContext() throws {
        try modelContext.save()
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
    }

    /// 回滚未持久化变更
    public func rollbackContext() {
        modelContext.rollback()
    }

    /// 纯内存：标记删除所有维度（cascade 会带值，但调用方应配合 CategoryValueRepository.deleteAll 显式清）
    public func deleteAll() throws {
        try modelContext.delete(model: CategoryDimensionModel.self)
    }

    // MARK: - Private Helpers

    private func fetchModelById(_ id: UUID) throws -> CategoryDimensionModel? {
        let target = id
        let predicate = #Predicate<CategoryDimensionModel> { $0.id == target }
        var descriptor = FetchDescriptor<CategoryDimensionModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
