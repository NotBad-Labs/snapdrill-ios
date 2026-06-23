//
//  CategoryManagerViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  维度管理 ViewModel 守护测试（L3）：加载、新建（成功/重名）、
//  删除（内置跳过 / 在用拦截 / 用户维度删除）。取代旧 3 套 Category/Source/Level Manager VM 测试。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillFeatureLibrary
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("CategoryManagerViewModel 维度管理测试", .serialized)
@MainActor
final class CategoryManagerViewModelTests {

    private let container: ModelContainer
    private let repos: RepositoryContainer

    init() throws {
        let schema = Schema(SnapDrillSchemaV1.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        repos = RepositoryContainer(modelContext: container.mainContext)
    }

    private func createVM() -> CategoryManagerViewModel {
        CategoryManagerViewModel(repositories: repos)
    }

    // MARK: - 加载

    @Test("loadData 加载维度（按 sortOrder）")
    func loadData_loadsSorted() {
        repos.dimension.seedDefaultsIfNeeded()
        let vm = createVM()
        vm.loadData()
        #expect(vm.dimensions.count == 4)
        #expect(vm.dimensions.map(\.sortOrder) == vm.dimensions.map(\.sortOrder).sorted())
    }

    // MARK: - 新建

    @Test("addDimension 成功新建用户维度（systemKey=nil / 非内置）")
    func addDimension_success() {
        let vm = createVM()
        let ok = vm.addDimension(name: "章节", isMultiValue: false, icon: "book")
        #expect(ok == true)
        #expect(vm.dimensions.contains { $0.name == "章节" && !$0.isBuiltIn && $0.systemKey == nil })
        #expect(vm.isDuplicateName == false)
    }

    @Test("addDimension 重名返回 false 并置 isDuplicateName")
    func addDimension_duplicate_returnsFalse() {
        let vm = createVM()
        _ = vm.addDimension(name: "章节", isMultiValue: false, icon: "book")
        let second = vm.addDimension(name: "章节", isMultiValue: true, icon: "tag")
        #expect(second == false)
        #expect(vm.isDuplicateName == true)
        #expect(vm.dimensions.filter { $0.name == "章节" }.count == 1)
    }

    // MARK: - 删除

    @Test("delete 内置维度被跳过")
    func delete_builtIn_skipped() {
        repos.dimension.seedDefaultsIfNeeded()
        let vm = createVM()
        vm.loadData()
        let builtInCount = vm.dimensions.count
        // 删除全部位置——内置应全部跳过
        vm.delete(at: IndexSet(integersIn: 0..<vm.dimensions.count))
        #expect(vm.dimensions.count == builtInCount)
    }

    @Test("delete 用户维度（无引用）成功移除")
    func delete_userDimension_removes() {
        let vm = createVM()
        _ = vm.addDimension(name: "章节", isMultiValue: false, icon: "book")
        vm.loadData()
        guard let idx = vm.dimensions.firstIndex(where: { $0.name == "章节" }) else {
            Issue.record("应有章节维度"); return
        }
        vm.delete(at: IndexSet(integer: idx))
        #expect(!vm.dimensions.contains { $0.name == "章节" })
    }

    @Test("delete 维度下有值被题目引用时拦截（不静默剥离题目分类）")
    func delete_inUse_blocked() throws {
        let vm = createVM()
        _ = vm.addDimension(name: "章节", isMultiValue: false, icon: "book")
        vm.loadData()
        guard let dim = vm.dimensions.first(where: { $0.name == "章节" }) else {
            Issue.record("应有章节维度"); return
        }
        let value = CategoryValueModel(name: "第一章", dimension: dim)
        try repos.categoryValue.insertAndSave(value)
        let item = ArchiveItemModel(content: "题")
        item.categoryValues = [value]
        repos.archive.insert(item)
        try repos.archive.saveContext()

        vm.loadData()
        guard let idx = vm.dimensions.firstIndex(where: { $0.name == "章节" }) else {
            Issue.record("应有章节维度"); return
        }
        vm.delete(at: IndexSet(integer: idx))
        #expect(vm.isDeletingInUse == true)
        #expect(vm.pendingDeletionName == "章节")
        #expect(vm.dimensions.contains { $0.name == "章节" })   // 仍在，未被删
    }
}
