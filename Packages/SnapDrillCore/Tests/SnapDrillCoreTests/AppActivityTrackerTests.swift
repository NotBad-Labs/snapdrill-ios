//
//  AppActivityTrackerTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Testing
@testable import SnapDrillCore

@Suite("AppActivityTracker state")
@MainActor
struct AppActivityTrackerTests {
    @Test("initial state is empty")
    func initialStateIsEmpty() {
        #expect(AppActivityTracker().activeActivities.isEmpty)
    }

    @Test("begin and end track one activity")
    func beginThenEnd() {
        let tracker = AppActivityTracker()
        tracker.begin(.exporting)
        #expect(tracker.activeActivities == [.exporting])
        tracker.end(.exporting)
        #expect(tracker.activeActivities.isEmpty)
    }

    @Test("multiple activities remain until individually ended")
    func multipleActivities() {
        let tracker = AppActivityTracker()
        tracker.begin(.capturing)
        tracker.begin(.exporting)
        #expect(tracker.activeActivities == [.capturing, .exporting])
        tracker.end(.capturing)
        #expect(tracker.activeActivities == [.exporting])
    }

    @Test("duplicate begin is idempotent")
    func duplicateBeginIsIdempotent() {
        let tracker = AppActivityTracker()
        tracker.begin(.backupRestore)
        tracker.begin(.backupRestore)
        #expect(tracker.activeActivities.count == 1)
        tracker.end(.backupRestore)
        #expect(tracker.activeActivities.isEmpty)
    }

    @Test("ending an inactive activity is a no-op")
    func endWithoutBeginIsNoOp() {
        let tracker = AppActivityTracker()
        tracker.begin(.capturing)
        tracker.end(.printing)
        #expect(tracker.activeActivities == [.capturing])
    }
}
