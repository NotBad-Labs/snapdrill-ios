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

    private func makeVM(
        defaults: UserDefaults? = nil,
        now: @escaping () -> Date = Date.init,
        randomizeArchiveItems: @escaping ([ArchiveItemModel]) -> [ArchiveItemModel] = { $0 }
    ) -> SmartPaperViewModel {
        SmartPaperViewModel(
            repositories: repos,
            defaults: defaults ?? makeDefaults(),
            calendar: Self.gregorianCalendar,
            now: now,
            randomizeArchiveItems: randomizeArchiveItems
        )
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "SmartPaperViewModelTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            preconditionFailure("Failed to create test UserDefaults suite: \(suiteName)")
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private static var gregorianCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        let components = DateComponents(
            calendar: gregorianCalendar,
            timeZone: gregorianCalendar.timeZone,
            year: year,
            month: month,
            day: day
        )
        return components.date ?? Date(timeIntervalSince1970: 0)
    }

    /// 手建分类维度（仅 3 个值，不走 seedDefaults 以免引入 locale 相关默认值），返回 name→value
    @discardableResult
    private func seedCategories() throws -> [String: CategoryValueModel] {
        let dimension = CategoryDimensionModel(
            name: "分类", isMultiValue: false, isBuiltIn: true,
            systemKey: CategorySystemKey.category, sortOrder: 0, icon: "book"
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
        let values = try seedCategories()
        func add(_ content: String, _ category: String) {
            let item = ArchiveItemModel(content: content)
            if let value = values[category] { item.categoryValues = [value] }
            repos.archive.insert(item)
        }
        add("数学题1", "数学")
        add("数学题2", "数学")
        add("英语题1", "英语")
        add("物理题1", "物理")
        add("物理题2", "物理")
        try repos.archive.saveContext()
        return values
    }

    // MARK: - 初始状态

    @Test("初始状态：默认配置正确")
    func initialState() {
        let vm = makeVM()
        #expect(vm.questionCount == 10)
        #expect(vm.selectedItems.isEmpty)
        #expect(vm.availableCategories.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
        #expect(vm.hideAnswers == true)
        #expect(vm.showBlankAnswerArea == true)
        #expect(vm.showHeader == true)
        #expect(vm.itemsPerPage == 2)
    }

    // MARK: - loadInitialData

    @Test("loadInitialData 加载分类列表并按 sortOrder 排序")
    func loadInitialData_loadsCategories() throws {
        try seedCategories()
        let vm = makeVM()
        vm.loadInitialData()

        #expect(vm.availableCategories.map(\.name) == ["数学", "英语", "物理"])
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

    @Test("refreshSelection 分类筛选")
    func refreshSelection_filtersByCategory() throws {
        let values = try seedItems()
        let vm = makeVM()
        vm.selectedCategoryValueIds = [try #require(values["英语"]).id]
        vm.refreshSelection()

        // 注：selectedItems 是 ArchiveExportSnapshot，其 .category 仍来自旧字段（S5d 重写）→ 此处断 content
        #expect(vm.selectedItems.count == 1)
        #expect(vm.selectedItems[0].content == "英语题1")
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

    @Test("refreshSelection 不存在的分类筛选返回空")
    func refreshSelection_nonexistentCategory() throws {
        try seedItems()
        let vm = makeVM()
        vm.selectedCategoryValueIds = [UUID()] // 不存在的分类值 id
        vm.refreshSelection()

        #expect(vm.selectedItems.isEmpty)
    }

    @Test("refreshSelection 免费层走随机抽取，Pro 层保留 SM-2 精准排序")
    func refreshSelection_freeRandomProPrecise() throws {
        let oldestCreated = ArchiveItemModel(
            content: "随机第一",
            createdAt: Date(timeIntervalSince1970: 1),
            nextReviewAt: Date(timeIntervalSince1970: 300)
        )
        let middle = ArchiveItemModel(
            content: "随机第二",
            createdAt: Date(timeIntervalSince1970: 2),
            nextReviewAt: Date(timeIntervalSince1970: 200)
        )
        let mostUrgent = ArchiveItemModel(
            content: "精准第一",
            createdAt: Date(timeIntervalSince1970: 3),
            nextReviewAt: Date(timeIntervalSince1970: 100)
        )
        repos.archive.insert(oldestCreated)
        repos.archive.insert(middle)
        repos.archive.insert(mostUrgent)
        try repos.archive.saveContext()

        let vm = makeVM(randomizeArchiveItems: { Array($0.reversed()) })
        vm.questionCount = 2

        vm.refreshSelection(isProUser: false)
        #expect(vm.selectedItems.map { $0.content ?? "" } == ["随机第一", "随机第二"])

        vm.refreshSelection(isProUser: true)
        #expect(vm.selectedItems.map { $0.content ?? "" } == ["精准第一", "随机第二"])
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

    // MARK: - 免费配额

    @Test("prepareGeneration 免费层每自然月 3 次，超额后自然月重置")
    func prepareGeneration_freeQuotaMonthlyReset() throws {
        try seedItems()
        var currentDate = Self.date(2026, 6, 15)
        let defaults = makeDefaults()
        let vm = makeVM(defaults: defaults, now: { currentDate })

        for _ in 0..<SmartPaperViewModel.freeMonthlyQuota {
            #expect(vm.prepareGeneration(isProUser: false) == .preview)
        }
        #expect(vm.freeQuotaUsed == SmartPaperViewModel.freeMonthlyQuota)
        #expect(vm.prepareGeneration(isProUser: false) == .quotaExceeded)

        currentDate = Self.date(2026, 7, 1)
        #expect(vm.prepareGeneration(isProUser: false) == .preview)
        #expect(vm.freeQuotaUsed == 1)
        #expect(defaults.string(forKey: UDKey.smartPaperFreeQuotaMonth) == "2026-07")
    }

    @Test("prepareGeneration Pro 路径不消耗免费配额")
    func prepareGeneration_proDoesNotConsumeFreeQuota() throws {
        try seedItems()
        let defaults = makeDefaults()
        let vm = makeVM(defaults: defaults)

        #expect(vm.prepareGeneration(isProUser: true) == .preview)
        #expect(vm.freeQuotaUsed == 0)
        #expect(defaults.object(forKey: UDKey.smartPaperFreeQuotaUsed) == nil)
    }

    // MARK: - 软删 pending 排除（Fix 4 / GAP-R1）

    @Test("refreshSelection 排除软删 pending 的题")
    func refreshSelection_excludesPendingDeletion() throws {
        let keep = ArchiveItemModel(content: "保留题")
        keep.nextReviewAt = Date(timeIntervalSinceNow: -3600)
        let pending = ArchiveItemModel(content: "待删题")
        pending.nextReviewAt = Date(timeIntervalSinceNow: -3600)
        repos.archive.insert(keep)
        repos.archive.insert(pending)

        let scheduler = DeletionScheduler()
        scheduler.scheduleDeletion(ids: [pending.id]) { _ in }  // 模拟 5 秒撤销窗口
        let vm = SmartPaperViewModel(repositories: repos, deletionScheduler: scheduler)
        vm.refreshSelection()

        #expect(vm.selectedItems.count == 1)  // 排除 pending 后只剩 1
    }
}
