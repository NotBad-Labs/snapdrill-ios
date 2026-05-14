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

    private func makeVM() -> SmartPaperViewModel {
        SmartPaperViewModel(repositories: repos)
    }

    private func seedSubjects() throws {
        repos.subject.insert(SubjectModel(name: "数学", icon: "function", colorHex: "#FF0000", sortOrder: 0))
        repos.subject.insert(SubjectModel(name: "英语", icon: "book", colorHex: "#0000FF", sortOrder: 1))
        repos.subject.insert(SubjectModel(name: "物理", icon: "bolt", colorHex: "#00FF00", sortOrder: 2))
        try repos.review.saveContext()
    }

    private func seedItems() throws {
        try seedSubjects()
        repos.review.insert(ReviewItemModel(content: "数学题1", subject: "数学", difficulty: 3))
        repos.review.insert(ReviewItemModel(content: "数学题2", subject: "数学", difficulty: 1))
        repos.review.insert(ReviewItemModel(content: "英语题1", subject: "英语", difficulty: 2))
        repos.review.insert(ReviewItemModel(content: "物理题1", subject: "物理", difficulty: 4))
        repos.review.insert(ReviewItemModel(content: "物理题2", subject: "物理", difficulty: 5))
        try repos.review.saveContext()
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

        #expect(vm.availableSubjects == ["数学", "英语", "物理"])
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
        try seedItems()
        let vm = makeVM()
        vm.selectedSubjects = ["英语"]
        vm.refreshSelection()

        #expect(vm.selectedItems.count == 1)
        #expect(vm.selectedItems[0].subject == "英语")
    }

    @Test("refreshSelection 难度筛选")
    func refreshSelection_filtersByDifficulty() throws {
        try seedItems()
        let vm = makeVM()
        vm.selectedDifficulties = [4, 5]
        vm.refreshSelection()

        // 难度 4 和 5 的题目只有物理的两道
        #expect(vm.selectedItems.count == 2)
        for item in vm.selectedItems {
            #expect(item.subject == "物理")
        }
    }

    // MARK: - 联合筛选

    @Test("refreshSelection 学科+难度联合筛选")
    func refreshSelection_combinedFilter() throws {
        try seedItems()
        let vm = makeVM()
        vm.selectedSubjects = ["数学"]
        vm.selectedDifficulties = [3]
        vm.refreshSelection()

        // 数学+难度3 只有"数学题1"
        #expect(vm.selectedItems.count == 1)
        #expect(vm.selectedItems[0].content == "数学题1")
    }

    @Test("refreshSelection 联合筛选无匹配时返回空")
    func refreshSelection_combinedFilter_noMatch() throws {
        try seedItems()
        let vm = makeVM()
        vm.selectedSubjects = ["英语"]
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
        vm.selectedSubjects = ["化学"]
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
}
