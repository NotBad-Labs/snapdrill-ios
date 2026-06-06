//
//  SmartPaperViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SmartPaperViewModel 智能组卷选题逻辑单元测试。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillFeatureLibrary
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("SmartPaperViewModel 智能组卷测试", .serialized)
final class SmartPaperViewModelTests {

    private let container: ModelContainer
    private let repos: RepositoryContainer

    init() throws {
        // L3：用 SnapDrillSchemaV1.models（含 CategoryDimension/Value）
        let schema = Schema(SnapDrillSchemaV1.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        repos = RepositoryContainer(modelContext: container.mainContext)
    }

    private func makeVM() -> SmartPaperViewModel {
        SmartPaperViewModel(repositories: repos)
    }

    /// 手建学科维度（仅 3 个值，不走 seedDefaults 以免引入 locale 相关默认值），返回 name→value
    @discardableResult
    private func seedSubjects() throws -> [String: CategoryValueModel] {
        let dimension = CategoryDimensionModel(
            name: "学科", isMultiValue: false, isBuiltIn: true,
            systemKey: CategorySystemKey.subject, sortOrder: 0, icon: "book"
        )
        try repos.dimension.insertAndSave(dimension)
        var values: [String: CategoryValueModel] = [:]
        for (index, name) in ["数学", "英语", "物理"].enumerated() {
            let value = CategoryValueModel(name: name, sortOrder: index, dimension: dimension)
            try repos.categoryValue.insertAndSave(value)
            values[name] = value
        }
        return values
    }

    @discardableResult
    private func seedItems() throws -> [String: CategoryValueModel] {
        let values = try seedSubjects()
        func add(_ content: String, _ subject: String, _ difficulty: Int) {
            let item = ReviewItemModel(content: content, difficulty: difficulty)
            if let value = values[subject] { item.categoryValues = [value] }
            repos.review.insert(item)
        }
        add("数学题1", "数学", 3)
        add("数学题2", "数学", 1)
        add("英语题1", "英语", 2)
        add("物理题1", "物理", 4)
        add("物理题2", "物理", 5)
        try repos.review.saveContext()
        return values
    }

    // MARK: - 初始状态

    @Test("初始状态：默认配置正确")
    func initialState() {
        let vm = makeVM()
        #expect(vm.questionCount == 10)
        #expect(vm.selectedItems.isEmpty)
        #expect(vm.availableSubjects.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
        #expect(vm.hideAnswers == true)
        #expect(vm.showBlankAnswerArea == true)
        #expect(vm.showHeader == true)
        #expect(vm.itemsPerPage == 2)
    }

    // MARK: - loadInitialData

    @Test("loadInitialData 加载学科列表并按 sortOrder 排序")
    func loadInitialData_loadsSubjects() throws {
        try seedSubjects()
        let vm = makeVM()
        vm.loadInitialData()

        #expect(vm.availableSubjects.map(\.name) == ["数学", "英语", "物理"])
    }

    @Test("loadInitialData 同时触发选题")
    func loadInitialData_triggersSelection() throws {
        try seedItems()
        let vm = makeVM()
        vm.loadInitialData()

        #expect(!vm.selectedItems.isEmpty)
        #expect(vm.selectedItems.count == 5)
    }

    // MARK: - refreshSelection

    @Test("refreshSelection 空数据库返回空列表")
    func refreshSelection_emptyDB() {
        let vm = makeVM()
        vm.refreshSelection()

        #expect(vm.selectedItems.isEmpty)
        #expect(vm.errorMessage == nil)
    }

    @Test("refreshSelection 尊重 questionCount 限制")
    func refreshSelection_respectsLimit() throws {
        try seedItems()
        let vm = makeVM()
        vm.questionCount = 2
        vm.refreshSelection()

        #expect(vm.selectedItems.count == 2)
    }

    @Test("refreshSelection 学科筛选")
    func refreshSelection_filtersBySubject() throws {
        let values = try seedItems()
        let vm = makeVM()
        vm.selectedSubjectValueIds = [try #require(values["英语"]).id]
        vm.refreshSelection()

        // 注：selectedItems 是 ReviewExportSnapshot，其 .subject 仍来自旧字段（S5d 重写）→ 此处断 content
        #expect(vm.selectedItems.count == 1)
        #expect(vm.selectedItems[0].content == "英语题1")
    }

    @Test("refreshSelection 难度筛选")
    func refreshSelection_filtersByDifficulty() throws {
        try seedItems()
        let vm = makeVM()
        vm.selectedDifficulties = [4, 5]
        vm.refreshSelection()

        // 难度 4 和 5 的题目只有物理的两道
        #expect(vm.selectedItems.count == 2)
        #expect(Set(vm.selectedItems.map(\.content)) == ["物理题1", "物理题2"])
    }

    // MARK: - 联合筛选

    @Test("refreshSelection 学科+难度联合筛选")
    func refreshSelection_combinedFilter() throws {
        let values = try seedItems()
        let vm = makeVM()
        vm.selectedSubjectValueIds = [try #require(values["数学"]).id]
        vm.selectedDifficulties = [3]
        vm.refreshSelection()

        // 数学+难度3 只有"数学题1"
        #expect(vm.selectedItems.count == 1)
        #expect(vm.selectedItems[0].content == "数学题1")
    }

    @Test("refreshSelection 联合筛选无匹配时返回空")
    func refreshSelection_combinedFilter_noMatch() throws {
        let values = try seedItems()
        let vm = makeVM()
        vm.selectedSubjectValueIds = [try #require(values["英语"]).id]
        vm.selectedDifficulties = [5]
        vm.refreshSelection()

        #expect(vm.selectedItems.isEmpty)
        #expect(vm.errorMessage == nil)
    }

    // MARK: - 边界条件

    @Test("refreshSelection questionCount 大于可用题目时返回全部")
    func refreshSelection_countExceedsAvailable() throws {
        try seedItems() // 5 道题
        let vm = makeVM()
        vm.questionCount = 100
        vm.refreshSelection()

        #expect(vm.selectedItems.count == 5)
    }

    @Test("refreshSelection 不存在的学科筛选返回空")
    func refreshSelection_nonexistentSubject() throws {
        try seedItems()
        let vm = makeVM()
        vm.selectedSubjectValueIds = [UUID()] // 不存在的学科值 id
        vm.refreshSelection()

        #expect(vm.selectedItems.isEmpty)
    }

    @Test("refreshSelection 不存在的难度筛选返回空")
    func refreshSelection_nonexistentDifficulty() throws {
        try seedItems()
        let vm = makeVM()
        vm.selectedDifficulties = [99]
        vm.refreshSelection()

        #expect(vm.selectedItems.isEmpty)
    }

    // 错误处理路径测试（refreshSelection + loadInitialData 的 catch 分支）：
    // 当前 RepositoryContainer 无 protocol 抽象，无法注入 mock 触发失败。
    // Codex/Gemini 审查确认此为架构限制，需后续引入 DI 后补充。

    // MARK: - pdfOptions

    @Test("pdfOptions 正确映射配置")
    func pdfOptions_mapsConfiguration() {
        let vm = makeVM()
        vm.hideAnswers = false
        vm.showBlankAnswerArea = false
        vm.showHeader = false
        vm.itemsPerPage = 4

        let options = vm.pdfOptions
        #expect(options.hideAnswers == false)
        #expect(options.showBlankAnswerArea == false)
        #expect(options.showHeader == false)
        #expect(options.itemsPerPage == 4)
    }

    // MARK: - 软删 pending 排除（Fix 4 / GAP-R1）

    @Test("refreshSelection 排除软删 pending 的题")
    func refreshSelection_excludesPendingDeletion() throws {
        let keep = ReviewItemModel(content: "保留题")
        keep.nextReviewAt = Date(timeIntervalSinceNow: -3600)
        let pending = ReviewItemModel(content: "待删题")
        pending.nextReviewAt = Date(timeIntervalSinceNow: -3600)
        repos.review.insert(keep)
        repos.review.insert(pending)

        let scheduler = DeletionScheduler()
        scheduler.scheduleDeletion(ids: [pending.id]) { _ in }  // 模拟 5 秒撤销窗口
        let vm = SmartPaperViewModel(repositories: repos, deletionScheduler: scheduler)
        vm.refreshSelection()

        #expect(vm.selectedItems.count == 1)  // 排除 pending 后只剩 1
    }
}
