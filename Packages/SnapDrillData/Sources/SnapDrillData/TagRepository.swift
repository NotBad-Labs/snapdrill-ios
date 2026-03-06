//
//  TagRepository.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2025/12/30.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  实现 TagRepositoryProtocol，基于 SwiftData 持久化标签数据。
//

import Foundation
import SwiftData
import SnapDrillCore

/// 标签数据仓库的 SwiftData 实现
@MainActor
public final class TagRepository {
    
    private let modelContext: ModelContext
    
    /// 创建标签数据仓库
    /// - Parameter modelContext: 当前 ModelContext
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// 删除指定标签并立即保存
    /// - Parameter id: 要删除的标签 UUID
    /// - Throws: SwiftData save 错误
    public func delete(id: UUID) throws {
        if let model = try fetchModelById(id) {
            modelContext.delete(model)
            try modelContext.save()
        }
    }
    
    // MARK: - Model-Tier API（直接返回 @Model，供 Features ViewModel 使用）

    /// 获取全部 TagModel，按创建时间降序
    public func fetchAllModels() throws -> [TagModel] {
        let descriptor = FetchDescriptor<TagModel>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    /// 按名称查找或创建 TagModel（纯内存操作）。
    /// 若已存在则直接返回；若不存在则 insert 但不 save。
    /// 调用方负责统一 saveContext()，失败时 rollbackContext() 可清除脏 Tag。
    public func fetchOrCreateModel(name: String, colorHex: String) throws -> TagModel {
        let targetName = name
        let predicate = #Predicate<TagModel> { $0.name == targetName }
        var descriptor = FetchDescriptor<TagModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        let newTag = TagModel(name: name, colorHex: colorHex)
        modelContext.insert(newTag)
        return newTag
    }

    // MARK: - Private Helpers

    private func fetchModelById(_ id: UUID) throws -> TagModel? {
        let targetId = id
        let predicate = #Predicate<TagModel> { $0.id == targetId }
        var descriptor = FetchDescriptor<TagModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
    
    /// 纯内存操作：将所有标签标记为待删除。调用方负责 saveContext()。
    public func deleteAll() throws {
        try modelContext.delete(model: TagModel.self)
    }
}
