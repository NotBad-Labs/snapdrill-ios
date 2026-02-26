//
//  SubjectRepository.swift
//  SnapDrillData
//
//  Created by SnapDrill Labs on 2025/12/30.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  学科数据的仓库层，负责 Default Subjects 的初始化与查询。
//

import Foundation
import SnapDrillCore
import SwiftData

/// 学科数据仓库
///
/// 管理学科的增删改查及默认初始化。
@MainActor
public class SubjectRepository: SubjectRepositoryProtocol {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public API
    
    /// 获取所有学科（按 sortOrder 排序）
    public func fetchAll() throws -> [SubjectModel] {
        let descriptor = FetchDescriptor<SubjectModel>(sortBy: [SortDescriptor(\.sortOrder)])
        return try modelContext.fetch(descriptor)
    }
    
    /// 添加学科
    /// - Throws: `DataError.duplicateName` 如果学科名称已存在
    public func add(name: String, icon: String, colorHex: String) throws {
        // 检查名称唯一性
        let existing = try fetchAll().first { $0.name == name }
        if existing != nil {
            throw DataError.duplicateName(name: name, entityType: "Subject")
        }
        
        let count = try? fetchAll().count
        let order = count ?? 0
        let model = SubjectModel(name: name, icon: icon, colorHex: colorHex, sortOrder: order)
        modelContext.insert(model)
    }
    
    /// 更新学科
    public func update(_ subject: SubjectModel, name: String, icon: String, colorHex: String) throws {
        // 检查名称唯一性，排除自身
        let existing = try fetchAll().first { $0.name == name && $0.id != subject.id }
        if existing != nil {
            throw DataError.duplicateName(name: name, entityType: "Subject")
        }
        subject.name = name
        subject.icon = icon
        subject.colorHex = colorHex
    }
    
    /// 删除学科
    public func delete(_ subject: SubjectModel) {
        modelContext.delete(subject)
    }
    
    /// 清空所有学科
    public func deleteAll() throws {
        try modelContext.delete(model: SubjectModel.self)
    }
    
    /// 初始化默认学科（如果为空）
    public func initializeDefaultsIfNeeded() {
        do {
            let count = try modelContext.fetchCount(FetchDescriptor<SubjectModel>())
            if count == 0 {
                createDefaultSubjects()
                try? modelContext.save()
            }
        } catch {
            SnapDrillLogger.generic.info("Failed to check subject count: \(error)")
        }
    }
    
    // MARK: - Private Helpers
    
    private func createDefaultSubjects() {
        // Simple localization check
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
            let model = SubjectModel(
                name: item.0,
                icon: item.1,
                colorHex: item.2,
                sortOrder: index
            )
            modelContext.insert(model)
        }
    }
    
    /// 保存上下文
    public func save() throws {
        try modelContext.save()
    }
    
    /// 获取特定学科下的题目数量
    public func countItems(named: String) throws -> Int {
        let predicate = #Predicate<ReviewItemModel> { item in
            item.subjectRawValue == named
        }
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }
    
    /// 检查学科是否被使用
    public func isSubjectInUse(_ subject: SubjectModel) throws -> Bool {
        let count = try countItems(named: subject.name)
        return count > 0
    }
}
