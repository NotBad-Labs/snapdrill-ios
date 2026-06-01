//
//  AppActivityTrackerTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  AppActivityTracker 状态机契约单元测试（审计 #8：原零 oracle）。
//  覆盖 begin / end / canSwitchProfile / 多活动叠加 / Set 幂等 / 异常顺序 /
//  switchBlockReason，锁定「活动进行中阻塞 Profile 切换」这一数据丢失防护契约
//  （含审计 #7 担忧的 begin(.exporting) → canSwitchProfile == false）。
//

import Testing
import Foundation
@testable import SnapDrillCore

@Suite("AppActivityTracker 状态机契约测试")
@MainActor
struct AppActivityTrackerTests {

    // MARK: - 初始状态

    @Test("初始无活动：canSwitchProfile == true，activeActivities 为空")
    func initialState_allowsProfileSwitch() {
        let tracker = AppActivityTracker()
        #expect(tracker.canSwitchProfile == true)
        #expect(tracker.activeActivities.isEmpty)
        #expect(tracker.switchBlockReason == nil)
    }

    // MARK: - 单活动 begin / end

    @Test("begin 活动后阻塞 Profile 切换（含导出场景，审计 #7 核心契约）")
    func begin_blocksProfileSwitch() {
        let tracker = AppActivityTracker()
        tracker.begin(.exporting)
        #expect(tracker.canSwitchProfile == false)
        #expect(tracker.activeActivities.contains(.exporting))
        #expect(tracker.switchBlockReason != nil)
    }

    @Test("begin 后 end 恢复可切换")
    func beginThenEnd_restoresProfileSwitch() {
        let tracker = AppActivityTracker()
        tracker.begin(.exporting)
        tracker.end(.exporting)
        #expect(tracker.canSwitchProfile == true)
        #expect(tracker.activeActivities.isEmpty)
        #expect(tracker.switchBlockReason == nil)
    }

    // MARK: - 多活动叠加

    @Test("多活动叠加：全部结束前持续阻塞切换")
    func multipleActivities_blockUntilAllEnded() {
        let tracker = AppActivityTracker()
        tracker.begin(.capturing)
        tracker.begin(.exporting)
        #expect(tracker.activeActivities == [.capturing, .exporting])
        #expect(tracker.canSwitchProfile == false)

        tracker.end(.capturing)
        // 仍有 .exporting，继续阻塞
        #expect(tracker.canSwitchProfile == false)
        #expect(tracker.activeActivities == [.exporting])

        tracker.end(.exporting)
        #expect(tracker.canSwitchProfile == true)
    }

    // MARK: - Set 幂等

    @Test("重复 begin 同一活动幂等：单次 end 即清除")
    func duplicateBegin_isIdempotent() {
        let tracker = AppActivityTracker()
        tracker.begin(.backupRestore)
        tracker.begin(.backupRestore)
        #expect(tracker.activeActivities.count == 1)

        tracker.end(.backupRestore)
        #expect(tracker.activeActivities.isEmpty)
        #expect(tracker.canSwitchProfile == true)
    }

    // MARK: - 异常顺序

    @Test("end 未 begin 的活动：不崩溃、不影响其他活动状态")
    func endWithoutBegin_isNoOp() {
        let tracker = AppActivityTracker()
        tracker.begin(.capturing)
        tracker.end(.printing) // 从未 begin
        // .capturing 仍在，.printing 的 end 无副作用
        #expect(tracker.activeActivities == [.capturing])
        #expect(tracker.canSwitchProfile == false)
    }

    // MARK: - switchBlockReason

    @Test("switchBlockReason：无活动为 nil，有活动为非空描述")
    func switchBlockReason_reflectsActiveState() {
        let tracker = AppActivityTracker()
        #expect(tracker.switchBlockReason == nil)

        tracker.begin(.printing)
        let reason = tracker.switchBlockReason
        #expect(reason != nil)
        #expect(reason?.isEmpty == false)
    }
}
