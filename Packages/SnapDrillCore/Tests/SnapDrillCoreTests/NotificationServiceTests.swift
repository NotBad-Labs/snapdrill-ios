//
//  NotificationServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import Testing
import UserNotifications
@testable import SnapDrillCore

nonisolated private final class FakeNotificationCenter: UserNotificationScheduling, @unchecked Sendable {
    private var pending: [String: UNNotificationRequest] = [:]

    func add(_ request: UNNotificationRequest) async throws {
        pending[request.identifier] = request
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        Array(pending.values)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        for identifier in identifiers {
            pending.removeValue(forKey: identifier)
        }
    }

    func seed(_ request: UNNotificationRequest) {
        pending[request.identifier] = request
    }
}

private func dummyRequest(id: String) -> UNNotificationRequest {
    UNNotificationRequest(
        identifier: id,
        content: UNMutableNotificationContent(),
        trigger: nil
    )
}

@Suite("NotificationServiceMock tests")
struct NotificationServiceMockTests {
    @Test("requestPermission defaults to granted")
    func requestPermissionGrantedByDefault() async {
        let mock = NotificationServiceMock()
        #expect(await mock.requestPermission())
        #expect(mock.requestPermissionCallCount == 1)
    }

    @Test("scheduleDaily records and replaces the time")
    func scheduleDailyRecordsParameters() async throws {
        let mock = NotificationServiceMock()
        try await mock.scheduleDaily(at: 8, minute: 30)
        try await mock.scheduleDaily(at: 20, minute: 15)
        #expect(mock.scheduledTime?.hour == 20)
        #expect(mock.scheduledTime?.minute == 15)
    }

    @Test("scheduleDaily propagates simulated errors")
    func scheduleDailyThrowsWhenSimulated() async {
        let mock = NotificationServiceMock()
        mock.simulatedError = NSError(domain: "test", code: 1)
        await #expect(throws: (any Error).self) {
            try await mock.scheduleDaily(at: 8, minute: 0)
        }
        #expect(mock.scheduledTime == nil)
    }

    @Test("cancelDaily clears the schedule")
    func cancelDailyClearsSchedule() async throws {
        let mock = NotificationServiceMock()
        try await mock.scheduleDaily(at: 9, minute: 0)
        mock.cancelDaily()
        #expect(mock.scheduledTime == nil)
        #expect(mock.cancelDailyCallCount == 1)
    }

    @Test("reset clears tracked state")
    func resetClearsAllState() async throws {
        let mock = NotificationServiceMock()
        _ = await mock.requestPermission()
        try await mock.scheduleDaily(at: 9, minute: 0)
        mock.cancelDaily()
        mock.reset()
        #expect(mock.requestPermissionCallCount == 0)
        #expect(mock.scheduledTime == nil)
        #expect(mock.cancelDailyCallCount == 0)
        #expect(mock.cancelAllSnapDrillCallCount == 0)
    }
}

@Suite("LiveNotificationService single-library scheduling")
struct LiveNotificationServiceTests {
    @Test("daily review uses one managed identifier")
    func dailyReviewIdentifierIsStable() {
        #expect(SnapDrillNotificationID.dailyReview == "com.snapdrill.notification.daily-review")
        #expect(SnapDrillNotificationID.isManaged(SnapDrillNotificationID.dailyReview))
        #expect(SnapDrillNotificationID.isManaged(SnapDrillNotificationID.legacyDailyReview))
        #expect(!SnapDrillNotificationID.isManaged("com.other.unrelated-app"))
    }

    @Test("rescheduling leaves exactly one request")
    func scheduleDailyReplacesExistingSchedule() async throws {
        let center = FakeNotificationCenter()
        let service = LiveNotificationService(notificationCenter: center)
        try await service.scheduleDaily(at: 8, minute: 0)
        try await service.scheduleDaily(at: 20, minute: 30)
        let pending = await center.pendingNotificationRequests()
        #expect(pending.map(\.identifier) == [SnapDrillNotificationID.dailyReview])
    }

    @Test("scheduling removes legacy Profile-scoped requests but preserves external requests")
    func scheduleDailyRemovesRetiredIdentifiers() async throws {
        let center = FakeNotificationCenter()
        let service = LiveNotificationService(notificationCenter: center)
        center.seed(dummyRequest(id: "com.snapdrill.notification.daily-review.profile.legacy"))
        center.seed(dummyRequest(id: SnapDrillNotificationID.legacyDailyReview))
        center.seed(dummyRequest(id: "com.other.local-notification"))

        try await service.scheduleDaily(at: 20, minute: 0)

        let identifiers = Set(await center.pendingNotificationRequests().map(\.identifier))
        #expect(identifiers == [SnapDrillNotificationID.dailyReview, "com.other.local-notification"])
    }

    @Test("cancelDaily removes the one daily request")
    func cancelDailyRemovesSchedule() async throws {
        let center = FakeNotificationCenter()
        let service = LiveNotificationService(notificationCenter: center)
        try await service.scheduleDaily(at: 20, minute: 0)
        service.cancelDaily()
        #expect(await center.pendingNotificationRequests().isEmpty)
    }

    @Test("cancelAll removes managed requests only")
    func cancelAllKeepsExternalRequests() async {
        let center = FakeNotificationCenter()
        let service = LiveNotificationService(notificationCenter: center)
        center.seed(dummyRequest(id: SnapDrillNotificationID.dailyReview))
        center.seed(dummyRequest(id: "com.snapdrill.notification.daily-review.profile.legacy"))
        center.seed(dummyRequest(id: "com.other.local-notification"))
        await service.cancelAllSnapDrillNotifications()
        let identifiers = Set(await center.pendingNotificationRequests().map(\.identifier))
        #expect(identifiers == ["com.other.local-notification"])
    }
}
