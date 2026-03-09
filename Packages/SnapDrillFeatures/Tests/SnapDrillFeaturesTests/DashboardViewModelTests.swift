//
//  DashboardViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/03/09.
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

    func saveDraft(image: UIImage, content: String) {
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

    @Test("loadData 空数据库返回全零统计")
    func loadData_empty_allZero() {
        let vm = DashboardViewModel(repositories: repos)
        vm.loadData()

        #expect(vm.todayItemsCount == 0)
        #expect(vm.totalCount == 0)
        #expect(vm.dueCount == 0)
        #expect(vm.reviewedTodayCount == 0)
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
    }

    // MARK: - restoreDraft

    @Test("restoreDraft 有草稿时带草稿导航")
    func restoreDraft_withDraft_navigatesWithDraft() {
        let draftService = MockDraftService()
        let draft = CaptureDraftService.Draft(image: createTestImage(), content: "草稿", date: Date())
        draftService.savedDraft = draft
        draftService.hasDraft = true
        let vm = DashboardViewModel(repositories: repos, draftService: draftService)
        let router = DashboardRouter()

        var receivedDraft: CaptureDraftService.Draft?
        router.onNavigateToCapture = { draft in receivedDraft = draft }

        vm.restoreDraft(router: router)

        #expect(receivedDraft != nil)
        #expect(receivedDraft?.content == "草稿")
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

        // 发送通知，等待防抖 + 处理
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(vm.totalCount == 1)
        vm.cancelTasks()
    }
}
