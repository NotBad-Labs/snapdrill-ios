//
//  DeletionSchedulerTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/04/12.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  DeletionScheduler 状态机单元测试。
//

import Testing
import Foundation
import Synchronization
@testable import SnapDrillCore

@Suite("DeletionScheduler 状态机测试")
struct DeletionSchedulerTests {

    // 每个测试前清理 shared 状态，防止跨测试泄漏
    init() {
        _ = DeletionScheduler.shared.undoDeletion()
    }

    // MARK: - scheduleDeletion

    @Test("调度删除后 pendingDeletionIDs 和 UI 状态正确")
    func scheduleDeletionSetsState() {
        let scheduler = DeletionScheduler.shared
        let ids: Set<UUID> = [UUID(), UUID(), UUID()]

        scheduler.scheduleDeletion(ids: ids) { _ in }

        #expect(scheduler.pendingDeletionIDs == ids)
        #expect(scheduler.pendingDeletionCount == 3)
        #expect(scheduler.showUndoToast == true)

        // 清理
        _ = scheduler.undoDeletion()
    }

    @Test("空集合调度后不应有 pending 状态")
    func scheduleDeletionEmptyIds() {
        let scheduler = DeletionScheduler.shared

        scheduler.scheduleDeletion(ids: []) { _ in }

        // 空集合不应触发有意义的 pending 状态
        // （当前实现会设置空集合，未来应优化为 no-op）
        #expect(scheduler.pendingDeletionCount == 0)

        _ = scheduler.undoDeletion()
    }

    // MARK: - undoDeletion

    @Test("撤销删除返回恢复的 ID 集合")
    func undoDeletionReturnsIds() {
        let scheduler = DeletionScheduler.shared
        let ids: Set<UUID> = [UUID(), UUID()]

        scheduler.scheduleDeletion(ids: ids) { _ in }
        let result = scheduler.undoDeletion()

        if case .undone(let restored) = result {
            #expect(restored == ids)
        } else {
            Issue.record("预期 .undone，实际 \(result)")
        }

        #expect(scheduler.pendingDeletionIDs.isEmpty)
        #expect(scheduler.pendingDeletionCount == 0)
        #expect(scheduler.showUndoToast == false)
    }

    @Test("无 pending 时撤销返回 .noPending")
    func undoDeletionNoPending() {
        let scheduler = DeletionScheduler.shared

        let result = scheduler.undoDeletion()

        if case .noPending = result {
            // 正确
        } else {
            Issue.record("预期 .noPending，实际 \(result)")
        }
    }

    // MARK: - commitImmediately

    @Test("立即提交后清除 pending 状态")
    func commitImmediatelyClearsState() {
        let scheduler = DeletionScheduler.shared

        scheduler.scheduleDeletion(ids: [UUID()]) { _ in }
        scheduler.commitImmediately()

        #expect(scheduler.pendingDeletionIDs.isEmpty)
        #expect(scheduler.pendingDeletionCount == 0)
        #expect(scheduler.showUndoToast == false)
    }

    @Test("立即提交调用 executor 并传入正确 ID")
    func commitImmediatelyCallsExecutor() async throws {
        let scheduler = DeletionScheduler.shared
        let ids: Set<UUID> = [UUID(), UUID()]

        let executed = Mutex(false)
        let receivedIds = Mutex<Set<UUID>>([])

        scheduler.scheduleDeletion(ids: ids) { deletedIds in
            executed.withLock { $0 = true }
            receivedIds.withLock { $0 = deletedIds }
        }
        scheduler.commitImmediately()

        // 等待 fire-and-forget Task 执行
        try await Task.sleep(for: .milliseconds(100))

        #expect(executed.withLock { $0 } == true)
        #expect(receivedIds.withLock { $0 } == ids)
    }

    @Test("无 pending 时 commitImmediately 不崩溃")
    func commitImmediatelyNoPending() {
        let scheduler = DeletionScheduler.shared
        // 不应崩溃
        scheduler.commitImmediately()
        #expect(scheduler.pendingDeletionIDs.isEmpty)
    }

    // MARK: - 连续调度

    @Test("连续调度时前一批被立即提交")
    func consecutiveScheduleCommitsPrevious() async throws {
        let scheduler = DeletionScheduler.shared
        let firstIds: Set<UUID> = [UUID()]
        let secondIds: Set<UUID> = [UUID()]

        let firstExecuted = Mutex(false)
        let secondExecuted = Mutex(false)

        scheduler.scheduleDeletion(ids: firstIds) { _ in
            firstExecuted.withLock { $0 = true }
        }

        // 第二次调度应立即提交第一批
        scheduler.scheduleDeletion(ids: secondIds) { _ in
            secondExecuted.withLock { $0 = true }
        }

        // 等待第一批的 fire-and-forget 执行
        try await Task.sleep(for: .milliseconds(100))

        #expect(firstExecuted.withLock { $0 } == true)
        #expect(secondExecuted.withLock { $0 } == false)
        #expect(scheduler.pendingDeletionIDs == secondIds)

        _ = scheduler.undoDeletion()
    }

    // MARK: - 5 秒倒计时

    @Test("5 秒倒计时后 executor 自动执行")
    func timerExecutesAfterDelay() async throws {
        let scheduler = DeletionScheduler.shared
        let ids: Set<UUID> = [UUID()]

        let executed = Mutex(false)

        scheduler.scheduleDeletion(ids: ids) { _ in
            executed.withLock { $0 = true }
        }

        // 等待 5 秒 + 余量
        try await Task.sleep(for: .seconds(5.5))

        #expect(executed.withLock { $0 } == true)
        #expect(scheduler.pendingDeletionIDs.isEmpty)
    }

    @Test("5 秒内撤销则 executor 不执行")
    func undoBeforeTimerPreventsExecution() async throws {
        let scheduler = DeletionScheduler.shared
        let ids: Set<UUID> = [UUID()]

        let executed = Mutex(false)

        scheduler.scheduleDeletion(ids: ids) { _ in
            executed.withLock { $0 = true }
        }

        // 1 秒后撤销
        try await Task.sleep(for: .seconds(1))
        _ = scheduler.undoDeletion()

        // 再等 5 秒确认 executor 没被调用
        try await Task.sleep(for: .seconds(5))

        #expect(executed.withLock { $0 } == false)
    }
}
