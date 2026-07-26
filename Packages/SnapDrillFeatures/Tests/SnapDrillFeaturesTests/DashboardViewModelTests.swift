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

    private func makeViewModel(
        draftService: CaptureDraftServiceProtocol = CaptureDraftServiceMock()
    ) -> DashboardViewModel {
        DashboardViewModel(
            repositories: repos,
            draftService: draftService
        )
    }

    // MARK: - loadData

    @Test("loadData 空数据库返回全零统计")
    func loadData_empty_allZero() {
        let vm = makeViewModel()
        vm.loadData()

        #expect(vm.todayItemsCount == 0)
        #expect(vm.totalCount == 0)
        vm.cancelTasks()
    }

    @Test("loadData 正确统计题目数量")
    func loadData_countsItems() throws {
        let item1 = ArchiveItemModel(content: "题目1")
        let item2 = ArchiveItemModel(content: "题目2")
        repos.archive.insert(item1)
        repos.archive.insert(item2)
        try repos.archive.saveContext()

        let vm = makeViewModel()
        vm.loadData()

        #expect(vm.totalCount == 2)
        #expect(vm.todayItemsCount == 2)
        vm.cancelTasks()
    }

    // MARK: - checkDraftAndCapture

    @Test("checkDraftAndCapture 有草稿时显示弹窗")
    func checkDraftAndCapture_withDraft_showsAlert() async {
        let draftService = CaptureDraftServiceMock()
        draftService.seedDraft(content: "草稿")
        let vm = makeViewModel(draftService: draftService)
        let router = DashboardRouter()

        await vm.checkDraftAndCapture(router: router)

        #expect(vm.isShowingDraftAlert == true)
        vm.cancelTasks()
    }

    @Test("checkDraftAndCapture 无草稿时导航到采集")
    func checkDraftAndCapture_noDraft_navigates() async {
        let draftService = CaptureDraftServiceMock()
        let vm = makeViewModel(draftService: draftService)
        let router = DashboardRouter()

        var navigated = false
        router.onNavigateToCapture = { _ in navigated = true }

        await vm.checkDraftAndCapture(router: router)

        #expect(vm.isShowingDraftAlert == false)
        #expect(navigated == true)
        vm.cancelTasks()
    }

    @Test("checkDraftAndCapture 数据核实失败时不恢复也不导航")
    func checkDraftAndCapture_lookupFailure_failsClosed() async {
        let draftService = CaptureDraftServiceMock()
        draftService.seedDraft(content: "可能已保存")
        let vm = makeViewModel(draftService: draftService)
        let router = DashboardRouter()
        var navigated = false
        router.onNavigateToCapture = { _ in navigated = true }

        await vm.checkDraftAndCapture(router: router) { _ in
            throw DashboardDraftLookupError.failed
        }

        #expect(vm.isShowingDraftVerificationError)
        #expect(!vm.isShowingDraftAlert)
        #expect(!navigated)
        #expect(draftService.discardCallCount == 0)
        vm.cancelTasks()
    }

    // MARK: - startNewCapture

    @Test("startNewCapture 清除草稿并导航")
    func startNewCapture_clearsDraftAndNavigates() async {
        let draftService = CaptureDraftServiceMock()
        draftService.seedDraft(content: "草稿")
        let vm = makeViewModel(draftService: draftService)
        let router = DashboardRouter()

        var navigated = false
        router.onNavigateToCapture = { _ in navigated = true }

        await vm.checkDraftAndCapture(router: router)
        await vm.startNewCapture(router: router)

        #expect(draftService.discardCallCount == 1)
        #expect(navigated == true)
        vm.cancelTasks()
    }

    // MARK: - restoreDraft

    @Test("restoreDraft 有草稿时带草稿导航")
    func restoreDraft_withDraft_navigatesWithDraft() async {
        let draftService = CaptureDraftServiceMock()
        draftService.seedDraft(image: createTestImage(), content: "草稿", category: "数学")
        let vm = makeViewModel(draftService: draftService)
        let router = DashboardRouter()

        var receivedDraft: CaptureDraft?
        router.onNavigateToCapture = { draft in receivedDraft = draft }

        await vm.checkDraftAndCapture(router: router)
        vm.restoreDraft(router: router)

        #expect(receivedDraft != nil)
        #expect(receivedDraft?.content == "草稿")
        #expect(draftService.discardCallCount == 0)
        vm.cancelTasks()
    }

    @Test("restoreDraft 无草稿时直接导航")
    func restoreDraft_noDraft_navigatesWithoutDraft() {
        let draftService = CaptureDraftServiceMock()
        let vm = makeViewModel(draftService: draftService)
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
        let vm = makeViewModel()
        vm.cancelTasks()
    }

    // MARK: - 通知刷新

    @Test("libraryDataDidChange 通知触发数据刷新")
    func notification_refreshesData() async throws {
        let item = ArchiveItemModel(content: "通知测试")
        repos.archive.insert(item)
        try repos.archive.saveContext()

        let vm = makeViewModel()
        #expect(vm.totalCount == 0)

        // 让 for-await 循环启动（短暂让出 MainActor）
        await Task.yield()
        // 发送通知，轮询等待防抖 + loadData 完成
        NotificationCenter.default.post(name: .libraryDataDidChange, object: nil)
        try await waitUntil { vm.totalCount == 1 }
        vm.cancelTasks()
    }
}

private enum DashboardDraftLookupError: Error {
    case failed
}
