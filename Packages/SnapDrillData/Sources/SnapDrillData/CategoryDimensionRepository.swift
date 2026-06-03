//
//  CategoryDimensionRepository.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  分类维度数据仓库（SwiftData 实现）。管理维度本身（低频，藏「管理分类」二级界面）。
//

import Foundation
import SwiftData
import SnapDrillCore

/// 分类维度数据仓库
public final class CategoryDimensionRepository {

    private let modelContext: ModelContext

    /// 创建维度仓库（推荐路径）
    public init(executor: DataExecutor) {
        self.modelContext = executor.container.mainContext
    }

    /// 创建维度仓库（测试/Preview 路径）
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// 获取全部维度，按 sortOrder 升序（同序按 name 兜底，保证确定性）
    public func fetchAllModels() throws -> [CategoryDimensionModel] {
        let descriptor = FetchDescriptor<CategoryDimensionModel>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 按稳定 systemKey 查找内置维度（消费链识别 / seed 幂等用）。
    /// systemKey 是标量字符串，可安全进 #Predicate（非关系过滤）。
    public func fetchDimension(bySystemKey systemKey: String) throws -> CategoryDimensionModel? {
        let target = systemKey
        let predicate = #Predicate<CategoryDimensionModel> { $0.systemKey == target }
        var descriptor = FetchDescriptor<CategoryDimensionModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// 维度总数
    public func totalCount() throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<CategoryDimensionModel>())
    }

    /// 纯内存插入；调用方统一 saveContext()
    public func insert(_ model: CategoryDimensionModel) {
        modelContext.insert(model)
    }

    /// 插入并保存（带 name 唯一性校验）
    public func insertAndSave(_ model: CategoryDimensionModel) throws {
        let name = model.name
        let predicate = #Predicate<CategoryDimensionModel> { $0.name == name }
        if try modelContext.fetchCount(FetchDescriptor<CategoryDimensionModel>(predicate: predicate)) > 0 {
            throw DataError.duplicateName(name: name, entityType: "CategoryDimension")
        }
        modelContext.insert(model)
        try modelContext.save()
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
    }

    /// 删除维度（仅非内置）。显式遍历删除其所有值后再删维度——
    /// 本库走显式 save（非 autosave），框架 cascade 在显式-save 路径不可靠（FB13640004）。
    public func delete(id: UUID) throws {
        guard let model = try fetchModelById(id) else { return }
        // 防御：内置维度不可删（UI 层管理界面不提供删除入口）
        guard !model.isBuiltIn else { return }
        for value in model.values ?? [] {
            // 先解题目对该值的反向引用（对齐 CategoryValueRepository.delete）——
            // 否则幸存题目 categoryValues 残留悬挂引用（desync，与 audit#1 #3/#4 同性质）
            for item in value.items ?? [] {
                item.categoryValues?.removeAll { $0.id == value.id }
            }
            modelContext.delete(value)
        }
        modelContext.delete(model)
        do {
            try modelContext.save()
        } catch {
            rollbackContext()
            throw error
        }
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
    }

    /// 保存 ModelContext（直接改 @Model 属性后调用）
    public func saveContext() throws {
        try modelContext.save()
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
    }

    /// 回滚未持久化变更
    public func rollbackContext() {
        modelContext.rollback()
    }

    /// 纯内存：标记删除所有维度（cascade 会带值，但调用方应配合 CategoryValueRepository.deleteAll 显式清）
    public func deleteAll() throws {
        try modelContext.delete(model: CategoryDimensionModel.self)
    }

    // MARK: - Seed（内置维度默认值）

    // swiftlint:disable large_tuple
    /// 首次启动种入内置维度（学科/来源/年级=单值，标签=多值）及其默认值。幂等：维度非空则跳过。
    /// 替代旧 Subject/Source/Grade Repository 的 seedDefaultsIfNeeded（S6 删旧）。
    public func seedDefaultsIfNeeded() {
        do {
            guard try totalCount() == 0 else { return }
            let zh = Locale.current.language.languageCode?.identifier == "zh"
            seedSubjectDimension(zh: zh)
            seedSourceDimension(zh: zh)
            seedGradeDimension(zh: zh)
            seedTagDimension(zh: zh)
            try modelContext.save()
            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
        } catch {
            modelContext.rollback()
            SnapDrillLogger.generic.error("初始化默认分类维度失败: \(error.localizedDescription)")
        }
    }

    private func seedSubjectDimension(zh: Bool) {
        let dim = makeBuiltIn(systemKey: "subject", name: zh ? "学科" : "Subject",
                              icon: "book.fill", isMultiValue: false, sortOrder: 0)
        seedValues(zh ? [
            ("语文", "book.fill", "#E57373"),
            ("数学", "function", "#4FC3F7"),
            ("英语", "character.textbox", "#AED581"),
            ("物理", "atom", "#7986CB"),
            ("化学", "flask.fill", "#F06292"),
            ("生物", "leaf.fill", "#81C784"),
            ("历史", "clock.fill", "#DCE775"),
            ("地理", "globe.asia.australia", "#4DB6AC"),
            ("政治", "person.2.fill", "#FFB74D")
        ] : [
            ("Math", "function", "#4FC3F7"),
            ("English", "character.textbox", "#AED581"),
            ("Physics", "atom", "#7986CB"),
            ("Chemistry", "flask.fill", "#F06292"),
            ("Biology", "leaf.fill", "#81C784"),
            ("History", "clock.fill", "#DCE775"),
            ("Geography", "globe.asia.australia", "#4DB6AC"),
            ("Art", "paintpalette.fill", "#FFB74D")
        ], into: dim)
    }

    private func seedSourceDimension(zh: Bool) {
        let dim = makeBuiltIn(systemKey: "source", name: zh ? "来源" : "Source",
                              icon: "doc.text.fill", isMultiValue: false, sortOrder: 1)
        seedValues(zh ? [
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
        ], into: dim)
    }

    private func seedGradeDimension(zh: Bool) {
        let dim = makeBuiltIn(systemKey: "grade", name: zh ? "年级" : "Grade",
                              icon: "graduationcap.fill", isMultiValue: false, sortOrder: 2)
        let names = zh
            ? ["小学", "初一", "初二", "初三", "高一", "高二", "高三"]
            : ["Elementary", "Middle School", "Grade 9", "Grade 10", "Grade 11", "Grade 12"]
        seedValues(names.map { ($0, "circle", "#808080") }, into: dim)
    }

    private func seedTagDimension(zh: Bool) {
        _ = makeBuiltIn(systemKey: "tag", name: zh ? "标签" : "Tag",
                        icon: "tag.fill", isMultiValue: true, sortOrder: 3)
    }

    /// 建一个内置维度并 insert（纯内存）
    private func makeBuiltIn(
        systemKey: String,
        name: String,
        icon: String,
        isMultiValue: Bool,
        sortOrder: Int
    ) -> CategoryDimensionModel {
        let dim = CategoryDimensionModel(
            name: name, isMultiValue: isMultiValue, isBuiltIn: true,
            systemKey: systemKey, sortOrder: sortOrder, icon: icon
        )
        modelContext.insert(dim)
        return dim
    }

    /// 为维度种入默认值（纯内存，调用方统一 save）
    private func seedValues(_ values: [(String, String, String)], into dim: CategoryDimensionModel) {
        for (index, value) in values.enumerated() {
            let model = CategoryValueModel(
                name: value.0, icon: value.1, colorHex: value.2, sortOrder: index, dimension: dim
            )
            modelContext.insert(model)
        }
    }
    // swiftlint:enable large_tuple

    // MARK: - Private Helpers

    private func fetchModelById(_ id: UUID) throws -> CategoryDimensionModel? {
        let target = id
        let predicate = #Predicate<CategoryDimensionModel> { $0.id == target }
        var descriptor = FetchDescriptor<CategoryDimensionModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
