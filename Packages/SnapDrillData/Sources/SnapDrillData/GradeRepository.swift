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
import SnapDrillDomain

/// 年级数据仓库的 SwiftData 实现
@MainActor
public final class GradeRepository {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - GradeRepositoryProtocol

    public func fetchAll() throws -> [Grade] {
        let descriptor = FetchDescriptor<GradeModel>(sortBy: [SortDescriptor(\.sortOrder)])
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    public func fetchByName(_ name: String) throws -> Grade? {
        let targetName = name
        let predicate = #Predicate<GradeModel> { $0.name == targetName }
        var descriptor = FetchDescriptor<GradeModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.toEntity()
    }

    public func save(_ grade: Grade) throws {
        if let existing = try fetchModelById(grade.id) {
            existing.name = grade.name
            existing.sortOrder = grade.sortOrder
        } else {
            let name = grade.name
            let namePredicate = #Predicate<GradeModel> { $0.name == name }
            let descriptor = FetchDescriptor<GradeModel>(predicate: namePredicate)
            if try modelContext.fetchCount(descriptor) > 0 {
                throw DataError.duplicateName(name: name, entityType: "Grade")
            }

            let model = GradeModel(id: grade.id, name: grade.name, sortOrder: grade.sortOrder)
            modelContext.insert(model)
        }
        try modelContext.save()
    }

    public func delete(id: UUID) throws {
        if let model = try fetchModelById(id) {
            modelContext.delete(model)
            try modelContext.save()
        }
    }

    public func totalCount() throws -> Int {
        let descriptor = FetchDescriptor<GradeModel>()
        return try modelContext.fetchCount(descriptor)
    }

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

    public func deleteAll() throws {
        try modelContext.delete(model: GradeModel.self)
        try modelContext.save()
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
    }

    /// 保存 ModelContext（直接修改 @Model 属性后调用）
    public func saveContext() throws {
        try modelContext.save()
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
