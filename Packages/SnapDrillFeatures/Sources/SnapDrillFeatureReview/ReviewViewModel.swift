//
//  ReviewViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  复习会话的状态与业务逻辑管理，直接依赖 ReviewRepository 和 ReviewScheduler。
//

import Foundation
import Observation
import SnapDrillCore
import SnapDrillData

// MARK: - ReviewPhase

/// 复习流程阶段状态机
enum ReviewPhase: Equatable {
    case loading
    case idle       // 仪表盘
    case reviewing  // 卡片复习中
    case finished   // 今日完成
    case error      // 数据加载失败
}

// MARK: - UndoEntry

/// 撤销栈条目，记录滑动前的 SM-2 状态和评分
struct UndoEntry {
    let item: ReviewItemModel
    let previousState: SM2State
    let rating: ReviewRating
}

// MARK: - ReviewViewModel

/// 复习会话 ViewModel
@Observable
@MainActor
final class ReviewViewModel {

    // MARK: - Properties

    var phase: ReviewPhase = .loading

    /// 今日全部待复习条目
    var reviewQueue: [ReviewItemModel] = []
    /// 当前会话的工作栈
    var workingItems: [ReviewItemModel] = []
    /// 已完成卡片数量
    var finishedItems: Int = 0
    /// 撤销栈（记录滑动前的 SM-2 状态和评分，确保 undo 可完整回滚数据和统计）
    var undoStack: [UndoEntry] = []

    // MARK: - Statistics

    var reviewedTodayCount: Int = 0
    var totalItemsCount: Int = 0
    var sessionStartReviewedCount: Int = 0
    /// 本次会话中"记得"（右滑）的卡片数
    var sessionGoodCount: Int = 0
    /// 本次会话中"忘记"（左滑）的卡片数
    var sessionAgainCount: Int = 0

    // MARK: - State

    var isAnswerShown: Bool = false
    var swipeTrigger: Int?
    var showPauseAlert: Bool = false
    var isProcessingSwipe: Bool = false
    var lastInteractionTime: Date = .distantPast
    var currentSwipeOffset: CGFloat = 0

    // MARK: - Constants

    let minInteractionInterval: TimeInterval = 0.55
    /// undoStack 最大容量，防止长时间复习导致内存无限增长
    let undoStackCapacity: Int = 20

    // MARK: - Dependencies

    // ReviewRepository 标注为 @MainActor final class，
    // 在 @MainActor ViewModel 中调用其方法（含 saveContext）完全线程安全。
    private let repository: ReviewRepository
    private let scheduler = ReviewScheduler()

    @ObservationIgnored
    private var dataChangeTask: Task<Void, Never>?

    // MARK: - Initialization

    init(repository: ReviewRepository) {
        self.repository = repository
    }

    // MARK: - Public API

    /// 启动数据变更监听（在 View 的 onAppear 调用）
    func startObservingDataChanges() {
        dataChangeTask?.cancel()
        dataChangeTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .reviewDataDidChange) {
                guard let self else { break }
                // 仅在 idle 状态刷新，不打断正在进行的复习会话
                guard self.phase != .reviewing else { continue }
                await self.loadDataAsync()
            }
        }
    }

    /// 取消数据变更监听（在 View 的 onDisappear 调用）
    func cancelObserving() {
        dataChangeTask?.cancel()
        dataChangeTask = nil
    }

    // MARK: - Public API

    /// 异步加载复习数据
    func loadDataAsync() async {
        do {
            let due = try repository.fetchDueModels()
            reviewQueue = due
            reviewedTodayCount = try repository.fetchTodayReviewedCount()
            totalItemsCount = try repository.totalItemCount()

            // 仅在初始加载阶段（.loading）才切换为 .idle；
            // 不覆盖 .finished（防止数据刷新通知将"今日完成"页强制踢回仪表盘）
            if phase == .loading {
                phase = .idle
            }
        } catch is CancellationError {
        } catch {
            SnapDrillLogger.generic.error("加载复习数据失败: \(error.localizedDescription)")
            if phase == .loading {
                phase = .error
            }
        }
    }

    /// 重试加载数据（从错误状态恢复）
    func retryLoading() async {
        // 防止重复点击：仅在 error 状态下允许重试
        guard phase == .error else { return }
        phase = .loading
        await loadDataAsync()
    }

    /// 开始复习会话
    func startSession() {
        workingItems = reviewQueue
        finishedItems = 0
        sessionGoodCount = 0
        sessionAgainCount = 0
        undoStack.removeAll()
        isAnswerShown = false
        sessionStartReviewedCount = reviewedTodayCount
        // 队列为空时直接进入 finished，防止进入 reviewing 后无卡片可操作的死状态
        phase = workingItems.isEmpty ? .finished : .reviewing
    }

    /// 暂停并退出当前会话
    func quitSession() async {
        await loadDataAsync()
        phase = .idle
    }

    func toggleAnswer() {
        isAnswerShown.toggle()
    }

    func triggerButtonRating(_ direction: Int) {
        let now = Date()
        guard now.timeIntervalSince(lastInteractionTime) >= minInteractionInterval,
              !isProcessingSwipe else { return }
        lastInteractionTime = now
        isProcessingSwipe = true
        swipeTrigger = direction
    }

    /// 处理卡片滑动完成：更新 SM-2 状态并持久化
    func handleSwipeCompletion(direction: Int) {
        swipeTrigger = nil
        isProcessingSwipe = false
        currentSwipeOffset = 0

        guard let item = workingItems.first else { return }

        // 在修改 SM-2 字段前，保存旧状态供 undo 完整回滚
        let previousState = SM2State(
            easeFactor: item.easeFactor,
            interval: item.interval,
            repetitions: item.repetitions,
            nextReviewAt: item.nextReviewAt,
            lastReviewedAt: item.lastReviewedAt
        )

        // 先写 @Model 并尝试持久化；保存成功后才更新 UI 状态，
        // 确保持久化失败时 rollback 可完整还原，不留部分更新。
        let rating: ReviewRating = direction > 0 ? .good : .again
        let newState = scheduler.scheduleNextReview(state: previousState, rating: rating)
        item.easeFactor = newState.easeFactor
        item.interval = newState.interval
        item.repetitions = newState.repetitions
        // SM2State 的 Date? 解包：distantPast 作为"从未复习/立即到期"哨兵值
        item.nextReviewAt = newState.nextReviewAt ?? Date.distantPast
        item.lastReviewedAt = newState.lastReviewedAt ?? Date.distantPast
        do {
            try repository.saveContext()
        } catch {
            // 持久化失败：回滚 @Model 变更并提前返回，UI 状态保持不变
            repository.rollbackContext()
            SnapDrillLogger.generic.error("处理滑动结果失败: \(error.localizedDescription)")
            return
        }

        // 持久化成功后更新 UI 状态
        let removed = workingItems.removeFirst()
        undoStack.append(UndoEntry(item: removed, previousState: previousState, rating: rating))
        if rating == .good {
            sessionGoodCount += 1
        } else {
            sessionAgainCount += 1
        }
        // 超出容量时丢弃最旧的一条，防止内存无限增长
        if undoStack.count > undoStackCapacity {
            undoStack.removeFirst()
        }
        finishedItems += 1
        isAnswerShown = false
        if workingItems.isEmpty {
            phase = .finished
        }
    }

    /// 撤销上一次滑动，同时回滚 SM-2 状态并持久化
    func undoLastSwipe() {
        guard !undoStack.isEmpty else { return }
        let entry = undoStack.removeLast()
        // 将 SM-2 字段回滚到滑动前的旧状态
        entry.item.easeFactor = entry.previousState.easeFactor
        entry.item.interval = entry.previousState.interval
        entry.item.repetitions = entry.previousState.repetitions
        entry.item.nextReviewAt = entry.previousState.nextReviewAt ?? Date.distantPast
        entry.item.lastReviewedAt = entry.previousState.lastReviewedAt ?? Date.distantPast
        do {
            try repository.saveContext()
        } catch {
            // 持久化失败：先将 entry 放回栈，确保用户可再次尝试撤销；
            // 再 rollback @Model，恢复字段为滑动后状态；最后提前返回，
            // 阻止 workingItems/finishedItems 更新，防止内存与磁盘不一致。
            undoStack.append(entry)
            repository.rollbackContext()
            SnapDrillLogger.generic.error("撤销保存失败: \(error.localizedDescription)")
            return
        }
        workingItems.insert(entry.item, at: 0)
        // @MainActor 保证单线程访问，max(0,...) 仅作防御性下界保护，无竞态风险
        finishedItems = max(0, finishedItems - 1)
        if entry.rating == .good {
            sessionGoodCount = max(0, sessionGoodCount - 1)
        } else {
            sessionAgainCount = max(0, sessionAgainCount - 1)
        }
        isAnswerShown = false
        if phase == .finished {
            phase = .reviewing
        }
    }

    // MARK: - Computed

    var isUndoEnabled: Bool { !undoStack.isEmpty }
}
