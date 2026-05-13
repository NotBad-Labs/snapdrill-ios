//
//  NotificationSettingsViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/03/09.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  NotificationSettingsViewModel 核心路径单元测试：权限请求、调度、取消。
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
    var cancelAllCallCount = 0

    func requestPermission() async -> Bool {
        requestPermissionCallCount += 1
        return requestPermissionResult
    }

    func scheduleDaily(at hour: Int, minute: Int) async throws {
        scheduleDailyCallCount += 1
        lastScheduledHour = hour
        lastScheduledMinute = minute
        if let error = scheduleDailyError {
            throw error
        }
    }

    func cancelAll() {
        cancelAllCallCount += 1
    }
}

@Suite("NotificationSettingsViewModel 通知设置测试")
struct NotificationSettingsViewModelTests {

    // MARK: - enable

    @Test("enable 权限授予后安排每日通知")
    func enable_granted_schedules() async {
        let service = MockNotificationService()
        service.requestPermissionResult = true
        let vm = NotificationSettingsViewModel(notificationService: service)

        let result = await vm.enable(hour: 9, minute: 0)

        #expect(result == true)
        #expect(service.requestPermissionCallCount == 1)
        #expect(service.scheduleDailyCallCount == 1)
        #expect(service.lastScheduledHour == 9)
        #expect(service.lastScheduledMinute == 0)
        #expect(vm.isPermissionDenied == false)
    }

    @Test("enable 权限拒绝时返回 false 并标记")
    func enable_denied_returnsFalse() async {
        let service = MockNotificationService()
        service.requestPermissionResult = false
        let vm = NotificationSettingsViewModel(notificationService: service)

        let result = await vm.enable(hour: 9, minute: 0)

        #expect(result == false)
        #expect(vm.isPermissionDenied == true)
        #expect(service.scheduleDailyCallCount == 0)
    }

    @Test("enable 调度失败时返回 false 并回滚通知状态")
    func enable_scheduleFails_returnsFalseAndCancels() async {
        let service = MockNotificationService()
        service.requestPermissionResult = true
        service.scheduleDailyError = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "调度失败"])
        let vm = NotificationSettingsViewModel(notificationService: service)

        let result = await vm.enable(hour: 9, minute: 0)

        #expect(result == false)
        #expect(service.requestPermissionCallCount == 1)
        #expect(service.scheduleDailyCallCount == 1)
        #expect(service.cancelAllCallCount == 1)
        #expect(vm.rescheduleError != nil)
    }

    @Test("enable 并发重入保护")
    func enable_concurrentGuard() async {
        let service = MockNotificationService()
        let vm = NotificationSettingsViewModel(notificationService: service)
        vm.isRequesting = true

        let result = await vm.enable(hour: 9, minute: 0)

        #expect(result == false)
        #expect(service.requestPermissionCallCount == 0)
    }

    // MARK: - disable

    @Test("disable 取消所有通知")
    func disable_cancelsAll() {
        let service = MockNotificationService()
        let vm = NotificationSettingsViewModel(notificationService: service)

        vm.disable()

        #expect(service.cancelAllCallCount == 1)
    }

    // MARK: - reschedule

    @Test("reschedule 重新安排通知时间")
    func reschedule_updatesSchedule() async {
        let service = MockNotificationService()
        let vm = NotificationSettingsViewModel(notificationService: service)

        let result = await vm.reschedule(hour: 20, minute: 30)

        #expect(result == true)
        #expect(service.scheduleDailyCallCount == 1)
        #expect(service.lastScheduledHour == 20)
        #expect(service.lastScheduledMinute == 30)
        #expect(vm.rescheduleError == nil)
    }

    @Test("reschedule 失败时记录错误信息")
    func reschedule_error_setsErrorMessage() async {
        let service = MockNotificationService()
        service.scheduleDailyError = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "调度失败"])
        let vm = NotificationSettingsViewModel(notificationService: service)

        let result = await vm.reschedule(hour: 20, minute: 30)

        #expect(result == false)
        #expect(vm.rescheduleError != nil)
    }
}
