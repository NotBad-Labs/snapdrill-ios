//
//  DashboardViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  首页仪表盘 ViewModel，管理统计数据加载与快捷操作状态。
//

import Foundation
import Observation
import SnapDrillCore
import SnapDrillData

@Observable
@MainActor
public final class DashboardViewModel {

    // MARK: - State

    public var isShowingSubjectManager = false
    public var isShowingDraftAlert = false

    /// 今日新增卡片数
    public var todayItemsCount: Int = 0
    /// 题库总卡片数量
    public var totalCount: Int = 0
    /// 今日待复习卡片数
    public var dueCount: Int = 0
    /// 今日已复习卡片数（用于进度环）
    public var reviewedTodayCount: Int = 0

    // MARK: - Dependencies

    /// 监听 reviewDataDidChange 通知的长驻任务句柄
    /// @ObservationIgnored：Task 不是 UI 状态，不应触发 Observation 追踪
    @ObservationIgnored
    private var dataChangeTask: Task<Void, Never>?
    /// 防抖任务句柄：新通知到来时 cancel 旧任务，避免批量写库时冗余查询
    @ObservationIgnored
    private var pendingRefreshTask: Task<Void, Never>?
    private let draftService: CaptureDraftServiceProtocol
    private let repositories: RepositoryContainer

    public init(
        repositories: RepositoryContainer,
        draftService: CaptureDraftServiceProtocol = CaptureDraftService.shared
    ) {
        self.repositories = repositories
        self.draftService = draftService

        setupDataChangeObserver()
    }

    // MARK: - Public API

    /// 加载并刷新统计数据
    ///
    /// 先将所有统计值读取到局部变量，全部成功后再统一写入属性，
    /// 避免中途抛出异常导致 UI 呈现部分更新的不一致状态。
    public func loadData() {
        do {
            let today = try repositories.review.fetchTodayCount()
            let total = try repositories.review.totalItemCount()
            let due = try repositories.review.fetchDueCount()
            let reviewed = try repositories.review.fetchTodayReviewedCount()
            todayItemsCount = today
            totalCount = total
            dueCount = due
            reviewedTodayCount = reviewed
        } catch {
            SnapDrillLogger.generic.error("加载统计数据失败: \(error.localizedDescription)")
        }
    }

    /// 取消所有进行中的异步任务（由 View 的 onDisappear 调用）
    public func cancelTasks() {
        dataChangeTask?.cancel()
        dataChangeTask = nil
        pendingRefreshTask?.cancel()
        pendingRefreshTask = nil
    }

    public func checkDraftAndCapture(router: DashboardRouter) {
        if draftService.hasDraft {
            isShowingDraftAlert = true
        } else {
            router.navigateToCapture()
        }
    }

    public func startNewCapture(router: DashboardRouter) {
        draftService.clearDraft()
        router.navigateToCapture()
    }

    public func restoreDraft(router: DashboardRouter) {
        if let draft = draftService.loadDraft() {
            router.navigateToCapture(withDraft: draft)
        } else {
            router.navigateToCapture()
        }
    }

    // MARK: - Private Helpers

    /// 用 async notification stream 监听数据变更，无需 NotificationCenter token + deinit 清理
    private func setupDataChangeObserver() {
        dataChangeTask = Task {
            for await _ in NotificationCenter.default.notifications(named: .reviewDataDidChange) {
                guard !Task.isCancelled else { break }
                // 防抖：cancel 上一次待执行的刷新，避免批量写库触发冗余查询
                pendingRefreshTask?.cancel()
                pendingRefreshTask = Task {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    guard !Task.isCancelled else { return }
                    SnapDrillLogger.generic.info("数据发生变更，刷新仪表盘...")
                    loadData()
                }
            }
        }
    }
}
