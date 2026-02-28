//
//  TagRepository.swift
//  SnapDrillData
//
//  Created by SnapDrill Labs on 2025/12/30.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  核心职责：实现 TagRepositoryProtocol，基于 SwiftData 持久化标签数据。
//

import Foundation
import SwiftData
import SnapDrillCore
import SnapDrillDomain

/// 标签数据仓库的 SwiftData 实现
@MainActor
public final class TagRepository: TagRepositoryProtocol {
    
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - TagRepositoryProtocol
    
    public func fetchAll() throws -> [Tag] {
        let descriptor = FetchDescriptor<TagModel>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }
    
    public func fetchByName(_ name: String) throws -> Tag? {
        let predicate = #Predicate<TagModel> { $0.name == name }
        var descriptor = FetchDescriptor<TagModel>(predicate: predicate)
        descriptor.fetchLimit = 1 // 性能优化
        return try modelContext.fetch(descriptor).first?.toEntity()
    }
    
    public func save(_ tag: Tag) throws {
        if let existing = try fetchModelById(tag.id) {
            updateModel(existing, from: tag)
        } else {
            // 检查名称唯一性
            if let name = try fetchByName(tag.name) {
                // 如果 ID 不同但名字相同，视为冲突
                if name.id != tag.id {
                     throw DataError.duplicateName(name: tag.name, entityType: "Tag")
                }
            }
            
            let model = TagModel(name: tag.name, colorHex: tag.colorHex)
            model.id = tag.id // 显式保持 ID 一致
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
    
    // MARK: - Private Helpers
    
    private func fetchModelById(_ id: UUID) throws -> TagModel? {
        let targetId = id
        let predicate = #Predicate<TagModel> { $0.id == targetId }
        var descriptor = FetchDescriptor<TagModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
    
    private func updateModel(_ model: TagModel, from tag: Tag) {
        model.name = tag.name
        model.colorHex = tag.colorHex
    }
    
    public func deleteAll() throws {
        try modelContext.delete(model: TagModel.self)
        try modelContext.save()
    }
}
