//
//  SourceManagerViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/03/09.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SourceManagerViewModel 核心路径单元测试：增删改查与使用中保护。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillFeatureLibrary
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("SourceManagerViewModel 来源管理测试", .serialized)
@MainActor
final class SourceManagerViewModelTests {

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
        let vm = SourceManagerViewModel(repositories: repos)
        vm.loadData()
        #expect(vm.sources.isEmpty)
    }

    @Test("loadData 加载已有来源")
    func loadData_loadsSources() throws {
        let source = SourceModel(name: "试卷", icon: "doc.text", colorHex: "#808080", sortOrder: 0)
        try repos.source.insertAndSave(source)

        let vm = SourceManagerViewModel(repositories: repos)
        vm.loadData()

        #expect(vm.sources.count == 1)
        #expect(vm.sources.first?.name == "试卷")
    }

    // MARK: - saveSource（新建）

    @Test("saveSource 新建来源")
    func saveSource_creates() {
        let vm = SourceManagerViewModel(repositories: repos)

        vm.saveSource(source: nil, name: "课本", selectedIcon: "book", finalColorHex: "#0000FF")

        #expect(vm.sources.count == 1)
        #expect(vm.sources.first?.name == "课本")
    }

    // MARK: - saveSource（编辑）

    @Test("saveSource 编辑来源名称并级联更新题目")
    func saveSource_editsAndCascades() throws {
        let source = SourceModel(name: "试卷", icon: "doc.text", colorHex: "#808080", sortOrder: 0)
        try repos.source.insertAndSave(source)
        let item = ReviewItemModel(content: "题目", source: "试卷")
        repos.review.insert(item)
        try repos.review.saveContext()

        let vm = SourceManagerViewModel(repositories: repos)
        vm.loadData()

        vm.saveSource(source: vm.sources.first, name: "作业", selectedIcon: "doc.text", finalColorHex: "#808080")

        #expect(vm.sources.first?.name == "作业")
        #expect(item.source == "作业")
    }

    // MARK: - delete

    @Test("delete 删除未使用的来源")
    func delete_removesUnused() throws {
        let source = SourceModel(name: "练习册", icon: "book", colorHex: "#00FF00", sortOrder: 0)
        try repos.source.insertAndSave(source)

        let vm = SourceManagerViewModel(repositories: repos)
        vm.loadData()
        #expect(vm.sources.count == 1)

        vm.delete(at: IndexSet(integer: 0))

        #expect(vm.sources.isEmpty)
        #expect(vm.isDeletingInUse == false)
    }

    @Test("delete 阻止删除使用中的来源")
    func delete_blocksInUse() throws {
        let source = SourceModel(name: "试卷", icon: "doc.text", colorHex: "#808080", sortOrder: 0)
        try repos.source.insertAndSave(source)
        let item = ReviewItemModel(content: "题目", source: "试卷")
        repos.review.insert(item)
        try repos.review.saveContext()

        let vm = SourceManagerViewModel(repositories: repos)
        vm.loadData()

        vm.delete(at: IndexSet(integer: 0))

        #expect(vm.isDeletingInUse == true)
        #expect(vm.pendingDeletionName == "试卷")
        #expect(vm.sources.count == 1)
    }

    // MARK: - 边界条件

    @Test("saveSource 重命名为已存在的来源名称时题目级联正确")
    func saveSource_renameToExistingName() throws {
        let sourceA = SourceModel(name: "试卷", icon: "doc.text", colorHex: "#808080", sortOrder: 0)
        let sourceB = SourceModel(name: "课本", icon: "book", colorHex: "#0000FF", sortOrder: 1)
        try repos.source.insertAndSave(sourceA)
        try repos.source.insertAndSave(sourceB)

        let item = ReviewItemModel(content: "题目", source: "试卷")
        repos.review.insert(item)
        try repos.review.saveContext()

        let vm = SourceManagerViewModel(repositories: repos)
        vm.loadData()

        let examSource = vm.sources.first(where: { $0.name == "试卷" })
        vm.saveSource(source: examSource, name: "课本", selectedIcon: "doc.text", finalColorHex: "#808080")

        #expect(item.source == "课本")
    }
}
