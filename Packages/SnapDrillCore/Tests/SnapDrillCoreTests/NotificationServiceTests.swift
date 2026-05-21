//
//  NotificationServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  通知服务 Mock 与 LiveNotificationService 的单元测试。
//  Multi-Profile 隔离（S-D4-002 修复）通过 FakeNotificationCenter facade 覆盖。
//

import Testing
import Foundation
import UserNotifications
@testable import SnapDrillCore

// MARK: - Fake Notification Center（facade for testing LiveNotificationService）
//
// 每个测试 @Test 创建独立 FakeNotificationCenter 实例，单测内只一个 task 序列化访问，
// 所以无需内部加锁。Sendable 用 @unchecked 标注以兼容 UNNotificationRequest 非 Sendable 限制。

nonisolated private final class FakeNotificationCenter: UserNotificationScheduling, @unchecked Sendable {
    private var pending: [String: UNNotificationRequest] = [:]
    private(set) var removedBatches: [[String]] = []

    func add(_ request: UNNotificationRequest) async throws {
        pending[request.identifier] = request
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        Array(pending.values)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedBatches.append(identifiers)
        for identifier in identifiers {
            pending.removeValue(forKey: identifier)
        }
    }

    func seed(_ request: UNNotificationRequest) {
        pending[request.identifier] = request
    }
}

private func makeScope(_ uuid: String) -> ProfileScope {
    guard let id = UUID(uuidString: uuid) else {
        fatalError("Invalid UUID literal in test fixture: \(uuid)")
    }
    return ProfileScope(id: id, name: uuid)
}

private func dummyRequest(id: String) -> UNNotificationRequest {
    UNNotificationRequest(
        identifier: id,
        content: UNMutableNotificationContent(),
        trigger: nil
    )
}

@Suite("NotificationServiceMock 测试")
struct NotificationServiceMockTests {

    @Test("requestPermission 默认返回 true")
    func requestPermissionGrantedByDefault() async {
        let mock = NotificationServiceMock()
        let result = await mock.requestPermission()
        #expect(result == true)
        #expect(mock.requestPermissionCallCount == 1)
    }

    @Test("requestPermission 模拟拒绝权限时返回 false")
    func requestPermissionDenied() async {
        let mock = NotificationServiceMock()
        mock.simulatedPermissionGranted = false
        let result = await mock.requestPermission()
        #expect(result == false)
    }

    @Test("scheduleDaily 正常调用按 profile 记录参数")
    func scheduleDailyRecordsParameters() async throws {
        let mock = NotificationServiceMock()
        let scope = ProfileScope(id: UUID(), name: "A")
        try await mock.scheduleDaily(at: 8, minute: 30, for: scope)
        #expect(mock.schedulesByProfile[scope.id]?.hour == 8)
        #expect(mock.schedulesByProfile[scope.id]?.minute == 30)
    }

    @Test("scheduleDaily 同 profile 后者覆盖前者")
    func scheduleDailyOverwritesSameProfile() async throws {
        let mock = NotificationServiceMock()
        let scope = ProfileScope(id: UUID(), name: "A")
        try await mock.scheduleDaily(at: 8, minute: 0, for: scope)
        try await mock.scheduleDaily(at: 20, minute: 30, for: scope)
        #expect(mock.schedulesByProfile[scope.id]?.hour == 20)
    }

    @Test("scheduleDaily 模拟错误时应抛出")
    func scheduleDailyThrowsWhenSimulated() async throws {
        let mock = NotificationServiceMock()
        let scope = ProfileScope(id: UUID(), name: "A")
        mock.simulatedError = NSError(domain: "test", code: 1)
        await #expect(throws: (any Error).self) {
            try await mock.scheduleDaily(at: 8, minute: 0, for: scope)
        }
        #expect(mock.schedulesByProfile[scope.id] == nil)
    }

    @Test("cancelDaily 按 profile 记录")
    func cancelDailyRecordsProfile() {
        let mock = NotificationServiceMock()
        let scopeA = ProfileScope(id: UUID(), name: "A")
        mock.cancelDaily(for: scopeA)
        #expect(mock.cancelledProfileIds == [scopeA.id])
    }

    @Test("reset 清空所有追踪状态")
    func resetClearsAllState() async throws {
        let mock = NotificationServiceMock()
        let scope = ProfileScope(id: UUID(), name: "A")
        _ = await mock.requestPermission()
        try await mock.scheduleDaily(at: 9, minute: 0, for: scope)
        mock.cancelDaily(for: scope)

        mock.reset()

        #expect(mock.requestPermissionCallCount == 0)
        #expect(mock.schedulesByProfile.isEmpty)
        #expect(mock.cancelledProfileIds.isEmpty)
        #expect(mock.cancelAllSnapDrillCallCount == 0)
        #expect(mock.simulatedPermissionGranted == true)
        #expect(mock.simulatedError == nil)
    }
}

// MARK: - S-D4-002 Multi-Profile 隔离（LiveNotificationService via FakeCenter facade）

@Suite("LiveNotificationService Multi-Profile 隔离（S-D4-002）")
struct LiveNotificationServiceMultiProfileTests {

    @Test("通知 ID namespace 含通知类型 + Profile ID + lowercase UUID")
    func dailyReviewIdentifierIsProfileScoped() throws {
        let profileA = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000041"))
        let profileB = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000042"))

        let idA = SnapDrillNotificationID.dailyReview(for: profileA)
        let idB = SnapDrillNotificationID.dailyReview(for: profileB)

        #expect(idA.hasPrefix("com.snapdrill.notification.daily-review.profile."))
        #expect(idA.contains(profileA.uuidString.lowercased()))
        #expect(idA != idB)
        #expect(idA != SnapDrillNotificationID.legacyDailyReview)
        // managed prefix 防御
        #expect(SnapDrillNotificationID.isManaged(idA))
        #expect(SnapDrillNotificationID.isManaged(SnapDrillNotificationID.legacyDailyReview))
        #expect(!SnapDrillNotificationID.isManaged("com.other.unrelated-app"))
    }

    @Test("同一 Profile 重复 scheduleDaily 只覆盖自身通知，不影响其他 Profile")
    func scheduleDailyReplacesOnlySameProfile() async throws {
        let center = FakeNotificationCenter()
        let service = LiveNotificationService(notificationCenter: center)
        let profileA = makeScope("00000000-0000-0000-0000-000000000001")
        let profileB = makeScope("00000000-0000-0000-0000-000000000002")

        try await service.scheduleDaily(at: 8, minute: 0, for: profileA)
        try await service.scheduleDaily(at: 19, minute: 0, for: profileB)
        try await service.scheduleDaily(at: 20, minute: 30, for: profileA)

        let pending = await center.pendingNotificationRequests()
        let identifiers = Set(pending.map(\.identifier))
        #expect(identifiers == [
            SnapDrillNotificationID.dailyReview(for: profileA.id),
            SnapDrillNotificationID.dailyReview(for: profileB.id)
        ])
    }

    @Test("Profile A 设置后切到 B 设置不会擦除 A 的 pending（核心 S-D4-002 修复）")
    func scheduleDailyForBPreservesA() async throws {
        let center = FakeNotificationCenter()
        let service = LiveNotificationService(notificationCenter: center)
        let profileA = makeScope("00000000-0000-0000-0000-000000000011")
        let profileB = makeScope("00000000-0000-0000-0000-000000000012")

        try await service.scheduleDaily(at: 20, minute: 0, for: profileA)
        try await service.scheduleDaily(at: 19, minute: 0, for: profileB)

        let identifiers = Set(await center.pendingNotificationRequests().map(\.identifier))
        #expect(identifiers.contains(SnapDrillNotificationID.dailyReview(for: profileA.id)))
        #expect(identifiers.contains(SnapDrillNotificationID.dailyReview(for: profileB.id)))
        #expect(identifiers.count == 2)
    }

    @Test("cancelDaily on Profile A 只擦 A 通知，不影响 B")
    func cancelDailyRemovesOnlySelectedProfile() async throws {
        let center = FakeNotificationCenter()
        let service = LiveNotificationService(notificationCenter: center)
        let profileA = makeScope("00000000-0000-0000-0000-000000000021")
        let profileB = makeScope("00000000-0000-0000-0000-000000000022")

        try await service.scheduleDaily(at: 20, minute: 0, for: profileA)
        try await service.scheduleDaily(at: 19, minute: 0, for: profileB)
        service.cancelDaily(for: profileA)

        let identifiers = Set(await center.pendingNotificationRequests().map(\.identifier))
        #expect(!identifiers.contains(SnapDrillNotificationID.dailyReview(for: profileA.id)))
        #expect(identifiers.contains(SnapDrillNotificationID.dailyReview(for: profileB.id)))
    }

    @Test("cancelAllSnapDrillNotifications 只删除 managed namespace，不触碰第三方")
    func cancelAllSnapDrillNotificationsKeepsExternalRequests() async throws {
        let center = FakeNotificationCenter()
        let service = LiveNotificationService(notificationCenter: center)
        let profileA = makeScope("00000000-0000-0000-0000-000000000031")
        let profileB = makeScope("00000000-0000-0000-0000-000000000032")
        center.seed(dummyRequest(id: SnapDrillNotificationID.dailyReview(for: profileA.id)))
        center.seed(dummyRequest(id: SnapDrillNotificationID.dailyReview(for: profileB.id)))
        center.seed(dummyRequest(id: "com.other.local-notification"))

        await service.cancelAllSnapDrillNotifications()

        let identifiers = Set(await center.pendingNotificationRequests().map(\.identifier))
        #expect(identifiers == ["com.other.local-notification"])
    }

    @Test("scheduleDaily 触发 legacy daily-review ID 级联清理（升级路径）")
    func scheduleDailyRemovesLegacyIdentifier() async throws {
        let center = FakeNotificationCenter()
        let service = LiveNotificationService(notificationCenter: center)
        let profileA = makeScope("00000000-0000-0000-0000-000000000051")
        center.seed(dummyRequest(id: SnapDrillNotificationID.legacyDailyReview))

        try await service.scheduleDaily(at: 20, minute: 0, for: profileA)

        let identifiers = Set(await center.pendingNotificationRequests().map(\.identifier))
        #expect(!identifiers.contains(SnapDrillNotificationID.legacyDailyReview))
        #expect(identifiers.contains(SnapDrillNotificationID.dailyReview(for: profileA.id)))
    }
}
