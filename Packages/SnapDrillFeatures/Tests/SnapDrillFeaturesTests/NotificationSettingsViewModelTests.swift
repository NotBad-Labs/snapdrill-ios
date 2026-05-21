//
//  NotificationSettingsViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  NotificationSettingsViewModel 核心路径单元测试：权限请求、Multi-Profile 隔离调度与取消。
//

import Testing
import Foundation
@testable import SnapDrillFeatureSettings
@testable import SnapDrillCore

// MARK: - Mock Notification Service

@MainActor
final class MockNotificationService: NotificationServiceProtocol {
    var requestPermissionResult: Bool = true
    var requestPermissionCallCount = 0
    var scheduleDailyCallCount = 0
    var scheduleDailyError: Error?
    var lastScheduledHour: Int?
    var lastScheduledMinute: Int?
    var lastScheduledProfileId: UUID?
    var cancelledProfileIds: [UUID] = []
    var cancelAllSnapDrillCallCount = 0

    func requestPermission() async -> Bool {
        requestPermissionCallCount += 1
        return requestPermissionResult
    }

    func scheduleDaily(at hour: Int, minute: Int, for scope: ProfileScope) async throws {
        scheduleDailyCallCount += 1
        lastScheduledHour = hour
        lastScheduledMinute = minute
        lastScheduledProfileId = scope.id
        if let error = scheduleDailyError {
            throw error
        }
    }

    func cancelDaily(for scope: ProfileScope) {
        cancelledProfileIds.append(scope.id)
    }

    func cancelAllSnapDrillNotifications() async {
        cancelAllSnapDrillCallCount += 1
    }
}

@MainActor
private func makeScope(_ name: String = "TestProfile") -> ProfileScope {
    ProfileScope(id: UUID(), name: name)
}

@Suite("NotificationSettingsViewModel 通知设置测试")
struct NotificationSettingsViewModelTests {

    // MARK: - enable

    @Test("enable 权限授予后安排当前 Profile 的每日通知")
    func enable_granted_schedules() async {
        let service = await MockNotificationService()
        await MainActor.run { service.requestPermissionResult = true }
        let scope = await makeScope()
        let vm = await NotificationSettingsViewModel(notificationService: service, profileScope: scope)

        let result = await vm.enable(hour: 9, minute: 0)

        #expect(result == true)
        await #expect(service.requestPermissionCallCount == 1)
        await #expect(service.scheduleDailyCallCount == 1)
        await #expect(service.lastScheduledHour == 9)
        await #expect(service.lastScheduledMinute == 0)
        await #expect(service.lastScheduledProfileId == scope.id)
        await #expect(vm.isPermissionDenied == false)
    }

    @Test("enable 权限拒绝时返回 false 并标记")
    func enable_denied_returnsFalse() async {
        let service = await MockNotificationService()
        await MainActor.run { service.requestPermissionResult = false }
        let scope = await makeScope()
        let vm = await NotificationSettingsViewModel(notificationService: service, profileScope: scope)

        let result = await vm.enable(hour: 9, minute: 0)

        #expect(result == false)
        await #expect(vm.isPermissionDenied == true)
        await #expect(service.scheduleDailyCallCount == 0)
    }

    @Test("enable 调度失败时返回 false 并精准回滚当前 Profile 的通知（不触碰其他 Profile）")
    func enable_scheduleFails_returnsFalseAndCancelsThisProfile() async {
        let service = await MockNotificationService()
        await MainActor.run {
            service.requestPermissionResult = true
            service.scheduleDailyError = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "调度失败"])
        }
        let scope = await makeScope()
        let vm = await NotificationSettingsViewModel(notificationService: service, profileScope: scope)

        let result = await vm.enable(hour: 9, minute: 0)

        #expect(result == false)
        await #expect(service.requestPermissionCallCount == 1)
        await #expect(service.scheduleDailyCallCount == 1)
        // 回滚必须用 cancelDaily(for: scope)，绝不能触发 cancelAllSnapDrillNotifications（防误杀其他 Profile）
        await #expect(service.cancelledProfileIds == [scope.id])
        await #expect(service.cancelAllSnapDrillCallCount == 0)
        await #expect(vm.rescheduleError != nil)
    }

    @Test("enable 并发重入保护")
    func enable_concurrentGuard() async {
        let service = await MockNotificationService()
        let scope = await makeScope()
        let vm = await NotificationSettingsViewModel(notificationService: service, profileScope: scope)
        await MainActor.run { vm.isRequesting = true }

        let result = await vm.enable(hour: 9, minute: 0)

        #expect(result == false)
        await #expect(service.requestPermissionCallCount == 0)
    }

    // MARK: - disable

    @Test("disable 仅取消当前 Profile 的通知（不影响其他 Profile）")
    func disable_cancelsCurrentProfileOnly() async {
        let service = await MockNotificationService()
        let scope = await makeScope()
        let vm = await NotificationSettingsViewModel(notificationService: service, profileScope: scope)

        await vm.disable()

        await #expect(service.cancelledProfileIds == [scope.id])
        await #expect(service.cancelAllSnapDrillCallCount == 0)
    }

    // MARK: - reschedule

    @Test("reschedule 重新安排当前 Profile 的通知时间")
    func reschedule_updatesScheduleForCurrentProfile() async {
        let service = await MockNotificationService()
        let scope = await makeScope()
        let vm = await NotificationSettingsViewModel(notificationService: service, profileScope: scope)

        let result = await vm.reschedule(hour: 20, minute: 30)

        #expect(result == true)
        await #expect(service.scheduleDailyCallCount == 1)
        await #expect(service.lastScheduledHour == 20)
        await #expect(service.lastScheduledMinute == 30)
        await #expect(service.lastScheduledProfileId == scope.id)
        await #expect(vm.rescheduleError == nil)
    }

    @Test("reschedule 失败时记录错误信息")
    func reschedule_error_setsErrorMessage() async {
        let service = await MockNotificationService()
        await MainActor.run {
            service.scheduleDailyError = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "调度失败"])
        }
        let scope = await makeScope()
        let vm = await NotificationSettingsViewModel(notificationService: service, profileScope: scope)

        let result = await vm.reschedule(hour: 20, minute: 30)

        #expect(result == false)
        await #expect(vm.rescheduleError != nil)
    }

    // MARK: - Multi-Profile 隔离（S-D4-002 修复验证）

    @Test("Multi-Profile：不同 ViewModel 调用 cancelDaily 只清自己 profile")
    func multiProfile_independentCancel() async {
        let service = await MockNotificationService()
        let scopeA = await ProfileScope(id: UUID(), name: "A")
        let scopeB = await ProfileScope(id: UUID(), name: "B")
        let vmA = await NotificationSettingsViewModel(notificationService: service, profileScope: scopeA)
        let vmB = await NotificationSettingsViewModel(notificationService: service, profileScope: scopeB)

        await vmA.disable()
        await vmB.disable()

        await #expect(service.cancelledProfileIds == [scopeA.id, scopeB.id])
    }
}
