//
//  ModelTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs on 2026/01/02.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SubjectModel, SourceModel, TagModel 单元测试（Swift Testing）。
//

import Testing
import Foundation
import SwiftData
@testable import SnapDrillData

@MainActor
struct ModelTests {

    var container: ModelContainer
    var context: ModelContext

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: SubjectModel.self, SourceModel.self, TagModel.self,
            configurations: config
        )
        context = ModelContext(container)
    }

    // MARK: - SubjectModel Tests

    @Test("SubjectModel 初始化有效数据应创建模型")
    func testSubjectModel_Init_WithValidData_ShouldCreateModel() {
        let model = SubjectModel(
            name: "数学",
            icon: "function",
            colorHex: "#FF0000",
            sortOrder: 1
        )

        #expect(model.name == "数学")
        #expect(model.icon == "function")
        #expect(model.colorHex == "#FF0000")
        #expect(model.sortOrder == 1)
    }

    @Test("SubjectModel 默认值应正确")
    func testSubjectModel_DefaultValues_ShouldBeCorrect() {
        let model = SubjectModel(name: "", icon: "", colorHex: "", sortOrder: 0)

        #expect(model.name == "")
        #expect(model.icon == "")
        #expect(model.colorHex == "")
        #expect(model.sortOrder == 0)
    }

    @Test("SubjectModel 持久化应能保存并取回")
    func testSubjectModel_Persistence_ShouldSaveAndFetch() throws {
        let model = SubjectModel(name: "英语", icon: "book", colorHex: "#00FF00", sortOrder: 2)

        context.insert(model)
        try context.save()

        let fetchDescriptor = FetchDescriptor<SubjectModel>()
        let results = try context.fetch(fetchDescriptor)
        #expect(results.count == 1)
        #expect(results.first?.name == "英语")
    }

    // MARK: - SourceModel Tests

    @Test("SourceModel 初始化有效数据应创建模型")
    func testSourceModel_Init_WithValidData_ShouldCreateModel() {
        let model = SourceModel(
            name: "作业",
            icon: "doc.text",
            colorHex: "#0000FF",
            sortOrder: 1
        )

        #expect(model.name == "作业")
        #expect(model.icon == "doc.text")
        #expect(model.colorHex == "#0000FF")
        #expect(model.sortOrder == 1)
    }

    @Test("SourceModel 默认值应正确")
    func testSourceModel_DefaultValues_ShouldBeCorrect() {
        let model = SourceModel(name: "")

        #expect(model.name == "")
        #expect(model.icon == "doc.text")
        #expect(model.colorHex == "#808080")
        #expect(model.sortOrder == 0)
    }

    @Test("SourceModel 持久化应能保存并取回")
    func testSourceModel_Persistence_ShouldSaveAndFetch() throws {
        let model = SourceModel(name: "试卷", icon: "doc", colorHex: "#FFFF00", sortOrder: 3)

        context.insert(model)
        try context.save()

        let fetchDescriptor = FetchDescriptor<SourceModel>()
        let results = try context.fetch(fetchDescriptor)
        #expect(results.count == 1)
        #expect(results.first?.name == "试卷")
    }

    // MARK: - TagModel Tests

    @Test("TagModel 初始化有效数据应创建模型")
    func testTagModel_Init_WithValidData_ShouldCreateModel() {
        let model = TagModel(
            name: "粗心",
            colorHex: "#FF00FF"
        )

        #expect(model.name == "粗心")
        #expect(model.colorHex == "#FF00FF")
        #expect(model.createdAt != Date.distantFuture)
    }

    @Test("TagModel 默认值应正确")
    func testTagModel_DefaultValues_ShouldBeCorrect() {
        let model = TagModel(name: "")

        #expect(model.name == "")
        #expect(model.colorHex == "#8E8E93")
        #expect(model.createdAt != Date.distantFuture)
    }

    @Test("TagModel 持久化应能保存并取回")
    func testTagModel_Persistence_ShouldSaveAndFetch() throws {
        let model = TagModel(name: "计算错误", colorHex: "#00FFFF")

        context.insert(model)
        try context.save()

        let fetchDescriptor = FetchDescriptor<TagModel>()
        let results = try context.fetch(fetchDescriptor)
        #expect(results.count == 1)
        #expect(results.first?.name == "计算错误")
    }

    @Test("TagModel 关联关系应正确处理 items")
    func testTagModel_Relationship_ShouldHandleItems() throws {
        let tag = TagModel(name: "重点")
        context.insert(tag)

        #expect(tag.items != nil)
        #expect((tag.items?.count ?? 0) == 0)
    }

    // MARK: - Sorting Tests

    @Test("SubjectModel 按 sortOrder 排序应正确")
    func testSubjectModel_Sorting_BySortOrder_ShouldWork() throws {
        let subject1 = SubjectModel(name: "数学", icon: "a", colorHex: "#000", sortOrder: 2)
        let subject2 = SubjectModel(name: "英语", icon: "b", colorHex: "#000", sortOrder: 1)
        let subject3 = SubjectModel(name: "物理", icon: "c", colorHex: "#000", sortOrder: 3)

        context.insert(subject1)
        context.insert(subject2)
        context.insert(subject3)
        try context.save()

        let fetchDescriptor = FetchDescriptor<SubjectModel>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let results = try context.fetch(fetchDescriptor)

        #expect(results.count == 3)
        #expect(results[0].name == "英语")   // sortOrder 1
        #expect(results[1].name == "数学")   // sortOrder 2
        #expect(results[2].name == "物理")   // sortOrder 3
    }

    @Test("SourceModel 按 sortOrder 排序应正确")
    func testSourceModel_Sorting_BySortOrder_ShouldWork() throws {
        let source1 = SourceModel(name: "作业", sortOrder: 3)
        let source2 = SourceModel(name: "试卷", sortOrder: 1)
        let source3 = SourceModel(name: "教材", sortOrder: 2)

        context.insert(source1)
        context.insert(source2)
        context.insert(source3)
        try context.save()

        let fetchDescriptor = FetchDescriptor<SourceModel>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let results = try context.fetch(fetchDescriptor)

        #expect(results.count == 3)
        #expect(results[0].name == "试卷")
        #expect(results[1].name == "教材")
        #expect(results[2].name == "作业")
    }
}
