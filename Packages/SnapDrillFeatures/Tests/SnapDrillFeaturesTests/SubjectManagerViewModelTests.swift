//
//  SubjectManagerViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/03/09.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SubjectManagerViewModel 核心路径单元测试：增删改查与使用中保护。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillFeatureLibrary
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("SubjectManagerViewModel 学科管理测试", .serialized)
@MainActor
final class SubjectManagerViewModelTests {

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
        let vm = SubjectManagerViewModel(repositories: repos)
        vm.loadData()
        #expect(vm.subjects.isEmpty)
    }

    @Test("loadData 加载已有学科")
    func loadData_loadsSubjects() throws {
        let subject = SubjectModel(name: "数学", icon: "function", colorHex: "#FF0000", sortOrder: 0)
        try repos.subject.insertAndSave(subject)

        let vm = SubjectManagerViewModel(repositories: repos)
        vm.loadData()

        #expect(vm.subjects.count == 1)
        #expect(vm.subjects.first?.name == "数学")
    }

    // MARK: - saveSubject（新建）

    @Test("saveSubject 新建学科")
    func saveSubject_creates() {
        let vm = SubjectManagerViewModel(repositories: repos)

        vm.saveSubject(subject: nil, name: "英语", selectedIcon: "book", finalColorHex: "#0000FF")

        #expect(vm.subjects.count == 1)
        #expect(vm.subjects.first?.name == "英语")
        #expect(vm.subjects.first?.icon == "book")
    }

    // MARK: - saveSubject（编辑）

    @Test("saveSubject 编辑学科名称并级联更新题目")
    func saveSubject_editsAndCascades() throws {
        let subject = SubjectModel(name: "数学", icon: "function", colorHex: "#FF0000", sortOrder: 0)
        try repos.subject.insertAndSave(subject)
        let item = ReviewItemModel(content: "题目", subject: "数学")
        repos.review.insert(item)
        try repos.review.saveContext()

        let vm = SubjectManagerViewModel(repositories: repos)
        vm.loadData()

        vm.saveSubject(subject: vm.subjects.first, name: "高等数学", selectedIcon: "function", finalColorHex: "#FF0000")

        #expect(vm.subjects.first?.name == "高等数学")
        #expect(item.subject == "高等数学")
    }

    // MARK: - delete

    @Test("delete 删除未使用的学科")
    func delete_removesUnused() throws {
        let subject = SubjectModel(name: "物理", icon: "atom", colorHex: "#00FF00", sortOrder: 0)
        try repos.subject.insertAndSave(subject)

        let vm = SubjectManagerViewModel(repositories: repos)
        vm.loadData()
        #expect(vm.subjects.count == 1)

        vm.delete(at: IndexSet(integer: 0))

        #expect(vm.subjects.isEmpty)
        #expect(vm.isDeletingInUse == false)
    }

    @Test("delete 阻止删除使用中的学科")
    func delete_blocksInUse() throws {
        let subject = SubjectModel(name: "数学", icon: "function", colorHex: "#FF0000", sortOrder: 0)
        try repos.subject.insertAndSave(subject)
        let item = ReviewItemModel(content: "题目", subject: "数学")
        repos.review.insert(item)
        try repos.review.saveContext()

        let vm = SubjectManagerViewModel(repositories: repos)
        vm.loadData()

        vm.delete(at: IndexSet(integer: 0))

        #expect(vm.isDeletingInUse == true)
        #expect(vm.pendingDeletionName == "数学")
        #expect(vm.subjects.count == 1)
    }

    // MARK: - 边界条件

    @Test("saveSubject 重命名为已存在的学科名称时题目级联正确")
    func saveSubject_renameToExistingName() throws {
        // 准备两个学科
        let subjectA = SubjectModel(name: "数学", icon: "function", colorHex: "#FF0000", sortOrder: 0)
        let subjectB = SubjectModel(name: "物理", icon: "atom", colorHex: "#00FF00", sortOrder: 1)
        try repos.subject.insertAndSave(subjectA)
        try repos.subject.insertAndSave(subjectB)

        // 一道数学题
        let item = ReviewItemModel(content: "数学题", subject: "数学")
        repos.review.insert(item)
        try repos.review.saveContext()

        let vm = SubjectManagerViewModel(repositories: repos)
        vm.loadData()

        // 将"数学"重命名为"物理"（已存在的名称）
        let mathSubject = vm.subjects.first(where: { $0.name == "数学" })
        vm.saveSubject(subject: mathSubject, name: "物理", selectedIcon: "function", finalColorHex: "#FF0000")

        // 题目应级联更新到"物理"
        #expect(item.subject == "物理")

        // Known limitation: 生产代码不阻止重名，重命名后会产生两个同名 Model
        // 见 Issue #370
        let physicsCount = vm.subjects.filter { $0.name == "物理" }.count
        #expect(physicsCount == 2, "当前行为：重命名产生两个同名选项（#370 修复后应为 1）")
    }
}
