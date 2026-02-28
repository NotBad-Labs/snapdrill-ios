//
//  SourceRepository.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2026/01/01.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  实现 SourceRepositoryProtocol，基于 SwiftData 持久化来源数据。
//

import Foundation
import SwiftData
import SnapDrillCore
import SnapDrillDomain

/// 题目来源数据仓库的 SwiftData 实现
@MainActor
public final class SourceRepository: SourceRepositoryProtocol {
    
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - SourceRepositoryProtocol
    
    public func fetchAll() throws -> [Source] {
        let descriptor = FetchDescriptor<SourceModel>(sortBy: [SortDescriptor(\.sortOrder)])
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }
    
    public func fetchByName(_ name: String) throws -> Source? {
        let targetName = name
        let predicate = #Predicate<SourceModel> { $0.name == targetName }
        let descriptor = FetchDescriptor<SourceModel>(predicate: predicate)
        return try modelContext.fetch(descriptor).first?.toEntity()
    }
    
    public func save(_ source: Source) throws {
        if let existing = try fetchModelById(source.id) {
            updateModel(existing, from: source)
        } else {
            // 检查名称唯一性
            let name = source.name
            let namePredicate = #Predicate<SourceModel> { $0.name == name }
            let descriptor = FetchDescriptor<SourceModel>(predicate: namePredicate)
            if try modelContext.fetchCount(descriptor) > 0 {
                 throw DataError.duplicateName(name: name, entityType: "Source")
            }
            
            let model = SourceModel(
                id: source.id,
                name: source.name,
                icon: source.icon,
                colorHex: source.colorHex,
                sortOrder: source.sortOrder
            )
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
        let descriptor = FetchDescriptor<SourceModel>()
        return try modelContext.fetchCount(descriptor)
    }
    
    public func seedDefaultsIfNeeded() {
        do {
            if try totalCount() == 0 {
                let isChinese = Locale.current.language.languageCode?.identifier == "zh"
                // swiftlint:disable:next large_tuple
                let defaults: [(String, String, String)] = isChinese ? [
                    ("试卷", "doc.text", "#5C6BC0"),
                    ("作业", "pencil.and.outline", "#42A5F5"),
                    ("教材", "book", "#66BB6A"),
                    ("错题本", "xmark.seal", "#EF5350"),
                    ("其他", "ellipsis.circle", "#78909C")
                ] : [
                    ("Exam", "doc.text", "#5C6BC0"),
                    ("Homework", "pencil.and.outline", "#42A5F5"),
                    ("Textbook", "book", "#66BB6A"),
                    ("Mistake Book", "xmark.seal", "#EF5350"),
                    ("Other", "ellipsis.circle", "#78909C")
                ]
                
                for (index, item) in defaults.enumerated() {
                    let model = SourceModel(name: item.0, icon: item.1, colorHex: item.2, sortOrder: index)
                    modelContext.insert(model)
                }
                try modelContext.save()
            }
        } catch {
            SnapDrillLogger.generic.error("初始化默认来源失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Helpers
    
    private func fetchModelById(_ id: UUID) throws -> SourceModel? {
        let targetId = id
        let predicate = #Predicate<SourceModel> { $0.id == targetId }
        var descriptor = FetchDescriptor<SourceModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
    
    private func updateModel(_ model: SourceModel, from source: Source) {
        model.name = source.name
        model.icon = source.icon
        model.colorHex = source.colorHex
        model.sortOrder = source.sortOrder
    }
    
    public func deleteAll() throws {
        try modelContext.delete(model: SourceModel.self)
        try modelContext.save()
    }
}
