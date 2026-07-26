//
//  DashboardViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  首页仪表盘 ViewModel，管理资料概览加载与快捷操作状态。
//

import Foundation
import Observation
import SnapDrillCore
import SnapDrillData

/// 首页仪表盘 ViewModel
///
/// 负责加载首页概览数据、监听数据变更通知并触发刷新，以及处理草稿恢复流程。
@MainActor
@Observable
public final class DashboardViewModel {

    // MARK: - State

    /// 是否正在显示分类管理器 Sheet
    public var isShowingCategoryManager = false
    /// 是否正在显示草稿恢复提示 Alert
    public var isShowingDraftAlert = false
    public var isShowingUnrecoverableDraftAlert = false
    public var isShowingDraftVerificationError = false
    public private(set) var pendingDraft: CaptureDraft?
    public private(set) var pendingDraftFailure: CaptureDraftFailure?

    /// 今日新增资料数
    public var todayItemsCount: Int = 0
    /// 资料库总数
    public var totalCount: Int = 0

    // MARK: - Dependencies

    /// 监听 libraryDataDidChange 通知的长驻任务句柄
    /// @ObservationIgnored：Task 不是 UI 状态，不应触发 Observation 追踪
    @ObservationIgnored
    private var dataChangeTask: Task<Void, Never>?
    /// 防抖任务句柄：新通知到来时 cancel 旧任务，避免批量写库时冗余查询
    @ObservationIgnored
    private var pendingRefreshTask: Task<Void, Never>?
    private let draftService: CaptureDraftServiceProtocol
    private let repositories: RepositoryContainer

    /// 创建仪表盘 ViewModel
    /// - Parameters:
    ///   - repositories: 应用的数据仓库容器
    ///   - draftService: App 生命周期共享的草稿服务
    public init(
        repositories: RepositoryContainer,
        draftService: CaptureDraftServiceProtocol
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
            let today = try repositories.archive.fetchTodayCount()
            let total = try repositories.archive.totalItemCount()
            todayItemsCount = today
            totalCount = total
        } catch {
            // Dashboard 统计失败是 S3 级别：数据不影响任何操作流程，用户下次进入自动重试；
            // 不在 UI 展示错误状态，避免在首页增加不必要的视觉干扰
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

    /// 草稿提示详情文案（含分类和编辑时间）
    public var draftAlertMessage: String {
        guard let draft = pendingDraft else {
            return L10n.Dashboard.draftAlertMessage
        }
        let timeAgo = draft.date.relativeDescription()
        if let category = draft.category, !category.isEmpty {
            return L10n.Dashboard.draftAlertMessage(category: category, timeAgo: timeAgo)
        }
        return L10n.Dashboard.draftAlertMessage(timeAgo: timeAgo)
    }

    /// 检查是否有未完成草稿；若有则弹出提示，否则直接导航到采集页
    public func checkDraftAndCapture(router: DashboardRouter) async {
        await checkDraftAndCapture(router: router) { [repositories] captureID in
            try repositories.archive.fetchModel(by: captureID) != nil
        }
    }

    func checkDraftAndCapture(
        router: DashboardRouter,
        savedItemExists: (UUID) throws -> Bool
    ) async {
        isShowingDraftVerificationError = false
        switch await draftService.loadDraftState() {
        case .none:
            router.navigateToCapture()
        case .recoverable(let draft):
            let isAlreadyCommitted: Bool
            do {
                isAlreadyCommitted = try savedItemExists(draft.token.captureID)
            } catch {
                SnapDrillLogger.capture.error(
                    "Dashboard draft reconciliation lookup failed: \(error.localizedDescription)"
                )
                isShowingDraftVerificationError = true
                return
            }
            if isAlreadyCommitted {
                do {
                    try await draftService.discardDraft(expectedToken: draft.token)
                } catch {
                    SnapDrillLogger.capture.error(
                        "Dashboard draft reconciliation failed: \(error.localizedDescription)"
                    )
                    isShowingDraftVerificationError = true
                    return
                }
                router.navigateToCapture()
                return
            }
            pendingDraft = draft
            isShowingDraftAlert = true
        case .unrecoverable(let failure):
            pendingDraftFailure = failure
            isShowingUnrecoverableDraftAlert = true
        }
    }

    /// 丢弃现有草稿并开始新建采集
    public func startNewCapture(router: DashboardRouter) async {
        do {
            if let draft = pendingDraft {
                try await draftService.discardDraft(expectedToken: draft.token)
            } else if let token = pendingDraftFailure?.discardToken {
                try await draftService.discardUnrecoverableDraft(expectedToken: token)
            } else {
                return
            }
            pendingDraft = nil
            pendingDraftFailure = nil
            router.navigateToCapture()
        } catch {
            SnapDrillLogger.capture.error("Dashboard draft discard failed: \(error.localizedDescription)")
            isShowingDraftVerificationError = true
        }
    }

    /// 恢复草稿并导航到采集编辑页（无草稿时直接跳转采集页）
    public func restoreDraft(router: DashboardRouter) {
        if let draft = pendingDraft {
            router.navigateToCapture(withDraft: draft)
        } else {
            router.navigateToCapture()
        }
    }

    // MARK: - Private Helpers

    /// 用 async notification stream 监听数据变更，无需 NotificationCenter token + deinit 清理
    private func setupDataChangeObserver() {
        dataChangeTask = Task {
            for await _ in NotificationCenter.default.notifications(named: .libraryDataDidChange) {
                guard !Task.isCancelled else { break }
                // 防抖：cancel 上一次待执行的刷新，避免批量写库触发冗余查询
                pendingRefreshTask?.cancel()
                pendingRefreshTask = Task {
                    // best-effort: 防抖延迟，取消不影响正确性
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    guard !Task.isCancelled else { return }
                    SnapDrillLogger.generic.info("数据发生变更，刷新仪表盘...")
                    loadData()
                }
            }
        }
    }
}
