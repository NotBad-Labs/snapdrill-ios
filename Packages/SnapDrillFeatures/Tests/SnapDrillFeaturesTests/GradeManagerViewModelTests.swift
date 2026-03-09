//
//  GradeManagerViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/03/09.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  GradeManagerViewModel 核心路径单元测试：增删改查与使用中保护。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillFeatureLibrary
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("GradeManagerViewModel 年级管理测试", .serialized)
@MainActor
final class GradeManagerViewModelTests {

    private let container: ModelContainer
    private let repos: RepositoryContainer

    init() throws {
        let schema = Schema([
            ReviewItemModel.self,
            TagModel.self,
            SubjectModel.self,
            SourceModel.self,
            GradeModel.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        repos = RepositoryContainer(modelContext: container.mainContext)
    }

    // MARK: - loadData

    @Test("loadData 空数据库返回空列表")
    func loadData_empty() {
        let vm = GradeManagerViewModel(repositories: repos)
        vm.loadData()
        #expect(vm.grades.isEmpty)
    }

    @Test("loadData 加载已有年级")
    func loadData_loadsGrades() throws {
        let grade = GradeModel(name: "三年级", sortOrder: 0)
        try repos.grade.insertAndSave(grade)

        let vm = GradeManagerViewModel(repositories: repos)
        vm.loadData()

        #expect(vm.grades.count == 1)
        #expect(vm.grades.first?.name == "三年级")
    }

    // MARK: - saveGrade（新建）

    @Test("saveGrade 新建年级")
    func saveGrade_creates() {
        let vm = GradeManagerViewModel(repositories: repos)

        vm.saveGrade(grade: nil, name: "五年级")

        #expect(vm.grades.count == 1)
        #expect(vm.grades.first?.name == "五年级")
    }

    // MARK: - saveGrade（编辑）

    @Test("saveGrade 编辑年级名称并级联更新题目")
    func saveGrade_editsAndCascades() throws {
        let grade = GradeModel(name: "三年级", sortOrder: 0)
        try repos.grade.insertAndSave(grade)
        let item = ReviewItemModel(content: "题目", grade: "三年级")
        repos.review.insert(item)
        try repos.review.saveContext()

        let vm = GradeManagerViewModel(repositories: repos)
        vm.loadData()

        vm.saveGrade(grade: vm.grades.first, name: "四年级")

        #expect(vm.grades.first?.name == "四年级")
        #expect(item.grade == "四年级")
    }

    // MARK: - delete

    @Test("delete 删除未使用的年级")
    func delete_removesUnused() throws {
        let grade = GradeModel(name: "六年级", sortOrder: 0)
        try repos.grade.insertAndSave(grade)

        let vm = GradeManagerViewModel(repositories: repos)
        vm.loadData()
        #expect(vm.grades.count == 1)

        vm.delete(at: IndexSet(integer: 0))

        #expect(vm.grades.isEmpty)
        #expect(vm.isDeletingInUse == false)
    }

    @Test("delete 阻止删除使用中的年级")
    func delete_blocksInUse() throws {
        let grade = GradeModel(name: "三年级", sortOrder: 0)
        try repos.grade.insertAndSave(grade)
        let item = ReviewItemModel(content: "题目", grade: "三年级")
        repos.review.insert(item)
        try repos.review.saveContext()

        let vm = GradeManagerViewModel(repositories: repos)
        vm.loadData()

        vm.delete(at: IndexSet(integer: 0))

        #expect(vm.isDeletingInUse == true)
        #expect(vm.pendingDeletionName == "三年级")
        #expect(vm.grades.count == 1)
    }
}
