//
//  DeletionScheduler.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  App 级删除调度器，管理 Soft Delete 的 5 秒撤销窗口。
//  与 App 生命周期等长，不随 View 释放而取消。
//

import Foundation

/// Soft Delete 调度结果
public enum DeletionUndoResult: Sendable {
    /// 撤销成功，返回恢复的 ID 集合
    case undone(Set<UUID>)
    /// 无待撤销的删除
    case noPending
}

/// Soft Delete 执行回调
public typealias DeletionExecutor = @Sendable (Set<UUID>) async -> Void

/// App 级删除调度器
///
/// 将 Soft Delete 的 5 秒撤销窗口从 ViewModel 下沉到 App 级 Service，
/// 确保 Tab 切换、页面离开不会中断倒计时。
@Observable public final class DeletionScheduler {

    public static let shared = DeletionScheduler()

    /// 当前待删除的 ID 集合（用于 UI 过滤显示）
    public private(set) var pendingDeletionIDs: Set<UUID> = []

    /// 待删除的数量（用于 Toast 显示）
    public private(set) var pendingDeletionCount: Int = 0

    /// 是否显示 undo toast
    public var showUndoToast: Bool = false

    @ObservationIgnored
    private var currentExecutor: DeletionExecutor?

    @ObservationIgnored
    private var commitTask: Task<Void, Never>?

    public init() {}

    /// 调度一批 Soft Delete（启动 5 秒倒计时）
    ///
    /// 如果有上一批未提交的删除，先立即提交上一批。
    /// executor 按批次传入，避免全局可变 executor 的竞态风险。
    public func scheduleDeletion(ids: Set<UUID>, executor: @escaping DeletionExecutor) {
        // 提交上一批（如有）
        if !pendingDeletionIDs.isEmpty {
            commitImmediately()
        }

        pendingDeletionIDs = ids
        pendingDeletionCount = ids.count
        showUndoToast = true
        currentExecutor = executor

        commitTask = Task {
            try? await Task.sleep(for: .seconds(5)) // best-effort: 5 秒撤销窗口，取消即 Undo，延迟中断不影响正确性
            guard !Task.isCancelled else { return }
            await commitPendingDeletion()
        }
    }

    /// 撤销当前待删除
    public func undoDeletion() -> DeletionUndoResult {
        commitTask?.cancel()
        commitTask = nil

        guard !pendingDeletionIDs.isEmpty else { return .noPending }

        let restored = pendingDeletionIDs
        pendingDeletionIDs.removeAll()
        pendingDeletionCount = 0
        currentExecutor = nil
        showUndoToast = false
        return .undone(restored)
    }

    /// 立即提交待删除（不等 5 秒）
    ///
    /// 同步捕获当前状态后 fire-and-forget，避免与后续
    /// `scheduleDeletion` 覆写 `pendingDeletionIDs` 产生竞态。
    public func commitImmediately() {
        commitTask?.cancel()
        commitTask = nil
        let idsToCommit = pendingDeletionIDs
        let executor = currentExecutor
        pendingDeletionIDs.removeAll()
        pendingDeletionCount = 0
        currentExecutor = nil
        showUndoToast = false
        guard !idsToCommit.isEmpty, let executor else { return }
        Task { await executor(idsToCommit) }
    }

    /// 同步捕获状态后执行删除（与 commitImmediately 相同模式，
    /// 防止 await 挂起期间 currentExecutor 被新批次覆写）
    private func commitPendingDeletion() async {
        let ids = pendingDeletionIDs
        let executor = currentExecutor
        guard !ids.isEmpty, let executor else { return }

        pendingDeletionIDs.removeAll()
        pendingDeletionCount = 0
        currentExecutor = nil
        showUndoToast = false

        await executor(ids)
    }
}
