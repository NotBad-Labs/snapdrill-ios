//
//  CategoryValueListViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  维度详情 ViewModel 守护测试（L3）：值增删改、在用拦截、
//  单/多值开关（内置守卫）、per-Profile 录入页可见性写穿。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillFeatureLibrary
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("CategoryValueListViewModel 维度详情测试", .serialized)
@MainActor
final class CategoryValueListViewModelTests {

    private let container: ModelContainer
    private let repos: RepositoryContainer

    init() throws {
        let schema = Schema(SnapDrillSchemaV1.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        repos = RepositoryContainer(modelContext: container.mainContext)
    }

    @discardableResult
    private func makeDimension(
        name: String,
        isMultiValue: Bool = false,
        isBuiltIn: Bool = false,
        systemKey: String? = nil
    ) throws -> CategoryDimensionModel {
        let dim = CategoryDimensionModel(
            name: name, isMultiValue: isMultiValue, isBuiltIn: isBuiltIn, systemKey: systemKey
        )
        try repos.dimension.insertAndSave(dim)
        return dim
    }

    // MARK: - 值增删改

    @Test("saveValue 新建值")
    func saveValue_create() throws {
        let dim = try makeDimension(name: "章节")
        let vm = CategoryValueListViewModel(dimension: dim, repositories: repos)
        vm.loadData()
        let ok = vm.saveValue(value: nil, name: "第一章", icon: "book", colorHex: "#FF0000")
        #expect(ok == true)
        #expect(vm.values.contains { $0.name == "第一章" })
    }

    @Test("saveValue 重命名现有值")
    func saveValue_rename() throws {
        let dim = try makeDimension(name: "章节")
        let value = CategoryValueModel(name: "第一章", dimension: dim)
        try repos.categoryValue.insertAndSave(value)
        let vm = CategoryValueListViewModel(dimension: dim, repositories: repos)
        vm.loadData()
        let ok = vm.saveValue(value: value, name: "序章", icon: "book", colorHex: "#FF0000")
        #expect(ok == true)
        #expect(value.name == "序章")
    }

    @Test("saveValue 重名返回 false 并置 isDuplicateName")
    func saveValue_duplicate_returnsFalse() throws {
        let dim = try makeDimension(name: "章节")
        try repos.categoryValue.insertAndSave(CategoryValueModel(name: "第一章", dimension: dim))
        let vm = CategoryValueListViewModel(dimension: dim, repositories: repos)
        vm.loadData()
        let ok = vm.saveValue(value: nil, name: "第一章", icon: "book", colorHex: "#FF0000")
        #expect(ok == false)
        #expect(vm.isDuplicateName == true)
    }

    @Test("delete 值被题目引用时拦截")
    func delete_inUse_blocked() throws {
        let dim = try makeDimension(name: "章节")
        let value = CategoryValueModel(name: "第一章", dimension: dim)
        try repos.categoryValue.insertAndSave(value)
        let item = ReviewItemModel(content: "题")
        item.categoryValues = [value]
        repos.review.insert(item)
        try repos.review.saveContext()

        let vm = CategoryValueListViewModel(dimension: dim, repositories: repos)
        vm.loadData()
        guard let idx = vm.values.firstIndex(where: { $0.name == "第一章" }) else {
            Issue.record("应有第一章值"); return
        }
        vm.delete(at: IndexSet(integer: idx))
        #expect(vm.isDeletingInUse == true)
        #expect(vm.values.contains { $0.name == "第一章" })
    }

    @Test("delete 无引用值成功移除")
    func delete_notInUse_removes() throws {
        let dim = try makeDimension(name: "章节")
        try repos.categoryValue.insertAndSave(CategoryValueModel(name: "第一章", dimension: dim))
        let vm = CategoryValueListViewModel(dimension: dim, repositories: repos)
        vm.loadData()
        guard let idx = vm.values.firstIndex(where: { $0.name == "第一章" }) else {
            Issue.record("应有第一章值"); return
        }
        vm.delete(at: IndexSet(integer: idx))
        #expect(!vm.values.contains { $0.name == "第一章" })
    }

    // MARK: - 单值/多值开关

    @Test("用户维度切换单/多值持久化")
    func toggleMultiValue_userDimension_persists() throws {
        let dim = try makeDimension(name: "章节", isMultiValue: false, isBuiltIn: false)
        let vm = CategoryValueListViewModel(dimension: dim, repositories: repos)
        vm.isMultiValue = true
        #expect(dim.isMultiValue == true)
        // 重新 fetch 维度确认持久化（仅一个维度）
        let refetched = try #require(try repos.dimension.fetchAllModels().first)
        #expect(refetched.isMultiValue == true)
    }

    @Test("内置维度单/多值开关被守卫拦截（dimension 不变）")
    func toggleMultiValue_builtIn_guarded() throws {
        let dim = try makeDimension(
            name: "学科", isMultiValue: false, isBuiltIn: true, systemKey: CategorySystemKey.subject
        )
        let vm = CategoryValueListViewModel(dimension: dim, repositories: repos)
        vm.isMultiValue = true   // didSet → persistMultiValue → guard !isBuiltIn → no-op
        #expect(dim.isMultiValue == false)
    }

    // MARK: - per-Profile 录入页可见性

    @Test("isVisibleInCapture 写穿到 captureVisibilityKey")
    func visibility_writesThroughToUserDefaults() throws {
        let dim = try makeDimension(name: "章节")  // 用户维度，key 用 id（每次运行唯一，无冲突）
        let key = dim.captureVisibilityKey
        defer { UserDefaults.standard.removeObject(forKey: key) }

        let vm = CategoryValueListViewModel(dimension: dim, repositories: repos)
        #expect(vm.isVisibleInCapture == true)  // 用户自建维度默认可见（无 key → defaultCaptureVisibility）

        vm.isVisibleInCapture = false
        #expect(UserDefaults.standard.object(forKey: key) as? Bool == false)

        vm.isVisibleInCapture = true
        #expect(UserDefaults.standard.object(forKey: key) as? Bool == true)
    }

    @Test("默认可见性：学科 + 用户自建默认可见、内置非学科（来源/年级/标签）默认隐藏")
    func defaultVisibility_subjectAndCustomVisible_otherBuiltInHidden() throws {
        let subject = try makeDimension(name: "学科", isBuiltIn: true, systemKey: CategorySystemKey.subject)
        let source = try makeDimension(name: "来源", isBuiltIn: true, systemKey: CategorySystemKey.source)
        let custom = try makeDimension(name: "章节")  // 用户自建（isBuiltIn=false）
        let dims = [subject, source, custom]
        // 清掉可能被其他测试写过的稳定 systemKey 对应 key，确保读到的是 defaultCaptureVisibility
        for d in dims { UserDefaults.standard.removeObject(forKey: d.captureVisibilityKey) }
        defer { for d in dims { UserDefaults.standard.removeObject(forKey: d.captureVisibilityKey) } }

        #expect(CategoryValueListViewModel(dimension: subject, repositories: repos).isVisibleInCapture == true)
        #expect(CategoryValueListViewModel(dimension: source, repositories: repos).isVisibleInCapture == false)
        #expect(CategoryValueListViewModel(dimension: custom, repositories: repos).isVisibleInCapture == true)
    }
}
