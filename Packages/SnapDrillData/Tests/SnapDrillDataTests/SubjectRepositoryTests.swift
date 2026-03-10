//
//  SubjectRepositoryTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs on 2026/03/10.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SubjectRepository CRUD、唯一性约束与种子数据测试。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("SubjectRepository 单元测试", .serialized)
@MainActor
struct SubjectRepositoryTests {

    private func createRepo() throws -> SubjectRepository {
        let container = try TestModelContainer.create()
        return SubjectRepository(modelContext: container.mainContext)
    }

    // MARK: - CRUD

    @Test("insertAndSave 后 totalCount 递增")
    func insertAndSave_incrementsCount() throws {
        let repo = try createRepo()
        #expect(try repo.totalCount() == 0)

        let model = SubjectModel.mock(name: "数学")
        try repo.insertAndSave(model)

        #expect(try repo.totalCount() == 1)
    }

    @Test("fetchAllModels 按 sortOrder 排序")
    func fetchAllModels_sortedBySortOrder() throws {
        let repo = try createRepo()
        try repo.insertAndSave(SubjectModel.mock(name: "英语", sortOrder: 2))
        try repo.insertAndSave(SubjectModel.mock(name: "数学", sortOrder: 0))
        try repo.insertAndSave(SubjectModel.mock(name: "物理", sortOrder: 1))

        let all = try repo.fetchAllModels()
        #expect(all.map(\.name) == ["数学", "物理", "英语"])
    }

    @Test("fetchModel(byName:) 精确匹配")
    func fetchByName_returnsCorrectModel() throws {
        let repo = try createRepo()
        try repo.insertAndSave(SubjectModel.mock(name: "数学"))
        try repo.insertAndSave(SubjectModel.mock(name: "英语"))

        let found = try repo.fetchModel(byName: "英语")
        #expect(found?.name == "英语")

        let notFound = try repo.fetchModel(byName: "化学")
        #expect(notFound == nil)
    }

    @Test("delete 成功移除指定项")
    func delete_removesItem() throws {
        let repo = try createRepo()
        let model = SubjectModel.mock(name: "数学")
        try repo.insertAndSave(model)
        #expect(try repo.totalCount() == 1)

        try repo.delete(id: model.id)
        #expect(try repo.totalCount() == 0)
    }

    @Test("delete 不存在的 ID 不崩溃")
    func delete_nonExistentId_noCrash() throws {
        let repo = try createRepo()
        try repo.delete(id: UUID())
        #expect(try repo.totalCount() == 0)
    }

    // MARK: - 唯一性约束

    @Test("insertAndSave 重复名称抛出 duplicateName")
    func insertAndSave_duplicateName_throws() throws {
        let repo = try createRepo()
        try repo.insertAndSave(SubjectModel.mock(name: "数学"))

        #expect(throws: DataError.self) {
            try repo.insertAndSave(SubjectModel.mock(name: "数学"))
        }
    }

    // MARK: - seedDefaultsIfNeeded

    @Test("seedDefaultsIfNeeded 空库时插入预设数据")
    func seedDefaults_emptyDB_seedsData() throws {
        let repo = try createRepo()
        #expect(try repo.totalCount() == 0)

        repo.seedDefaultsIfNeeded()

        #expect(try repo.totalCount() > 0)
    }

    @Test("seedDefaultsIfNeeded 非空库时不重复插入")
    func seedDefaults_nonEmptyDB_noOp() throws {
        let repo = try createRepo()
        try repo.insertAndSave(SubjectModel.mock(name: "自定义"))
        let countBefore = try repo.totalCount()

        repo.seedDefaultsIfNeeded()

        #expect(try repo.totalCount() == countBefore)
    }

    // MARK: - deleteAll

    @Test("deleteAll 清空所有数据")
    func deleteAll_removesAll() throws {
        let repo = try createRepo()
        try repo.insertAndSave(SubjectModel.mock(name: "数学"))
        try repo.insertAndSave(SubjectModel.mock(name: "英语"))

        try repo.deleteAll()
        try repo.saveContext()

        #expect(try repo.totalCount() == 0)
    }
}
