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
    /// 撤销栈
    var undoStack: [ReviewItemModel] = []

    // MARK: - Statistics

    var reviewedTodayCount: Int = 0
    var totalItemsCount: Int = 0
    var sessionStartReviewedCount: Int = 0

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

    private let repository: ReviewRepository
    private let scheduler = ReviewScheduler()

    @ObservationIgnored
    nonisolated(unsafe) private var dataChangeObserver: Any?

    // MARK: - Initialization

    init(repository: ReviewRepository) {
        self.repository = repository
        setupDataChangeObserver()
    }

    deinit {
        if let observer = dataChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Private Setup

    private func setupDataChangeObserver() {
        dataChangeObserver = NotificationCenter.default.addObserver(
            forName: .reviewDataDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                // 仅在 idle 状态刷新，不打断正在进行的复习会话
                guard self.phase != .reviewing else { return }
                await self.loadDataAsync()
            }
        }
    }

    // MARK: - Public API

    /// 异步加载复习数据
    func loadDataAsync() async {
        do {
            let due = try repository.fetchDueModels()
            reviewQueue = due
            reviewedTodayCount = try repository.fetchTodayReviewedCount()
            totalItemsCount = try repository.totalItemCount()

            if phase != .reviewing {
                phase = .idle
            }
        } catch is CancellationError {
        } catch {
            SnapDrillLogger.generic.error("加载复习数据失败: \(error.localizedDescription)")
            if phase == .loading {
                phase = .idle
            }
        }
    }

    /// 开始复习会话
    func startSession() {
        workingItems = reviewQueue
        finishedItems = 0
        undoStack.removeAll()
        isAnswerShown = false
        sessionStartReviewedCount = reviewedTodayCount
        phase = .reviewing
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

        let removed = workingItems.removeFirst()
        undoStack.append(removed)
        // 超出容量时丢弃最旧的一条，防止内存无限增长
        if undoStack.count > undoStackCapacity {
            undoStack.removeFirst()
        }
        finishedItems += 1
        isAnswerShown = false

        if workingItems.isEmpty {
            phase = .finished
        }

        let rating: ReviewRating = direction > 0 ? .good : .again
        do {
            // 构建 SM-2 状态，调用调度引擎，直接写回 @Model 属性
            let state = SM2State(
                easeFactor: item.easeFactor,
                interval: item.interval,
                repetitions: item.repetitions
            )
            let newState = scheduler.scheduleNextReview(state: state, rating: rating)
            item.easeFactor = newState.easeFactor
            item.interval = newState.interval
            item.repetitions = newState.repetitions
            item.nextReviewAt = newState.nextReviewAt
            item.lastReviewedAt = newState.lastReviewedAt
            try repository.saveContext()
        } catch {
            SnapDrillLogger.generic.error("处理滑动结果失败: \(error.localizedDescription)")
        }
    }

    /// 撤销上一次滑动（仅恢复工作队列，不回滚 SM-2 状态）
    func undoLastSwipe() {
        guard !undoStack.isEmpty else { return }
        let item = undoStack.removeLast()
        workingItems.insert(item, at: 0)
        finishedItems -= 1
        isAnswerShown = false
        if phase == .finished {
            phase = .reviewing
        }
    }

    // MARK: - Computed

    var isUndoEnabled: Bool { !undoStack.isEmpty }
}
