//
//  SourceRepository.swift
//  SnapDrillData
//
//  Created by SnapDrill Labs on 2026/01/01.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  来源数据仓储，负责 SourceModel 的增删改查。
//

import SwiftData
import Foundation
import SnapDrillCore

@MainActor
public class SourceRepository: SourceRepositoryProtocol {
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// 获取所有来源
    public func fetchAll() throws -> [SourceModel] {
        let descriptor = FetchDescriptor<SourceModel>(sortBy: [SortDescriptor(\.sortOrder)])
        return try modelContext.fetch(descriptor)
    }
    
    /// 添加新来源
    /// - Throws: `DataError.duplicateName` 如果来源名称已存在
    public func add(name: String, icon: String, colorHex: String) throws {
        // 检查名称唯一性
        let existing = try fetchAll().first { $0.name == name }
        if existing != nil {
            throw DataError.duplicateName(name: name, entityType: "Source")
        }
        
        let count = try? modelContext.fetchCount(FetchDescriptor<SourceModel>())
        let sortOrder = count ?? 0
        let source = SourceModel(name: name, icon: icon, colorHex: colorHex, sortOrder: sortOrder)
        modelContext.insert(source)
    }
    
    /// 删除来源
    public func delete(_ source: SourceModel) {
        modelContext.delete(source)
    }
    
    /// 初始化默认来源 (当数据库为空时)
    public func seedDefaultSourcesIfNeeded() {
        do {
            let count = try modelContext.fetchCount(FetchDescriptor<SourceModel>())
            guard count == 0 else { return }
            
            struct DefaultSource {
                let name: String
                let icon: String
                let color: String
            }
            
            let defaults: [DefaultSource] = [
                DefaultSource(name: "试卷", icon: "doc.text", color: "#FF5733"),
                DefaultSource(name: "作业", icon: "pencil.and.list.clipboard", color: "#33FF57"),
                DefaultSource(name: "教材", icon: "book.closed", color: "#3357FF"),
                DefaultSource(name: "错题本", icon: "xmark.bin", color: "#FFFF33"),
                DefaultSource(name: "其他", icon: "questionmark.circle", color: "#808080")
            ]
            
            for (index, item) in defaults.enumerated() {
                let source = SourceModel(name: item.name, icon: item.icon, colorHex: item.color, sortOrder: index)
                modelContext.insert(source)
            }
            
            try modelContext.save()
            SnapDrillLogger.generic.info("Successfully seeded default sources.")
        } catch {
            SnapDrillLogger.generic.info("Failed to seed default sources: \(error)")
        }
    }
}
