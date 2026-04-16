//
//  SourceRepositoryTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs on 2026/03/10.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SourceRepository CRUD、唯一性约束与种子数据测试。
//

import Testing
import SwiftData

import Foundation
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("SourceRepository 单元测试", .serialized)
final class SourceRepositoryTests {

    private let container: ModelContainer
    private let repo: SourceRepository

    init() throws {
        container = try TestModelContainer.create()
        repo = SourceRepository(modelContext: container.mainContext)
    }

    // MARK: - CRUD

    @Test("insertAndSave 后 totalCount 递增")
    func insertAndSave_incrementsCount() throws {
        #expect(try repo.totalCount() == 0)

        try repo.insertAndSave(SourceModel.mock(name: "试卷"))
        #expect(try repo.totalCount() == 1)
    }

    @Test("fetchAllModels 按 sortOrder 排序")
    func fetchAllModels_sortedBySortOrder() throws {
        try repo.insertAndSave(SourceModel.mock(name: "教材", sortOrder: 2))
        try repo.insertAndSave(SourceModel.mock(name: "试卷", sortOrder: 0))
        try repo.insertAndSave(SourceModel.mock(name: "作业", sortOrder: 1))

        let all = try repo.fetchAllModels()
        #expect(all.map(\.name) == ["试卷", "作业", "教材"])
    }

    @Test("fetchModel(byName:) 精确匹配")
    func fetchByName_returnsCorrectModel() throws {
        try repo.insertAndSave(SourceModel.mock(name: "试卷"))

        #expect(try repo.fetchModel(byName: "试卷")?.name == "试卷")
        #expect(try repo.fetchModel(byName: "不存在") == nil)
    }

    @Test("delete 成功移除指定项")
    func delete_removesItem() throws {
        let model = SourceModel.mock(name: "试卷")
        try repo.insertAndSave(model)

        try repo.delete(id: model.id)
        #expect(try repo.totalCount() == 0)
    }

    @Test("delete 不存在的 ID 不崩溃")
    func delete_nonExistentId_noCrash() throws {
        try repo.delete(id: UUID())
    }

    // MARK: - 唯一性约束

    @Test("insertAndSave 重复名称抛出 duplicateName")
    func insertAndSave_duplicateName_throws() throws {
        try repo.insertAndSave(SourceModel.mock(name: "试卷"))

        #expect(throws: DataError.self) {
            try repo.insertAndSave(SourceModel.mock(name: "试卷"))
        }
    }

    // MARK: - seedDefaultsIfNeeded

    @Test("seedDefaultsIfNeeded 空库时插入预设数据")
    func seedDefaults_emptyDB_seedsData() throws {
        repo.seedDefaultsIfNeeded()
        #expect(try repo.totalCount() > 0)
    }

    @Test("seedDefaultsIfNeeded 非空库时不重复插入")
    func seedDefaults_nonEmptyDB_noOp() throws {
        try repo.insertAndSave(SourceModel.mock(name: "自定义"))
        let countBefore = try repo.totalCount()

        repo.seedDefaultsIfNeeded()
        #expect(try repo.totalCount() == countBefore)
    }

    // MARK: - deleteAll

    @Test("deleteAll 清空所有数据")
    func deleteAll_removesAll() throws {
        try repo.insertAndSave(SourceModel.mock(name: "试卷"))
        try repo.insertAndSave(SourceModel.mock(name: "作业"))

        try repo.deleteAll()
        try repo.saveContext()
        #expect(try repo.totalCount() == 0)
    }
}
