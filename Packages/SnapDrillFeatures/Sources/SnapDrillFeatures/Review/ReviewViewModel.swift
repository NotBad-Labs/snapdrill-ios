//
//  ReviewViewModel.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2026/02/24.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  复习会话的状态与业务逻辑管理，从 ReviewView 中提取。
//

import Foundation
import Observation
import SwiftData
import SnapDrillCore
import SnapDrillData

// MARK: - ReviewPhase

/// 复习流程阶段状态机
enum ReviewPhase {
    case loading
    case idle       // 仪表盘
    case reviewing  // 卡片复习中
    case finished   // 今日完成
}

// MARK: - ReviewViewModel

/// 复习会话 ViewModel
///
/// 管理复习流程的完整状态，包括：
/// - 待复习队列加载（SM-2 算法过滤）
/// - 会话的开始 / 暂停 / 结束
/// - 每张卡片的评分与调度更新
/// - 撤销上一次滑动
///
/// - Important: 必须在 `@MainActor` 上下文使用，因为它持有并直接操作 `ModelContext`。
@Observable
@MainActor
final class ReviewViewModel {

    // MARK: - 阶段状态

    var phase: ReviewPhase = .loading

    // MARK: - 队列数据

    /// 今日全部待复习条目
    var reviewQueue: [ReviewItemModel] = []
    /// 当前会话的工作栈（顶部 = 当前展示的卡片）
    var workingItems: [ReviewItemModel] = []
    /// 已完成卡片数量
    var finishedItems: Int = 0
    /// 撤销栈
    var undoStack: [ReviewItemModel] = []

    // MARK: - 统计

    /// 今日已复习总数（跨会话持久）
    var reviewedTodayCount: Int = 0
    /// 本次会话开始时已完成的数量（用于进度条计算）
    var sessionStartReviewedCount: Int = 0

    // MARK: - UI 交互状态

    var isAnswerShown: Bool = false
    var swipeTrigger: Int?
    var showPauseAlert: Bool = false
    var isProcessingSwipe: Bool = false
    var lastInteractionTime: Date = .distantPast
    var currentSwipeOffset: CGFloat = 0

    // MARK: - 常量

    /// 最小交互间隔（略长于卡片动画时长 0.5s），防止连击
    let minInteractionInterval: TimeInterval = 0.55

    // MARK: - Private

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// 从数据库加载今日待复习数据，刷新统计
    ///
    /// - Note: 仅在非复习进行中阶段切换 phase，避免打断用户
    func loadData(allItems: [ReviewItemModel]) {
        let now = Date()
        let due = allItems.filter { item in
            guard let next = item.nextReviewAt else { return true }
            return next <= now
        }.sorted { ($0.nextReviewAt ?? .distantPast) < ($1.nextReviewAt ?? .distantPast) }

        reviewQueue = due

        let today = Calendar.current.startOfDay(for: now)
        reviewedTodayCount = allItems.filter { item in
            guard let date = item.lastReviewedAt else { return false }
            return date >= today
        }.count

        if phase != .reviewing {
            phase = .idle
        }
    }

    /// 开始复习会话
    func startSession() {
        workingItems = reviewQueue
        finishedItems = 0
        undoStack.removeAll()
        isAnswerShown = false

        // 计算会话前已完成数，用于进度条连续显示
        let today = Calendar.current.startOfDay(for: Date())
        sessionStartReviewedCount = workingItems.isEmpty ? 0 : reviewedTodayCount

        phase = .reviewing
    }

    /// 暂停并退出当前会话
    func quitSession(allItems: [ReviewItemModel]) {
        loadData(allItems: allItems)
        phase = .idle
    }

    /// 翻转答案卡片
    func toggleAnswer() {
        isAnswerShown.toggle()
    }

    /// 触发按钮评分（好 / 忘记），节流防连击
    /// - Parameter rating: 1 = 好 (右滑), -1 = 忘记 (左滑)
    func triggerButtonRating(_ direction: Int) {
        let now = Date()
        guard now.timeIntervalSince(lastInteractionTime) >= minInteractionInterval,
              !isProcessingSwipe else { return }
        lastInteractionTime = now
        isProcessingSwipe = true
        swipeTrigger = direction
    }

    /// 处理卡片滑走后的回调
    ///
    /// 负责：从工作栈移除卡片、运行 SM-2 更新、持久化到数据库。
    /// - Parameter direction: 正数 = 右滑（记得），负数 = 左滑（忘记）
    func handleSwipeCompletion(direction: Int) {
        swipeTrigger = nil
        isProcessingSwipe = false
        currentSwipeOffset = 0

        guard let item = workingItems.first else { return }

        let removed = workingItems.removeFirst()
        undoStack.append(removed)
        finishedItems += 1
        isAnswerShown = false

        if workingItems.isEmpty {
            phase = .finished
        }

        // SM-2 调度更新
        let rating: ReviewRating = direction > 0 ? .good : .again
        let scheduler = ReviewScheduler()
        let updated = scheduler.scheduleNextReview(for: item.toEntity(), rating: rating)

        item.lastReviewedAt = updated.lastReviewedAt
        item.nextReviewAt = updated.nextReviewAt
        item.easeFactor = updated.easeFactor
        item.interval = updated.interval
        item.repetitions = updated.repetitions

        saveContext()
    }

    /// 撤销上一次滑动
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


    // MARK: - Private Helpers

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            SnapDrillLogger.generic.error("ReviewViewModel: 保存失败 \(error)")
        }
    }
}
