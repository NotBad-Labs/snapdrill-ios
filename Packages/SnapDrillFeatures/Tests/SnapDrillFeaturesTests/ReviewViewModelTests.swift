//
//  ReviewViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/03/03.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ReviewViewModel 核心路径单元测试：会话状态机、SM-2 调度写回、撤销栈。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillFeatures
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("ReviewViewModel 状态机与 SM-2 调度测试")
@MainActor
struct ReviewViewModelTests {

    // MARK: - Helpers

    private func createTestRepository() throws -> ReviewRepository {
        let schema = Schema([
            ReviewItemModel.self,
            TagModel.self,
            SubjectModel.self,
            SourceModel.self,
            GradeModel.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ReviewRepository(modelContext: container.mainContext)
    }

    /// 插入一个 nextReviewAt 在过去的条目（即立即待复习）
    @discardableResult
    private func insertDueItem(
        in repo: ReviewRepository,
        content: String = "测试题",
        repetitions: Int = 0,
        interval: Int = 0
    ) throws -> ReviewItemModel {
        let model = ReviewItemModel(content: content, subject: "数学", source: "试卷")
        model.nextReviewAt = Date().addingTimeInterval(-3600)
        model.repetitions = repetitions
        model.interval = interval
        try repo.insertAndSave(model)
        return model
    }

    // MARK: - 初始状态

    @Test("ViewModel 初始 phase 为 loading")
    func initialPhaseIsLoading() throws {
        let repo = try createTestRepository()
        let vm = ReviewViewModel(repository: repo)
        #expect(vm.phase == .loading)
        #expect(vm.reviewQueue.isEmpty)
        #expect(vm.workingItems.isEmpty)
        #expect(vm.finishedItems == 0)
    }

    // MARK: - loadDataAsync

    @Test("空数据库时 loadDataAsync 将 phase 变为 idle，队列为空")
    func loadDataAsync_emptyDatabase_idleAndEmptyQueue() async throws {
        let repo = try createTestRepository()
        let vm = ReviewViewModel(repository: repo)

        await vm.loadDataAsync()

        #expect(vm.phase == .idle)
        #expect(vm.reviewQueue.isEmpty)
        #expect(vm.totalItemsCount == 0)
    }

    @Test("loadDataAsync 正确区分待复习与未来条目")
    func loadDataAsync_distinguishesDueFromFuture() async throws {
        let repo = try createTestRepository()

        try insertDueItem(in: repo, content: "过期题A")
        try insertDueItem(in: repo, content: "过期题B")

        // 未来条目不计入 reviewQueue
        let futureItem = ReviewItemModel(content: "未来题", subject: "物理", source: "课本")
        futureItem.nextReviewAt = Date().addingTimeInterval(86400)
        try repo.insertAndSave(futureItem)

        let vm = ReviewViewModel(repository: repo)
        await vm.loadDataAsync()

        #expect(vm.reviewQueue.count == 2)
        #expect(vm.totalItemsCount == 3) // 全部 3 条，但待复习只有 2
        #expect(vm.phase == .idle)
    }

    // MARK: - startSession

    @Test("startSession 将 reviewQueue 复制到 workingItems 并进入 reviewing")
    func startSession_copiesQueueAndEntersReviewing() async throws {
        let repo = try createTestRepository()
        try insertDueItem(in: repo, content: "题目A")
        try insertDueItem(in: repo, content: "题目B")

        let vm = ReviewViewModel(repository: repo)
        await vm.loadDataAsync()
        vm.startSession()

        #expect(vm.phase == .reviewing)
        #expect(vm.workingItems.count == 2)
        #expect(vm.finishedItems == 0)
        #expect(vm.undoStack.isEmpty)
        #expect(vm.isAnswerShown == false)
    }

    @Test("startSession 清除上次会话的残留状态")
    func startSession_resetsResidualSessionState() async throws {
        let repo = try createTestRepository()
        try insertDueItem(in: repo)

        let vm = ReviewViewModel(repository: repo)
        await vm.loadDataAsync()

        // 模拟旧会话残留
        vm.finishedItems = 5
        vm.isAnswerShown = true

        vm.startSession()

        #expect(vm.finishedItems == 0)
        #expect(vm.isAnswerShown == false)
        #expect(vm.undoStack.isEmpty)
    }

    // MARK: - handleSwipeCompletion（SM-2 核心路径）

    @Test("向右滑（good）更新 SM-2 状态并持久化到 @Model")
    func handleSwipe_rightGood_updatesSM2AndPersists() async throws {
        let repo = try createTestRepository()
        let model = try insertDueItem(in: repo, content: "SM-2 好题")

        let vm = ReviewViewModel(repository: repo)
        await vm.loadDataAsync()
        vm.startSession()

        vm.handleSwipeCompletion(direction: 1) // 右滑 = good

        // 队列变化
        #expect(vm.workingItems.isEmpty)
        #expect(vm.undoStack.count == 1)
        #expect(vm.finishedItems == 1)
        #expect(vm.isAnswerShown == false)

        // SM-2 写回：第一次 good 后 repetitions=1, interval=1
        #expect(model.repetitions == 1)
        #expect(model.interval == 1)
        #expect(model.nextReviewAt != nil)
        #expect(model.lastReviewedAt != nil)
    }

    @Test("向左滑（again）将 repetitions 和 interval 重置为 0")
    func handleSwipe_leftAgain_resetsSM2Counters() async throws {
        let repo = try createTestRepository()
        // 已有进度的条目
        let model = try insertDueItem(in: repo, content: "SM-2 难题", repetitions: 3, interval: 6)

        let vm = ReviewViewModel(repository: repo)
        await vm.loadDataAsync()
        vm.startSession()

        vm.handleSwipeCompletion(direction: -1) // 左滑 = again

        #expect(model.repetitions == 0)
        #expect(model.interval == 0)
        // again 后仍设置 nextReviewAt（约 10 分钟后），不为 nil
        #expect(model.nextReviewAt != nil)
    }

    @Test("最后一张卡片滑走后 phase 变为 finished")
    func handleSwipe_lastCard_phaseBecomesFinished() async throws {
        let repo = try createTestRepository()
        try insertDueItem(in: repo)

        let vm = ReviewViewModel(repository: repo)
        await vm.loadDataAsync()
        vm.startSession()

        #expect(vm.workingItems.count == 1)
        vm.handleSwipeCompletion(direction: 1)

        #expect(vm.phase == .finished)
    }

    @Test("非最后一张卡片滑走后 phase 保持 reviewing")
    func handleSwipe_notLastCard_phaseRemainsReviewing() async throws {
        let repo = try createTestRepository()
        try insertDueItem(in: repo, content: "题目A")
        try insertDueItem(in: repo, content: "题目B")

        let vm = ReviewViewModel(repository: repo)
        await vm.loadDataAsync()
        vm.startSession()

        vm.handleSwipeCompletion(direction: 1)

        #expect(vm.phase == .reviewing)
        #expect(vm.workingItems.count == 1)
    }

    @Test("空队列时 handleSwipeCompletion 不崩溃")
    func handleSwipe_emptyQueue_noOp() throws {
        let repo = try createTestRepository()
        let vm = ReviewViewModel(repository: repo)
        // 未调用 startSession，workingItems 为空
        vm.handleSwipeCompletion(direction: 1) // 不应崩溃
        #expect(vm.finishedItems == 0)
    }

    // MARK: - undoLastSwipe

    @Test("undoLastSwipe 将条目移回 workingItems 头部")
    func undoLastSwipe_restoresItemToFrontOfQueue() async throws {
        let repo = try createTestRepository()
        let model = try insertDueItem(in: repo, content: "可撤销题")

        let vm = ReviewViewModel(repository: repo)
        await vm.loadDataAsync()
        vm.startSession()

        vm.handleSwipeCompletion(direction: 1)
        #expect(vm.workingItems.isEmpty)
        #expect(vm.isUndoEnabled)

        vm.undoLastSwipe()

        #expect(vm.workingItems.count == 1)
        #expect(vm.workingItems.first?.content == model.content)
        #expect(vm.finishedItems == 0)
        #expect(vm.undoStack.isEmpty)
        #expect(!vm.isUndoEnabled)
    }

    @Test("finished 状态下 undoLastSwipe 恢复为 reviewing")
    func undoLastSwipe_fromFinished_resumesReviewing() async throws {
        let repo = try createTestRepository()
        try insertDueItem(in: repo)

        let vm = ReviewViewModel(repository: repo)
        await vm.loadDataAsync()
        vm.startSession()

        vm.handleSwipeCompletion(direction: 1)
        #expect(vm.phase == .finished)

        vm.undoLastSwipe()

        #expect(vm.phase == .reviewing)
    }

    @Test("undoStack 为空时 undoLastSwipe 无操作")
    func undoLastSwipe_emptyStack_noOp() throws {
        let repo = try createTestRepository()
        let vm = ReviewViewModel(repository: repo)

        #expect(!vm.isUndoEnabled)
        vm.undoLastSwipe() // 不应崩溃
        #expect(vm.workingItems.isEmpty)
    }

    // MARK: - toggleAnswer

    @Test("toggleAnswer 每次调用切换 isAnswerShown")
    func toggleAnswer_togglesVisibility() throws {
        let repo = try createTestRepository()
        let vm = ReviewViewModel(repository: repo)

        #expect(vm.isAnswerShown == false)
        vm.toggleAnswer()
        #expect(vm.isAnswerShown == true)
        vm.toggleAnswer()
        #expect(vm.isAnswerShown == false)
    }

    // MARK: - quitSession

    @Test("quitSession 刷新数据并将 phase 设为 idle")
    func quitSession_refreshesAndReturnsIdle() async throws {
        let repo = try createTestRepository()
        try insertDueItem(in: repo)

        let vm = ReviewViewModel(repository: repo)
        await vm.loadDataAsync()
        vm.startSession()
        #expect(vm.phase == .reviewing)

        await vm.quitSession()

        #expect(vm.phase == .idle)
    }
}
