//
//  CategoryRepositoryTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  动态维度系统守护测试（L3）：CategoryDimensionRepository / CategoryValueRepository
//  的 CRUD、约束（维度名唯一 / 维度内值唯一 / 跨维度同名 / 内置不可删）、
//  级联删除解题目引用、重命名传播（关系引用语义，无字段拷贝 desync）。
//

import Testing
import SwiftData
import Foundation
import SnapDrillCore
@testable import SnapDrillData

@Suite("CategoryRepository 维度/值 CRUD 与约束守护测试")
final class CategoryRepositoryTests {

    private let container: ModelContainer
    private let repos: RepositoryContainer

    init() throws {
        container = try TestModelContainer.create()
        repos = RepositoryContainer(modelContext: container.mainContext)
    }

    // MARK: - Helpers

    @discardableResult
    private func makeDimension(
        name: String,
        systemKey: String? = nil,
        isMultiValue: Bool = false,
        isBuiltIn: Bool = false,
        sortOrder: Int = 0
    ) throws -> CategoryDimensionModel {
        let dim = CategoryDimensionModel(
            name: name, isMultiValue: isMultiValue, isBuiltIn: isBuiltIn,
            systemKey: systemKey, sortOrder: sortOrder, icon: "tag"
        )
        try repos.dimension.insertAndSave(dim)
        return dim
    }

    @discardableResult
    private func makeValue(_ name: String, in dim: CategoryDimensionModel, sortOrder: Int = 0) throws -> CategoryValueModel {
        let value = CategoryValueModel(name: name, sortOrder: sortOrder, dimension: dim)
        try repos.categoryValue.insertAndSave(value)
        return value
    }

    /// 全局统计 CategoryValueModel 行数（whitebox：维度删除后无法经维度反查值是否级联清除）
    private func totalValueCount() throws -> Int {
        try container.mainContext.fetchCount(FetchDescriptor<CategoryValueModel>())
    }

    private func refetchItem(_ id: UUID) throws -> ArchiveItemModel {
        let model = try repos.archive.fetchModel(by: id)
        return try #require(model)
    }

    // MARK: - 维度 CRUD

    @Test("fetchAllModels 按 sortOrder 升序返回")
    func dimensions_fetchAll_sortedBySortOrder() throws {
        try makeDimension(name: "B维度", sortOrder: 2)
        try makeDimension(name: "A维度", sortOrder: 0)
        try makeDimension(name: "C维度", sortOrder: 1)

        let dims = try repos.dimension.fetchAllModels()
        #expect(dims.map(\.name) == ["A维度", "C维度", "B维度"])
    }

    @Test("fetchDimension(bySystemKey:) 命中内置维度，未知 key 返回 nil")
    func dimensions_fetchBySystemKey() throws {
        try makeDimension(name: "分类", systemKey: CategorySystemKey.category, isBuiltIn: true)

        let found = try repos.dimension.fetchDimension(bySystemKey: CategorySystemKey.category)
        #expect(found?.name == "分类")
        let missing = try repos.dimension.fetchDimension(bySystemKey: "nonexistent")
        #expect(missing == nil)
    }

    @Test("totalCount 反映已插入维度数")
    func dimensions_totalCount() throws {
        #expect(try repos.dimension.totalCount() == 0)
        try makeDimension(name: "维度1")
        try makeDimension(name: "维度2")
        #expect(try repos.dimension.totalCount() == 2)
    }

    @Test("维度名唯一：插入同名维度抛 duplicateName")
    func dimensions_duplicateName_throws() throws {
        try makeDimension(name: "分类")
        let dup = CategoryDimensionModel(name: "分类")
        #expect(throws: DataError.self) {
            try self.repos.dimension.insertAndSave(dup)
        }
        #expect(try repos.dimension.totalCount() == 1)
    }

    @Test("删除用户维度：级联删除其值 + 解题目反向引用")
    func dimensions_deleteUser_cascadesValuesAndDetachesItems() throws {
        let dim = try makeDimension(name: "章节")
        let value = try makeValue("第一章", in: dim)
        let item = ArchiveItemModel(content: "测试题")
        item.categoryValues = [value]
        repos.archive.insert(item)
        try repos.archive.saveContext()
        #expect(try totalValueCount() == 1)

        try repos.dimension.delete(id: dim.id)

        #expect(try repos.dimension.totalCount() == 0)
        #expect(try totalValueCount() == 0)               // 值级联删除
        let refetched = try refetchItem(item.id)
        #expect((refetched.categoryValues ?? []).isEmpty) // 题目引用已解
    }

    @Test("内置维度不可删：delete 静默跳过，维度仍在")
    func dimensions_deleteBuiltIn_isNoOp() throws {
        let dim = try makeDimension(name: "分类", systemKey: CategorySystemKey.category, isBuiltIn: true)
        try repos.dimension.delete(id: dim.id)
        #expect(try repos.dimension.totalCount() == 1)
    }

    // MARK: - 值 CRUD 与约束

    @Test("fetchAllModels(in:) 按 sortOrder 升序")
    func values_fetchInDimension_sorted() throws {
        let dim = try makeDimension(name: "分类")
        try makeValue("数学", in: dim, sortOrder: 1)
        try makeValue("语文", in: dim, sortOrder: 0)

        let values = repos.categoryValue.fetchAllModels(in: dim)
        #expect(values.map(\.name) == ["语文", "数学"])
    }

    @Test("fetchModel(byName:in:) 维度内命中 / 不存在返回 nil")
    func values_fetchByName() throws {
        let dim = try makeDimension(name: "分类")
        try makeValue("数学", in: dim)
        #expect(repos.categoryValue.fetchModel(byName: "数学", in: dim)?.name == "数学")
        #expect(repos.categoryValue.fetchModel(byName: "英语", in: dim) == nil)
    }

    @Test("维度内值唯一：同维度同名抛 duplicateName")
    func values_duplicateWithinDimension_throws() throws {
        let dim = try makeDimension(name: "分类")
        try makeValue("数学", in: dim)
        let dup = CategoryValueModel(name: "数学", dimension: dim)
        #expect(throws: DataError.self) {
            try self.repos.categoryValue.insertAndSave(dup)
        }
    }

    @Test("跨维度允许同名：分类'其他' 与 来源'其他' 共存")
    func values_crossDimensionSameName_allowed() throws {
        let category = try makeDimension(name: "分类", systemKey: CategorySystemKey.category, sortOrder: 0)
        let source = try makeDimension(name: "来源", systemKey: CategorySystemKey.source, sortOrder: 1)
        try makeValue("其他", in: category)
        try makeValue("其他", in: source)   // 不应抛错
        #expect(repos.categoryValue.fetchModel(byName: "其他", in: category) != nil)
        #expect(repos.categoryValue.fetchModel(byName: "其他", in: source) != nil)
    }

    @Test("fetchOrCreate：已存在返回原值，不存在则新建并追加 sortOrder")
    func values_fetchOrCreate() throws {
        let dim = try makeDimension(name: "标签", isMultiValue: true)
        let first = try makeValue("易错", in: dim, sortOrder: 0)

        // 已存在：返回同一对象
        let existing = repos.categoryValue.fetchOrCreate(name: "易错", in: dim)
        #expect(existing.id == first.id)

        // 不存在：新建，sortOrder 追加到末尾（=values.count）
        let created = repos.categoryValue.fetchOrCreate(name: "重点", in: dim)
        try repos.categoryValue.saveContext()
        #expect(created.name == "重点")
        #expect(created.sortOrder == 1)
        #expect(repos.categoryValue.fetchAllModels(in: dim).count == 2)
    }

    @Test("删除值：解题目反向引用")
    func values_delete_detachesItemReferences() throws {
        let dim = try makeDimension(name: "分类")
        let value = try makeValue("数学", in: dim)
        let item = ArchiveItemModel(content: "数学题")
        item.categoryValues = [value]
        repos.archive.insert(item)
        try repos.archive.saveContext()

        try repos.categoryValue.delete(id: value.id)

        let refetched = try refetchItem(item.id)
        #expect((refetched.categoryValues ?? []).isEmpty)
    }

    // MARK: - 重命名传播（关系引用语义）

    @Test("重命名值：所有引用题目自动跟随（无字段拷贝 desync）")
    func values_rename_propagatesToReferencingItems() throws {
        let dim = try makeDimension(name: "分类", systemKey: CategorySystemKey.category, isBuiltIn: true)
        let value = try makeValue("数学", in: dim)
        let item = ArchiveItemModel(content: "题")
        item.categoryValues = [value]
        repos.archive.insert(item)
        try repos.archive.saveContext()
        #expect(item.primaryCategoryName == "数学")

        value.name = "高等数学"
        try repos.categoryValue.saveContext()

        // 重新 fetch 题目（非依赖同一引用），值名自动跟随
        let refetched = try refetchItem(item.id)
        #expect(refetched.primaryCategoryName == "高等数学")
    }
}
