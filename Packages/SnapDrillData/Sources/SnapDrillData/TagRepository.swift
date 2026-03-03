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
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public API

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

    /// 按名称查找或创建 TagModel
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
        try modelContext.save()
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
    
    public func deleteAll() throws {
        try modelContext.delete(model: TagModel.self)
        try modelContext.save()
    }
}
