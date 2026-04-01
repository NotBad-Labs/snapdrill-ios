//
//  LibraryViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/03/09.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  LibraryViewModel 核心路径单元测试：过滤、分页、删除。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillFeatureLibrary
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("LibraryViewModel 过滤与分页测试", .serialized)
final class LibraryViewModelTests {

    // MARK: - 存储属性（每次 @Test 执行前由 Swift Testing 调用 init() 重建）

    /// ModelContainer 必须作为实例属性保活：ModelContext 对 ModelContainer 持弱引用，
    /// 若 container 被提前释放，后续 insert/fetch/save 均会 crash（x0 = nil, brk #1）。
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

    // MARK: - Helpers

    private func createVM() -> LibraryViewModel {
        LibraryViewModel(repositories: repos)
    }

    private func insertItem(
        content: String = "测试题",
        subject: String = "数学",
        tags: [TagModel]? = nil
    ) {
        let model = ReviewItemModel(content: content, subject: subject, tags: tags)
        repos.review.insert(model)
    }

    // MARK: - loadDataAsync

    @Test("空数据库 loadDataAsync 返回空列表")
    func loadDataAsync_empty_returnsEmptyList() async throws {
        let vm = createVM()
        await vm.loadDataAsync()

        #expect(vm.filteredItems.isEmpty)
        #expect(vm.isLoading == false)
    }

    @Test("loadDataAsync 加载元数据和题目")
    func loadDataAsync_loadsSubjectsAndItems() async throws {
        try seedDefaultTaxonomy(repos: repos)
        insertItem(content: "题目A")
        insertItem(content: "题目B")

        let vm = createVM()
        await vm.loadDataAsync()

        #expect(vm.filteredItems.count == 2)
        #expect(vm.subjects.count == 1)
        #expect(vm.isLoading == false)
    }

    // MARK: - refreshData

    @Test("refreshData 刷新过滤结果")
    func refreshData_updatesFilteredItems() async throws {
        insertItem(content: "题目A")

        let vm = createVM()
        await vm.refreshData()

        #expect(vm.filteredItems.count == 1)
    }

    // MARK: - 过滤

    @Test("按学科过滤")
    func filter_bySubject() async throws {
        insertItem(content: "数学题", subject: "数学")
        insertItem(content: "英语题", subject: "英语")

        let vm = createVM()
        vm.selectedSubjects = ["数学"]
        // 轮询等待防抖完成（替代固定 400ms sleep）
        try await waitUntil { vm.filteredItems.count == 1 }
        #expect(vm.filteredItems.first?.content == "数学题")
    }

    @Test("按搜索文本过滤")
    func filter_bySearchText() async throws {
        insertItem(content: "二次函数题")
        insertItem(content: "几何证明题")

        let vm = createVM()
        vm.searchText = "函数"
        try await waitUntil { vm.filteredItems.count == 1 }
        #expect(vm.filteredItems.first?.content == "二次函数题")
    }

    @Test("resetFilters 清空所有过滤器并刷新")
    func resetFilters_clearsAll() async throws {
        insertItem(content: "题目A", subject: "数学")
        insertItem(content: "题目B", subject: "英语")

        let vm = createVM()
        vm.selectedSubjects = ["数学"]
        try await waitUntil { vm.filteredItems.count == 1 }

        vm.resetFilters()
        try await waitUntil { vm.filteredItems.count == 2 }
        #expect(vm.searchText.isEmpty)
        #expect(vm.selectedSubjects.isEmpty)
        #expect(vm.selectedTags.isEmpty)
    }

    // MARK: - 分页

    @Test("loadMore 追加下一页数据")
    func loadMore_appendsNextPage() async throws {
        // 插入 55 条（pageSize=50，第二页应有 5 条）
        for i in 0..<55 {
            insertItem(content: "题目\(i)")
        }
        // fetchLimit/fetchOffset 仅对已持久化的行生效，必须 save 后再分页查询
        try repos.review.saveContext()

        let vm = createVM()
        await vm.refreshData()
        #expect(vm.filteredItems.count == 50)

        await vm.loadMore()
        #expect(vm.filteredItems.count == 55)
    }

    @Test("loadMore 空结果时不追加")
    func loadMore_emptyNextPage_noChange() async throws {
        insertItem(content: "唯一题目")
        // fetchLimit/fetchOffset 仅对已持久化的行生效，必须 save 后再分页查询
        try repos.review.saveContext()

        let vm = createVM()
        await vm.refreshData()
        #expect(vm.filteredItems.count == 1)

        await vm.loadMore()
        #expect(vm.filteredItems.count == 1)
    }

    // MARK: - 删除

    @Test("softDeleteItems 单条软删除并从列表移除")
    func softDeleteItem_removesFromList() async throws {
        let model = ReviewItemModel(content: "待删除", subject: "数学")
        repos.review.insert(model)

        let vm = createVM()
        await vm.refreshData()
        #expect(vm.filteredItems.count == 1)

        guard let firstItem = vm.filteredItems.first else {
            Issue.record("filteredItems 应有 1 条数据")
            return
        }
        vm.softDeleteItems(ids: [firstItem.id])
        #expect(vm.filteredItems.isEmpty)
        #expect(vm.showUndoToast == true)
    }

    @Test("softDeleteItems 批量软删除 + 从列表移除")
    func softDeleteItems_batchRemoves() async throws {
        var ids: Set<UUID> = []
        for i in 0..<3 {
            let model = ReviewItemModel(content: "题目\(i)", subject: "数学")
            repos.review.insert(model)
            ids.insert(model.id)
        }
        insertItem(content: "保留的题目")

        let vm = createVM()
        await vm.refreshData()
        #expect(vm.filteredItems.count == 4)

        vm.softDeleteItems(ids: ids)
        // 软删除立即从列表移除
        #expect(vm.filteredItems.count == 1)
        #expect(vm.filteredItems.first?.content == "保留的题目")
        #expect(vm.showUndoToast == true)
    }

    // MARK: - cancelTasks

    @Test("cancelTasks 不崩溃")
    func cancelTasks_noCrash() throws {
        let vm = createVM()
        vm.cancelTasks()
        // 无异常即通过
    }
}
