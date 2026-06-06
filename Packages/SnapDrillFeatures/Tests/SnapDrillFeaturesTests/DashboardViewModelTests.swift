//
//  DashboardViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  DashboardViewModel 核心路径单元测试：统计加载、草稿处理、通知刷新。
//

import Testing
import SwiftData
import Foundation
import UIKit
@testable import SnapDrillFeatureDashboard
@testable import SnapDrillData
@testable import SnapDrillCore

// MARK: - Mock DraftService

@MainActor
final class MockDraftService: CaptureDraftServiceProtocol {
    var hasDraft: Bool = false
    var savedDraft: CaptureDraftService.Draft?
    var clearDraftCallCount = 0

    func saveDraft(image: UIImage?, content: String, subject: String?) async {
        hasDraft = true
    }

    func loadDraft() -> CaptureDraftService.Draft? {
        savedDraft
    }

    func clearDraft() {
        clearDraftCallCount += 1
        hasDraft = false
        savedDraft = nil
    }
}

@Suite("DashboardViewModel 统计与草稿测试", .serialized)
@MainActor
final class DashboardViewModelTests {

    // MARK: - 存储属性

    private let container: ModelContainer
    private let repos: RepositoryContainer

    init() throws {
        let schema = Schema(SnapDrillSchemaV1.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        repos = RepositoryContainer(modelContext: container.mainContext)
    }

    // MARK: - loadData

    @Test("loadData 空数据库返回全零统计")
    func loadData_empty_allZero() {
        let vm = DashboardViewModel(repositories: repos)
        vm.loadData()

        #expect(vm.todayItemsCount == 0)
        #expect(vm.totalCount == 0)
        #expect(vm.dueCount == 0)
        #expect(vm.reviewedTodayCount == 0)
        vm.cancelTasks()
    }

    @Test("loadData 正确统计题目数量")
    func loadData_countsItems() throws {
        let item1 = ReviewItemModel(content: "题目1")
        let item2 = ReviewItemModel(content: "题目2")
        repos.review.insert(item1)
        repos.review.insert(item2)
        try repos.review.saveContext()

        let vm = DashboardViewModel(repositories: repos)
        vm.loadData()

        #expect(vm.totalCount == 2)
        #expect(vm.todayItemsCount == 2)
        vm.cancelTasks()
    }

    @Test("loadData 区分到期和未到期题目的 dueCount")
    func loadData_dueCount() throws {
        // 一道已到期的题目（1 小时前到期）
        let dueItem = ReviewItemModel(content: "待复习题目")
        dueItem.nextReviewAt = Date(timeIntervalSinceNow: -3600)
        repos.review.insert(dueItem)

        // 一道未到期的题目（远未来）
        let futureItem = ReviewItemModel(content: "未到期题目")
        futureItem.nextReviewAt = Date.distantFuture
        repos.review.insert(futureItem)

        try repos.review.saveContext()

        let vm = DashboardViewModel(repositories: repos)
        vm.loadData()

        #expect(vm.totalCount == 2)
        #expect(vm.dueCount == 1)
        vm.cancelTasks()
    }

    // MARK: - checkDraftAndCapture

    @Test("checkDraftAndCapture 有草稿时显示弹窗")
    func checkDraftAndCapture_withDraft_showsAlert() {
        let draftService = MockDraftService()
        draftService.hasDraft = true
        let vm = DashboardViewModel(repositories: repos, draftService: draftService)
        let router = DashboardRouter()

        vm.checkDraftAndCapture(router: router)

        #expect(vm.isShowingDraftAlert == true)
        vm.cancelTasks()
    }

    @Test("checkDraftAndCapture 无草稿时导航到采集")
    func checkDraftAndCapture_noDraft_navigates() {
        let draftService = MockDraftService()
        draftService.hasDraft = false
        let vm = DashboardViewModel(repositories: repos, draftService: draftService)
        let router = DashboardRouter()

        var navigated = false
        router.onNavigateToCapture = { _ in navigated = true }

        vm.checkDraftAndCapture(router: router)

        #expect(vm.isShowingDraftAlert == false)
        #expect(navigated == true)
        vm.cancelTasks()
    }

    // MARK: - startNewCapture

    @Test("startNewCapture 清除草稿并导航")
    func startNewCapture_clearsDraftAndNavigates() {
        let draftService = MockDraftService()
        draftService.hasDraft = true
        let vm = DashboardViewModel(repositories: repos, draftService: draftService)
        let router = DashboardRouter()

        var navigated = false
        router.onNavigateToCapture = { _ in navigated = true }

        vm.startNewCapture(router: router)

        #expect(draftService.clearDraftCallCount == 1)
        #expect(navigated == true)
        vm.cancelTasks()
    }

    // MARK: - restoreDraft

    @Test("restoreDraft 有草稿时带草稿导航")
    func restoreDraft_withDraft_navigatesWithDraft() {
        let draftService = MockDraftService()
        let draft = CaptureDraftService.Draft(image: createTestImage(), content: "草稿", date: Date(), subject: "数学")
        draftService.savedDraft = draft
        draftService.hasDraft = true
        let vm = DashboardViewModel(repositories: repos, draftService: draftService)
        let router = DashboardRouter()

        var receivedDraft: CaptureDraftService.Draft?
        router.onNavigateToCapture = { draft in receivedDraft = draft }

        vm.restoreDraft(router: router)

        #expect(receivedDraft != nil)
        #expect(receivedDraft?.content == "草稿")
        vm.cancelTasks()
    }

    @Test("restoreDraft 无草稿时直接导航")
    func restoreDraft_noDraft_navigatesWithoutDraft() {
        let draftService = MockDraftService()
        draftService.savedDraft = nil
        let vm = DashboardViewModel(repositories: repos, draftService: draftService)
        let router = DashboardRouter()

        var navigated = false
        router.onNavigateToCapture = { draft in
            #expect(draft == nil)
            navigated = true
        }

        vm.restoreDraft(router: router)

        #expect(navigated == true)
        vm.cancelTasks()
    }

    // MARK: - cancelTasks

    @Test("cancelTasks 不崩溃")
    func cancelTasks_noCrash() {
        let vm = DashboardViewModel(repositories: repos)
        vm.cancelTasks()
    }

    // MARK: - 通知刷新

    @Test("reviewDataDidChange 通知触发数据刷新")
    func notification_refreshesData() async throws {
        let item = ReviewItemModel(content: "通知测试")
        repos.review.insert(item)
        try repos.review.saveContext()

        let vm = DashboardViewModel(repositories: repos)
        #expect(vm.totalCount == 0)

        // 让 for-await 循环启动（短暂让出 MainActor）
        await Task.yield()
        // 发送通知，轮询等待防抖 + loadData 完成
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
        try await waitUntil { vm.totalCount == 1 }
        vm.cancelTasks()
    }

    // MARK: - 软删 pending 排除（Fix 4 / GAP-R1）

    @Test("loadData 的 dueCount 排除软删 pending 的到期题，totalCount 不受影响")
    func loadData_dueCountExcludesPendingDeletion() throws {
        let keep = ReviewItemModel(content: "保留题")
        keep.nextReviewAt = Date(timeIntervalSinceNow: -3600)
        let pending = ReviewItemModel(content: "待删题")
        pending.nextReviewAt = Date(timeIntervalSinceNow: -3600)
        repos.review.insert(keep)
        repos.review.insert(pending)

        let scheduler = DeletionScheduler()
        scheduler.scheduleDeletion(ids: [pending.id]) { _ in }  // 模拟 5 秒撤销窗口
        let vm = DashboardViewModel(
            repositories: repos,
            draftService: MockDraftService(),
            deletionScheduler: scheduler
        )
        vm.loadData()

        #expect(vm.dueCount == 1)    // 排除 pending 后只剩 1
        #expect(vm.totalCount == 2)  // 总数不受影响（软删窗口内 DB 仍在）

        vm.cancelTasks()  // 取消 reviewDataDidChange 观察者，避免跨测试 leak（与既有测试一致）
    }
}
