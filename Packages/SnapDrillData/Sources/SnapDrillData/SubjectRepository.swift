//
//  SubjectRepository.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2025/12/30.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  实现 SubjectRepositoryProtocol，基于 SwiftData 持久化学科数据。
//

import Foundation
import SwiftData
import SnapDrillCore

/// 学科数据仓库的 SwiftData 实现
@MainActor
public final class SubjectRepository {
    
    private let modelContext: ModelContext
    
    /// 创建学科数据仓库
    /// - Parameter modelContext: 当前 ModelContext
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public API

    /// 删除指定学科并立即保存
    /// - Parameter id: 要删除的学科 UUID
    /// - Throws: SwiftData save 错误
    public func delete(id: UUID) throws {
        if let model = try fetchModelById(id) {
            modelContext.delete(model)
            try modelContext.save()
        }
    }
    
    /// 返回学科总数
    /// - Throws: SwiftData fetch 错误
    public func totalCount() throws -> Int {
        let descriptor = FetchDescriptor<SubjectModel>()
        return try modelContext.fetchCount(descriptor)
    }
    
    /// 若数据库中无学科数据，则自动插入预设学科（首次启动时调用）
    public func seedDefaultsIfNeeded() {
        do {
            if try totalCount() == 0 {
                let isChinese = Locale.current.language.languageCode?.identifier == "zh"
                // swiftlint:disable:next large_tuple
                let defaults: [(String, String, String)] = isChinese ? [
                    ("语文", "text.book.closed", "#E57373"),
                    ("数学", "function", "#4FC3F7"),
                    ("英语", "character.book.closed", "#AED581"),
                    ("物理", "atom", "#7986CB"),
                    ("化学", "flask", "#F06292"),
                    ("生物", "leaf", "#81C784"),
                    ("历史", "scroll", "#DCE775"),
                    ("地理", "globe.asia.australia", "#4DB6AC"),
                    ("政治", "building.columns", "#FFB74D")
                ] : [
                    ("Math", "function", "#4FC3F7"),
                    ("English", "character.book.closed", "#AED581"),
                    ("Physics", "atom", "#7986CB"),
                    ("Chemistry", "flask", "#F06292"),
                    ("Biology", "leaf", "#81C784"),
                    ("History", "scroll", "#DCE775"),
                    ("Geography", "globe.americas", "#4DB6AC"),
                    ("Art", "paintbrush", "#FFB74D")
                ]
                
                for (index, item) in defaults.enumerated() {
                    let model = SubjectModel(name: item.0, icon: item.1, colorHex: item.2, sortOrder: index)
                    modelContext.insert(model)
                }
                try modelContext.save()
            }
        } catch {
            SnapDrillLogger.generic.error("初始化默认学科失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Model-Tier API（直接返回 @Model，供 Features ViewModel 使用）

    /// 获取全部 SubjectModel，按排序权重升序
    public func fetchAllModels() throws -> [SubjectModel] {
        let descriptor = FetchDescriptor<SubjectModel>(sortBy: [SortDescriptor(\.sortOrder)])
        return try modelContext.fetch(descriptor)
    }

    /// 按名称查找 SubjectModel
    public func fetchModel(byName name: String) throws -> SubjectModel? {
        let targetName = name
        let predicate = #Predicate<SubjectModel> { $0.name == targetName }
        var descriptor = FetchDescriptor<SubjectModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// 纯内存插入 SubjectModel，不 save；调用方统一 saveContext()
    public func insert(_ model: SubjectModel) {
        modelContext.insert(model)
    }

    /// 直接插入 SubjectModel 并保存（带名称唯一性校验）
    public func insertAndSave(_ model: SubjectModel) throws {
        let name = model.name
        let namePredicate = #Predicate<SubjectModel> { $0.name == name }
        let descriptor = FetchDescriptor<SubjectModel>(predicate: namePredicate)
        if try modelContext.fetchCount(descriptor) > 0 {
            throw DataError.duplicateName(name: name, entityType: "Subject")
        }
        modelContext.insert(model)
        try modelContext.save()
    }

    /// 保存 ModelContext（直接修改 @Model 属性后调用）
    public func saveContext() throws {
        try modelContext.save()
    }

    // MARK: - Private Helpers

    private func fetchModelById(_ id: UUID) throws -> SubjectModel? {
        let targetId = id
        let predicate = #Predicate<SubjectModel> { $0.id == targetId }
        var descriptor = FetchDescriptor<SubjectModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
    
    /// 纯内存操作：将所有学科标记为待删除。调用方负责 saveContext()。
    public func deleteAll() throws {
        try modelContext.delete(model: SubjectModel.self)
    }
}
