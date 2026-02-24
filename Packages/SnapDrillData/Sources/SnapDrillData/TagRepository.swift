//
//  TagRepository.swift
//  SnapDrillData
//
//  Created by SnapDrill Labs on 2026/01/02.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  标签数据仓储，负责 TagModel 的增删改查。
//

import SwiftData
import Foundation

@MainActor
public class TagRepository {
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// 获取所有标签
    public func fetchAll() throws -> [TagModel] {
        let descriptor = FetchDescriptor<TagModel>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    /// 根据名称查找标签
    /// - Parameter name: 标签名称
    /// - Returns: 找到的标签，如果不存在则返回 nil
    public func fetchByName(_ name: String) throws -> TagModel? {
        let descriptor = FetchDescriptor<TagModel>(
            predicate: #Predicate<TagModel> { tag in
                tag.name == name
            }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    /// 添加新标签
    /// - Parameters:
    ///   - name: 标签名称
    ///   - colorHex: 颜色代码
    /// - Throws: `DataError.duplicateName` 如果标签名称已存在
    /// - Returns: 创建的标签
    @discardableResult
    public func add(name: String, colorHex: String = "#8E8E93") throws -> TagModel {
        // 检查名称唯一性
        if let existing = try fetchByName(name) {
            throw DataError.duplicateName(name: name, entityType: "Tag")
        }
        
        let tag = TagModel(name: name, colorHex: colorHex)
        modelContext.insert(tag)
        return tag
    }
    
    /// 获取或创建标签（如果不存在则创建）
    /// - Parameters:
    ///   - name: 标签名称
    ///   - colorHex: 颜色代码（仅在创建时使用）
    /// - Returns: 现有或新创建的标签
    public func getOrCreate(name: String, colorHex: String = "#8E8E93") throws -> TagModel {
        if let existing = try fetchByName(name) {
            return existing
        }
        return try add(name: name, colorHex: colorHex)
    }
    
    /// 删除标签
    public func delete(_ tag: TagModel) {
        modelContext.delete(tag)
    }
    
    /// 保存上下文更改
    public func save() throws {
        try modelContext.save()
    }
}
