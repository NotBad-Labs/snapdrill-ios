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

/// 题目来源数据仓库的 SwiftData 实现
@MainActor
public final class SourceRepository {
    
    private let modelContext: ModelContext
    
    /// 创建来源数据仓库
    /// - Parameter modelContext: 当前 ModelContext
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// 删除指定来源并立即保存
    /// - Parameter id: 要删除的来源 UUID
    /// - Throws: SwiftData save 错误
    public func delete(id: UUID) throws {
        if let model = try fetchModelById(id) {
            modelContext.delete(model)
            try modelContext.save()
            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
        }
    }
    
    /// 返回来源总数
    /// - Throws: SwiftData fetch 错误
    public func totalCount() throws -> Int {
        let descriptor = FetchDescriptor<SourceModel>()
        return try modelContext.fetchCount(descriptor)
    }
    
    /// 若来源列表为空，则写入本地化默认来源（中文或英文）
    public func seedDefaultsIfNeeded() {
        do {
            if try totalCount() == 0 {
                let isChinese = Locale.current.language.languageCode?.identifier == "zh"
                // swiftlint:disable:next large_tuple
                let defaults: [(String, String, String)] = isChinese ? [
                    ("试卷", "doc.text.fill", "#5C6BC0"),
                    ("作业", "pencil", "#42A5F5"),
                    ("教材", "book.fill", "#66BB6A"),
                    ("错题本", "star.fill", "#EF5350"),
                    ("其他", "folder.fill", "#78909C")
                ] : [
                    ("Exam", "doc.text.fill", "#5C6BC0"),
                    ("Homework", "pencil", "#42A5F5"),
                    ("Textbook", "book.fill", "#66BB6A"),
                    ("Mistake Book", "star.fill", "#EF5350"),
                    ("Other", "folder.fill", "#78909C")
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
    
    // MARK: - Model-Tier API（直接返回 @Model，供 Features ViewModel 使用）

    /// 获取全部 SourceModel，按排序权重升序
    public func fetchAllModels() throws -> [SourceModel] {
        let descriptor = FetchDescriptor<SourceModel>(sortBy: [SortDescriptor(\.sortOrder)])
        return try modelContext.fetch(descriptor)
    }

    /// 按名称查找 SourceModel
    public func fetchModel(byName name: String) throws -> SourceModel? {
        let targetName = name
        let predicate = #Predicate<SourceModel> { $0.name == targetName }
        var descriptor = FetchDescriptor<SourceModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// 纯内存插入 SourceModel，不 save；调用方统一 saveContext()
    public func insert(_ model: SourceModel) {
        modelContext.insert(model)
    }

    /// 直接插入 SourceModel 并保存（带名称唯一性校验）
    public func insertAndSave(_ model: SourceModel) throws {
        let name = model.name
        let namePredicate = #Predicate<SourceModel> { $0.name == name }
        let descriptor = FetchDescriptor<SourceModel>(predicate: namePredicate)
        if try modelContext.fetchCount(descriptor) > 0 {
            throw DataError.duplicateName(name: name, entityType: "Source")
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

    // MARK: - Private Helpers

    private func fetchModelById(_ id: UUID) throws -> SourceModel? {
        let targetId = id
        let predicate = #Predicate<SourceModel> { $0.id == targetId }
        var descriptor = FetchDescriptor<SourceModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
    
    /// 纯内存操作：将所有来源标记为待删除。调用方负责 saveContext()。
    public func deleteAll() throws {
        try modelContext.delete(model: SourceModel.self)
    }
}
