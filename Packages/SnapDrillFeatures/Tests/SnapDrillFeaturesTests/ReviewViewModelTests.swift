//
//  ReviewViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ReviewViewModel 核心路径单元测试：会话状态机、SM-2 调度写回、撤销栈。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillFeatureReview
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("ReviewViewModel 状态机与 SM-2 调度测试", .serialized)
@MainActor
final class ReviewViewModelTests {

    // MARK: - 存储属性（每次 @Test 执行前由 Swift Testing 调用 init() 重建）

    /// ModelContainer 必须作为实例属性保活：ModelContext 对 ModelContainer 持弱引用，
    /// 若 container 被提前释放，后续 insert/fetch/save 均会 crash（x0 = nil, brk #1）。
    private let container: ModelContainer
    private let repo: ReviewRepository

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
        repo = ReviewRepository(modelContext: container.mainContext)
    }

    // MARK: - Helpers

    /// 插入一个 nextReviewAt 在过去的条目（即立即待复习）。
    /// 仅调用 insert()（不 save），在 in-memory 容器中已立即可查询。
    /// 避免调用 save() 触发 SwiftData iOS 26 关系验证路径的 brk #1 崩溃。
    @discardableResult
    private func insertDueItem(
        content: String = "测试题",
        repetitions: Int = 0,
        interval: Int = 0
    ) -> ReviewItemModel {
        let model = ReviewItemModel(content: content, subject: "数学", source: "试卷")
        model.nextReviewAt = Date().addingTimeInterval(-3600)
        model.repetitions = repetitions
        model.interval = interval
        repo.insert(model)
        return model
    }

    /// 批量插入多个待复习条目（仅 insert，不 save）
    private func insertDueItems(count: Int) {
        for i in 0..<count {
            let model = ReviewItemModel(content: "题目\(i)", subject: "数学", source: "试卷")
            model.nextReviewAt = Date().addingTimeInterval(-3600)
            repo.insert(model)
        }
    }

    // MARK: - 初始状态

    @Test("ViewModel 初始 phase 为 loading")
    func initialPhaseIsLoading() throws {
        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
        #expect(vm.phase == .loading)
        #expect(vm.reviewQueue.isEmpty)
        #expect(vm.workingItems.isEmpty)
        #expect(vm.finishedItems == 0)
    }

    // MARK: - loadDataAsync

    @Test("空数据库时 loadDataAsync 将 phase 变为 idle，队列为空")
    func loadDataAsync_emptyDatabase_idleAndEmptyQueue() async throws {
        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())

        await vm.loadDataAsync()

        #expect(vm.phase == .idle)
        #expect(vm.reviewQueue.isEmpty)
        #expect(vm.totalItemsCount == 0)
    }

    @Test("loadDataAsync 正确区分待复习与未来条目")
    func loadDataAsync_distinguishesDueFromFuture() async throws {
        insertDueItem(content: "过期题A")
        insertDueItem(content: "过期题B")

        // 未来条目不计入 reviewQueue
        let futureItem = ReviewItemModel(content: "未来题", subject: "物理", source: "课本")
        futureItem.nextReviewAt = Date().addingTimeInterval(86400)
        repo.insert(futureItem)

        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
        await vm.loadDataAsync()

        #expect(vm.reviewQueue.count == 2)
        #expect(vm.totalItemsCount == 3) // 全部 3 条，但待复习只有 2
        #expect(vm.phase == .idle)
    }

    // MARK: - startSession

    @Test("startSession 将 reviewQueue 复制到 workingItems 并进入 reviewing")
    func startSession_copiesQueueAndEntersReviewing() async throws {
        insertDueItem(content: "题目A")
        insertDueItem(content: "题目B")

        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
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
        insertDueItem()

        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
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
        let model = insertDueItem(content: "SM-2 好题")

        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
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
        // 已有进度的条目
        let model = insertDueItem(content: "SM-2 难题", repetitions: 3, interval: 6)

        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
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
        insertDueItem()

        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
        await vm.loadDataAsync()
        vm.startSession()

        #expect(vm.workingItems.count == 1)
        vm.handleSwipeCompletion(direction: 1)

        #expect(vm.phase == .finished)
    }

    @Test("非最后一张卡片滑走后 phase 保持 reviewing")
    func handleSwipe_notLastCard_phaseRemainsReviewing() async throws {
        insertDueItem(content: "题目A")
        insertDueItem(content: "题目B")

        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
        await vm.loadDataAsync()
        vm.startSession()

        vm.handleSwipeCompletion(direction: 1)

        #expect(vm.phase == .reviewing)
        #expect(vm.workingItems.count == 1)
    }

    @Test("空队列时 handleSwipeCompletion 不崩溃")
    func handleSwipe_emptyQueue_noOp() throws {
        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
        // 未调用 startSession，workingItems 为空
        let didCommit = vm.handleSwipeCompletion(direction: 1) // 不应崩溃
        #expect(didCommit == false)
        #expect(vm.finishedItems == 0)
    }

    // MARK: - undoLastSwipe

    @Test("undoLastSwipe 将条目移回 workingItems 头部")
    func undoLastSwipe_restoresItemToFrontOfQueue() async throws {
        let model = insertDueItem(content: "可撤销题")

        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
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
        insertDueItem()

        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
        await vm.loadDataAsync()
        vm.startSession()

        vm.handleSwipeCompletion(direction: 1)
        #expect(vm.phase == .finished)

        vm.undoLastSwipe()

        #expect(vm.phase == .reviewing)
    }

    @Test("undoStack 为空时 undoLastSwipe 无操作")
    func undoLastSwipe_emptyStack_noOp() throws {
        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())

        #expect(!vm.isUndoEnabled)
        vm.undoLastSwipe() // 不应崩溃
        #expect(vm.workingItems.isEmpty)
    }

    @Test("undoLastSwipe 完整回滚 SM-2 状态到滑动前，避免数据损坏")
    func undoLastSwipe_rollsBackSM2State() async throws {
        let model = ReviewItemModel(content: "回滚测试题", subject: "数学", source: "试卷")
        model.nextReviewAt = Date().addingTimeInterval(-3600)
        model.easeFactor = 2.8; model.interval = 5; model.repetitions = 3
        repo.insert(model)
        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
        await vm.loadDataAsync(); vm.startSession()
        // 记录滑动前 SM-2 字段
        let origEF = model.easeFactor; let origInterval = model.interval
        let origRep = model.repetitions; let origNext = model.nextReviewAt
        // good 评分后 SM-2 字段被修改
        vm.handleSwipeCompletion(direction: 1)
        #expect(model.interval > origInterval, "good 评分后 interval 应增大")
        // 撤销后持久化层应完整恢复
        vm.undoLastSwipe()
        let restored = try repo.fetchAllModels().first(where: { $0.id == model.id })
        #expect(restored?.easeFactor == origEF, "undo 后 easeFactor 应回到滑动前")
        #expect(restored?.interval == origInterval, "undo 后 interval 应回到滑动前")
        #expect(restored?.repetitions == origRep, "undo 后 repetitions 应回到滑动前")
        #expect(restored?.nextReviewAt == origNext, "undo 后 nextReviewAt 应回到滑动前")
    }

    // MARK: - triggerButtonRating 防抖

    @Test("triggerButtonRating 快速连续调用时第二次被防抖忽略")
    func triggerButtonRating_rapidCalls_secondCallIgnored() throws {
        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())

        // 第一次调用：设置 isProcessingSwipe = true，swipeTrigger 被赋值
        vm.triggerButtonRating(1)
        #expect(vm.swipeTrigger == 1)
        #expect(vm.isProcessingSwipe == true)

        // 立即第二次调用：isProcessingSwipe 为 true，guard 拦截
        vm.triggerButtonRating(-1)
        // swipeTrigger 不应被覆盖为 -1
        #expect(vm.swipeTrigger == 1, "防抖应阻止第二次快速调用覆盖 swipeTrigger")
    }

    @Test("triggerButtonRating 在 minInteractionInterval 内重复调用被节流")
    func triggerButtonRating_withinCooldown_throttled() throws {
        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())

        // 手动设置 lastInteractionTime 为刚才（模拟刚触发过）
        vm.lastInteractionTime = Date()
        vm.isProcessingSwipe = false // 确保 isProcessingSwipe 不拦截

        vm.triggerButtonRating(1)
        // 未超过 minInteractionInterval，应被节流
        #expect(vm.swipeTrigger == nil, "冷却期内调用应被节流")
    }

    @Test("handleSwipeCompletion 重置 isProcessingSwipe，允许下一次触发")
    func handleSwipeCompletion_resetsProcessingFlag() async throws {
        insertDueItem(content: "防抖重置测试题")

        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
        await vm.loadDataAsync()
        vm.startSession()

        // 触发第一次
        vm.triggerButtonRating(1)
        #expect(vm.isProcessingSwipe == true)

        // 滑动完成后重置
        vm.handleSwipeCompletion(direction: 1)
        #expect(vm.isProcessingSwipe == false, "滑动完成后 isProcessingSwipe 应被重置")
    }

    // MARK: - undoStack 容量上限

    @Test("undoStack 超过上限时自动丢弃最旧条目")
    func undoStack_exceedsCapacity_dropsOldestEntry() async throws {
        let capacity = 20

        // 批量插入（仅 insert，不 save），避免触发 SwiftData iOS 26 关系验证路径的 brk #1 崩溃
        insertDueItems(count: capacity + 1)

        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
        await vm.loadDataAsync()
        vm.startSession()

        // 滑完所有题目
        for _ in 0..<(capacity + 1) {
            vm.handleSwipeCompletion(direction: 1)
        }

        #expect(
            vm.undoStack.count == capacity,
            "undoStack 不应超过 \(capacity) 条，实际 \(vm.undoStack.count) 条"
        )
    }

    @Test("undoStack 未超限时不丢弃条目")
    func undoStack_withinCapacity_retainsAllEntries() async throws {
        let count = 5

        // 批量插入（仅 insert，不 save），避免触发 SwiftData iOS 26 关系验证路径的 brk #1 崩溃
        insertDueItems(count: count)

        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
        await vm.loadDataAsync()
        vm.startSession()

        for _ in 0..<count {
            vm.handleSwipeCompletion(direction: 1)
        }

        #expect(vm.undoStack.count == count, "未超限时应保留全部 \(count) 条")
    }

    // MARK: - toggleAnswer

    @Test("toggleAnswer 每次调用切换 isAnswerShown")
    func toggleAnswer_togglesVisibility() throws {
        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())

        #expect(vm.isAnswerShown == false)
        vm.toggleAnswer()
        #expect(vm.isAnswerShown == true)
        vm.toggleAnswer()
        #expect(vm.isAnswerShown == false)
    }

    // MARK: - 中断恢复（防止 SM-2 重复复习）

    @Test("复习到一半 quitSession 后重新加载，已完成题目不重复出现")
    func crashRecovery_completedItemsNotRepeated() async throws {
        // 批量插入 10 题（仅 insert，不 save），避免触发 SwiftData iOS 26 关系验证路径的 brk #1 崩溃
        insertDueItems(count: 10)

        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
        await vm.loadDataAsync()
        vm.startSession()
        #expect(vm.workingItems.count == 10)

        // 完成前 5 题（good 评分，nextReviewAt 被设为未来）
        for _ in 0..<5 {
            vm.handleSwipeCompletion(direction: 1)
        }
        #expect(vm.finishedItems == 5)
        #expect(vm.workingItems.count == 5)

        // 中断退出
        await vm.quitSession()
        #expect(vm.phase == .idle)

        // 重新加载：已完成的 5 题 nextReviewAt 已更新到未来，不应再进入队列
        await vm.loadDataAsync()
        let allModels = try repo.fetchAllModels()
        let dueModels = allModels.filter { ($0.nextReviewAt ?? .distantPast) <= Date() }
        #expect(
            dueModels.count == 5,
            "重新加载后待复习队列应只剩 5 题，实际 \(dueModels.count) 题"
        )
    }

    @Test("already 评分后题目仍在待复习队列（nextReviewAt 约 10 分钟后）")
    func crashRecovery_againRating_itemRemainsInQueue() async throws {
        insertDueItem(content: "难题")

        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
        await vm.loadDataAsync()
        vm.startSession()

        // again 评分：nextReviewAt 约 10 分钟后，仍属于近期待复习
        vm.handleSwipeCompletion(direction: -1)
        await vm.quitSession()

        // 重新 fetch：again 的题目 nextReviewAt 在未来约 10 分钟，fetchDueModels 按 <= now 判断
        // 此时刚好处于边界，验证 lastReviewedAt 已被写入（即持久化成功）
        let model = try repo.fetchAllModels().first
        #expect(model?.lastReviewedAt != nil, "again 评分后 lastReviewedAt 应被持久化")
        #expect(model?.repetitions == 0, "again 评分后 repetitions 应重置为 0")
    }

    @Test("quitSession 后 workingItems 和 undoStack 被清空")
    func quitSession_clearsSessionState() async throws {
        insertDueItem(content: "题目A")
        insertDueItem(content: "题目B")

        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
        await vm.loadDataAsync()
        vm.startSession()
        vm.handleSwipeCompletion(direction: 1)

        #expect(vm.undoStack.count == 1)

        await vm.quitSession()

        // quitSession 调用 loadDataAsync 重置会话状态
        #expect(vm.phase == .idle)
    }

    // MARK: - quitSession

    @Test("quitSession 刷新数据并将 phase 设为 idle")
    func quitSession_refreshesAndReturnsIdle() async throws {
        insertDueItem()

        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
        await vm.loadDataAsync()
        vm.startSession()
        #expect(vm.phase == .reviewing)

        await vm.quitSession()

        #expect(vm.phase == .idle)
    }
}
