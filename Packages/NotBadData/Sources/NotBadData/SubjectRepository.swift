//
//  SubjectRepository.swift
//  NotBadData
//
//  Created by NotBad Labs on 2025/12/30.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  学科数据的仓库层，负责 Default Subjects 的初始化与查询。
//

import Foundation
import NotBadCore
import SwiftData

/// 学科数据仓库
///
/// 管理学科的增删改查及默认初始化。
@MainActor
public class SubjectRepository {
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
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
    
    /// 初始化默认学科（如果为空）
    public func initializeDefaultsIfNeeded() {
        do {
            let count = try modelContext.fetchCount(FetchDescriptor<SubjectModel>())
            if count == 0 {
                createDefaultSubjects()
                try? modelContext.save()
            }
        } catch {
            NotBadLogger.generic.info("Failed to check subject count: \(error)")
        }
    }
    
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
}
