//
//  CategorySeedTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  内置维度 seed 守护测试（L3）：4 内置维度结构、单/多值、systemKey、
//  值数量（按 locale 运行时探测，不硬编码单一数字）、幂等（重复调用不重复种入）。
//

import Testing
import SwiftData
import Foundation
import SnapDrillCore
@testable import SnapDrillData

@Suite("Category seed 内置维度守护测试")
final class CategorySeedTests {

    private let container: ModelContainer
    private let repos: RepositoryContainer
    /// 运行时探测语言分支——seed 值数量随 locale 变化，不可硬编码单一数字
    private let isZh = Locale.current.language.languageCode?.identifier == "zh"

    init() throws {
        container = try TestModelContainer.create()
        repos = RepositoryContainer(modelContext: container.mainContext)
    }

    private func dimension(_ key: String) throws -> CategoryDimensionModel {
        let fetched = try repos.dimension.fetchDimension(bySystemKey: key)
        return try #require(fetched)
    }

    private func globalValueCount() throws -> Int {
        try container.mainContext.fetchCount(FetchDescriptor<CategoryValueModel>())
    }

    @Test("seedDefaultsIfNeeded 创建 4 个内置维度，systemKey 齐全")
    func seed_createsFourBuiltInDimensions() throws {
        repos.dimension.seedDefaultsIfNeeded()

        let dims = try repos.dimension.fetchAllModels()
        #expect(dims.count == 4)
        #expect(dims.allSatisfy { $0.isBuiltIn })
        let keys = Set(dims.compactMap(\.systemKey))
        #expect(keys == [
            CategorySystemKey.category, CategorySystemKey.source,
            CategorySystemKey.level, CategorySystemKey.tag
        ])
    }

    @Test("标签维度多值且无默认值；分类/来源/级别单值且有默认值")
    func seed_dimensionFlagsAndValuePresence() throws {
        repos.dimension.seedDefaultsIfNeeded()

        let tag = try dimension(CategorySystemKey.tag)
        #expect(tag.isMultiValue == true)
        #expect(repos.categoryValue.fetchAllModels(in: tag).isEmpty)

        for key in [CategorySystemKey.category, CategorySystemKey.source, CategorySystemKey.level] {
            let dim = try dimension(key)
            #expect(dim.isMultiValue == false)
            #expect(!repos.categoryValue.fetchAllModels(in: dim).isEmpty)
        }
    }

    @Test("seed 值数量符合当前 locale 分支")
    func seed_valueCountsMatchLocale() throws {
        repos.dimension.seedDefaultsIfNeeded()

        let category = try dimension(CategorySystemKey.category)
        let source = try dimension(CategorySystemKey.source)
        let level = try dimension(CategorySystemKey.level)

        #expect(repos.categoryValue.fetchAllModels(in: category).count == 6)
        #expect(repos.categoryValue.fetchAllModels(in: source).count == 5)
        #expect(repos.categoryValue.fetchAllModels(in: level).count == 4)
    }

    @Test("seed 内置维度使用通用资料归档命名")
    func seed_usesGeneralAudienceTaxonomyNames() throws {
        repos.dimension.seedDefaultsIfNeeded()

        let category = try dimension(CategorySystemKey.category)
        let level = try dimension(CategorySystemKey.level)
        let categoryValues = repos.categoryValue.fetchAllModels(in: category).map(\.name)
        let levelValues = repos.categoryValue.fetchAllModels(in: level).map(\.name)

        #expect(category.name == (isZh ? "分类" : "Category"))
        #expect(level.name == (isZh ? "级别" : "Level"))
        #expect(categoryValues.contains(isZh ? "题目" : "Questions"))
        #expect(levelValues.contains(isZh ? "基础" : "Basic"))
    }

    @Test("seed 幂等：重复调用不重复种入")
    func seed_isIdempotent() throws {
        repos.dimension.seedDefaultsIfNeeded()
        let dimCountAfterFirst = try repos.dimension.totalCount()
        let valueCountAfterFirst = try globalValueCount()

        repos.dimension.seedDefaultsIfNeeded()  // 第二次调用

        #expect(try repos.dimension.totalCount() == dimCountAfterFirst)
        #expect(try globalValueCount() == valueCountAfterFirst)
    }
}
