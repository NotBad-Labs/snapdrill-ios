//
//  ReviewRepositoryDimensionFilterTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  动态维度筛选守护测试（L3）：fetchFilteredModels 的「维度间 AND / 维度内 OR」语义、
//  内存路径分页切片、category 维度值名排序；fetchSmartSelection 分类值筛选 + limit 截断。
//  （many-to-many 关系无法走 #Predicate，全部内存过滤，是必须守护的退化点。）
//

import Testing
import SwiftData
import Foundation
import SnapDrillCore
@testable import SnapDrillData

@Suite("ReviewRepository 动态维度筛选测试", .serialized)
final class ReviewRepositoryDimensionFilterTests {

    private let container: ModelContainer
    private let repos: RepositoryContainer

    init() throws {
        container = try TestModelContainer.create()
        repos = RepositoryContainer(modelContext: container.mainContext)
    }

    // MARK: - Fixture

    private struct Fixture {
        let categoryDim: CategoryDimensionModel
        let tagDim: CategoryDimensionModel
        let math: CategoryValueModel
        let english: CategoryValueModel
        let chinese: CategoryValueModel
        let mistake: CategoryValueModel   // 易错
        let key: CategoryValueModel       // 重点
    }

    private func makeFixture() throws -> Fixture {
        let categoryDim = CategoryDimensionModel(
            name: "分类", isMultiValue: false, isBuiltIn: true,
            systemKey: CategorySystemKey.category, sortOrder: 0
        )
        try repos.dimension.insertAndSave(categoryDim)
        let tagDim = CategoryDimensionModel(
            name: "标签", isMultiValue: true, isBuiltIn: true,
            systemKey: CategorySystemKey.tag, sortOrder: 1
        )
        try repos.dimension.insertAndSave(tagDim)

        func value(_ name: String, in dim: CategoryDimensionModel, order: Int) throws -> CategoryValueModel {
            let v = CategoryValueModel(name: name, sortOrder: order, dimension: dim)
            try repos.categoryValue.insertAndSave(v)
            return v
        }
        return Fixture(
            categoryDim: categoryDim, tagDim: tagDim,
            math: try value("数学", in: categoryDim, order: 0),
            english: try value("英语", in: categoryDim, order: 1),
            chinese: try value("语文", in: categoryDim, order: 2),
            mistake: try value("易错", in: tagDim, order: 0),
            key: try value("重点", in: tagDim, order: 1)
        )
    }

    @discardableResult
    private func makeItem(
        _ content: String,
        values: [CategoryValueModel],
        difficulty: Int = 1
    ) throws -> ReviewItemModel {
        let item = ReviewItemModel(content: content, difficulty: difficulty)
        item.categoryValues = values
        repos.review.insert(item)
        try repos.review.saveContext()
        return item
    }

    // MARK: - 维度间 AND / 维度内 OR

    @Test("维度间 AND：同时命中分类与标签才入选")
    func filter_acrossDimensions_isAND() throws {
        let f = try makeFixture()
        try makeItem("数学易错题", values: [f.math, f.mistake])
        try makeItem("英语易错题", values: [f.english, f.mistake])
        try makeItem("数学重点题", values: [f.math, f.key])

        let result = try repos.review.fetchFilteredModels(
            searchText: "",
            valueIdsByDimension: [f.categoryDim.id: [f.math.id], f.tagDim.id: [f.mistake.id]],
            limit: 50, offset: 0
        )
        #expect(result.map(\.content) == ["数学易错题"])
    }

    @Test("维度内 OR：选中分类多个值取并集")
    func filter_withinDimension_isOR() throws {
        let f = try makeFixture()
        try makeItem("数学题", values: [f.math])
        try makeItem("英语题", values: [f.english])
        try makeItem("语文题", values: [f.chinese])

        let result = try repos.review.fetchFilteredModels(
            searchText: "",
            valueIdsByDimension: [f.categoryDim.id: [f.math.id, f.english.id]],
            limit: 50, offset: 0
        )
        #expect(Set(result.map(\.content)) == ["数学题", "英语题"])
    }

    @Test("空筛选返回全部（DB 高效路径）")
    func filter_empty_returnsAll() throws {
        let f = try makeFixture()
        try makeItem("题1", values: [f.math])
        try makeItem("题2", values: [f.english])

        let result = try repos.review.fetchFilteredModels(
            searchText: "", valueIdsByDimension: [:], limit: 50, offset: 0
        )
        #expect(result.count == 2)
    }

    @Test("搜索文本 + 维度值组合过滤")
    func filter_searchTextWithDimension() throws {
        let f = try makeFixture()
        try makeItem("抛物线数学题", values: [f.math])
        try makeItem("几何数学题", values: [f.math])

        let result = try repos.review.fetchFilteredModels(
            searchText: "抛物线",
            valueIdsByDimension: [f.categoryDim.id: [f.math.id]],
            limit: 50, offset: 0
        )
        #expect(result.map(\.content) == ["抛物线数学题"])
    }

    @Test("维度候选集路径组合搜索、难度与分页")
    func filter_candidatePath_combinesSearchDifficultyAndPagination() throws {
        let f = try makeFixture()
        for i in 0..<20 {
            try makeItem("抛物线英语干扰项\(i)", values: [f.english], difficulty: 3)
        }
        try makeItem("抛物线数学低难度", values: [f.math], difficulty: 1)
        try makeItem("抛物线数学目标A", values: [f.math], difficulty: 3)
        try makeItem("抛物线数学目标B", values: [f.math], difficulty: 3)

        let filter: [UUID: Set<UUID>] = [f.categoryDim.id: [f.math.id]]
        let page1 = try repos.review.fetchFilteredModels(
            searchText: "抛物线", valueIdsByDimension: filter,
            difficulties: [3], limit: 1, offset: 0
        )
        let page2 = try repos.review.fetchFilteredModels(
            searchText: "抛物线", valueIdsByDimension: filter,
            difficulties: [3], limit: 1, offset: 1
        )
        let page3 = try repos.review.fetchFilteredModels(
            searchText: "抛物线", valueIdsByDimension: filter,
            difficulties: [3], limit: 1, offset: 2
        )

        #expect(Set((page1 + page2).compactMap(\.content)) == ["抛物线数学目标A", "抛物线数学目标B"])
        #expect(page3.isEmpty)
    }

    // MARK: - 分页（内存路径）

    @Test("维度过滤下分页切片正确、无重复、覆盖全部")
    func filter_pagination_memoryPath() throws {
        let f = try makeFixture()
        for i in 0..<5 {
            try makeItem("数学题\(i)", values: [f.math])
        }
        let filter: [UUID: Set<UUID>] = [f.categoryDim.id: [f.math.id]]

        let page1 = try repos.review.fetchFilteredModels(
            searchText: "", valueIdsByDimension: filter, limit: 2, offset: 0
        )
        let page2 = try repos.review.fetchFilteredModels(
            searchText: "", valueIdsByDimension: filter, limit: 2, offset: 2
        )
        let page3 = try repos.review.fetchFilteredModels(
            searchText: "", valueIdsByDimension: filter, limit: 2, offset: 4
        )
        #expect(page1.count == 2)
        #expect(page2.count == 2)
        #expect(page3.count == 1)
        let all = Set((page1 + page2 + page3).compactMap(\.content))
        #expect(all.count == 5)   // 三页拼接无重复、覆盖全部 5 条
    }

    @Test("offset 超出结果数返回空")
    func filter_offsetBeyondCount_returnsEmpty() throws {
        let f = try makeFixture()
        try makeItem("数学题", values: [f.math])
        let result = try repos.review.fetchFilteredModels(
            searchText: "", valueIdsByDimension: [f.categoryDim.id: [f.math.id]],
            limit: 50, offset: 10
        )
        #expect(result.isEmpty)
    }

    // MARK: - category 维度值名排序

    @Test("sortByCategoryName 按分类值名升序")
    func filter_sortByCategoryName() throws {
        let f = try makeFixture()
        try makeItem("英语题", values: [f.english])
        try makeItem("数学题", values: [f.math])
        try makeItem("语文题", values: [f.chinese])

        let result = try repos.review.fetchFilteredModels(
            searchText: "", valueIdsByDimension: [:],
            sortByCategoryName: true, limit: 50, offset: 0
        )
        let names = result.map { $0.primaryCategoryName ?? "" }
        #expect(names.count == 3)
        #expect(names == names.sorted())   // 升序，与值名 < 关系一致
    }

    // MARK: - fetchSmartSelection 分类值筛选

    @Test("fetchSmartSelection 按分类值筛选 + limit 截断")
    func smartSelection_subjectFilter() throws {
        let f = try makeFixture()
        try makeItem("数学1", values: [f.math])
        try makeItem("数学2", values: [f.math])
        try makeItem("英语1", values: [f.english])

        let result = try repos.review.fetchSmartSelection(limit: 10, categoryValueIds: [f.math.id])
        #expect(Set(result.map { $0.content ?? "" }) == ["数学1", "数学2"])

        let limited = try repos.review.fetchSmartSelection(limit: 1, categoryValueIds: [f.math.id])
        #expect(limited.count == 1)
    }

    @Test("fetchSmartSelection 空分类筛选返回全部（limit 内）")
    func smartSelection_noSubjectFilter() throws {
        let f = try makeFixture()
        try makeItem("题1", values: [f.math])
        try makeItem("题2", values: [f.english])

        let result = try repos.review.fetchSmartSelection(limit: 10)
        #expect(result.count == 2)
    }
}
