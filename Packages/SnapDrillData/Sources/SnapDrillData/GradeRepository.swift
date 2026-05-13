//
//  GradeRepository.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2026/02/28.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  实现 GradeRepositoryProtocol，基于 SwiftData 持久化年级数据。
//

import Foundation
import SwiftData
import SnapDrillCore

/// 年级数据仓库的 SwiftData 实现
public final class GradeRepository {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    /// 创建年级数据仓库（推荐路径）
    /// - Parameter executor: DataExecutor
    public init(executor: DataExecutor) {
        self.modelContext = executor.container.mainContext
    }

    /// 创建年级数据仓库（向后兼容，Phase 2 移除）
    /// - Parameter modelContext: 当前 ModelContext
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// 删除指定年级并立即保存
    /// - Parameter id: 要删除的年级 UUID
    /// - Throws: SwiftData save 错误
    public func delete(id: UUID) throws {
        if let model = try fetchModelById(id) {
            modelContext.delete(model)
            try modelContext.save()
            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
        }
    }

    /// 返回年级总数
    /// - Throws: SwiftData fetch 错误
    public func totalCount() throws -> Int {
        let descriptor = FetchDescriptor<GradeModel>()
        return try modelContext.fetchCount(descriptor)
    }

    /// 若年级列表为空，则写入本地化默认年级（中文或英文）
    public func seedDefaultsIfNeeded() {
        do {
            if try totalCount() == 0 {
                let isChinese = Locale.current.language.languageCode?.identifier == "zh"
                let defaults: [String] = isChinese ? [
                    "小学", "初一", "初二", "初三",
                    "高一", "高二", "高三"
                ] : [
                    "Elementary", "Middle School",
                    "Grade 9", "Grade 10", "Grade 11", "Grade 12"
                ]

                for (index, name) in defaults.enumerated() {
                    let model = GradeModel(name: name, sortOrder: index)
                    modelContext.insert(model)
                }
                try modelContext.save()
            }
        } catch {
            SnapDrillLogger.generic.error("初始化默认年级失败: \(error.localizedDescription)")
        }
    }

    /// 纯内存操作：将所有年级标记为待删除。调用方负责 saveContext()。
    public func deleteAll() throws {
        try modelContext.delete(model: GradeModel.self)
    }

    // MARK: - Model-Tier API（直接返回 @Model，供 Features ViewModel 使用）

    /// 获取全部 GradeModel，按排序权重升序
    public func fetchAllModels() throws -> [GradeModel] {
        let descriptor = FetchDescriptor<GradeModel>(sortBy: [SortDescriptor(\.sortOrder)])
        return try modelContext.fetch(descriptor)
    }

    /// 按名称查找 GradeModel
    public func fetchModel(byName name: String) throws -> GradeModel? {
        let targetName = name
        let predicate = #Predicate<GradeModel> { $0.name == targetName }
        var descriptor = FetchDescriptor<GradeModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// 纯内存插入 GradeModel，不 save；调用方统一 saveContext()
    public func insert(_ model: GradeModel) {
        modelContext.insert(model)
    }

    /// 直接插入 GradeModel 并保存（带名称唯一性校验）
    public func insertAndSave(_ model: GradeModel) throws {
        let name = model.name
        let namePredicate = #Predicate<GradeModel> { $0.name == name }
        let descriptor = FetchDescriptor<GradeModel>(predicate: namePredicate)
        if try modelContext.fetchCount(descriptor) > 0 {
            throw DataError.duplicateName(name: name, entityType: "Grade")
        }
        modelContext.insert(model)
        try modelContext.save()
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
    }

    /// 保存 ModelContext（直接修改 @Model 属性后调用）
    public func saveContext() throws {
        try modelContext.save()
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
    }

    /// 回滚 ModelContext 中所有未持久化的变更（saveContext 失败时调用）
    public func rollbackContext() {
        modelContext.rollback()
    }

    // MARK: - Private Helpers

    private func fetchModelById(_ id: UUID) throws -> GradeModel? {
        let targetId = id
        let predicate = #Predicate<GradeModel> { $0.id == targetId }
        var descriptor = FetchDescriptor<GradeModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
