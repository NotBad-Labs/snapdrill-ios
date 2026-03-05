//
//  NotificationServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs on 2026/02/28.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  通知服务 Mock 的单元测试，验证调用追踪与错误模拟。
//

import Testing
import Foundation
@testable import SnapDrillCore

@MainActor
@Suite("NotificationServiceMock 测试")
struct NotificationServiceTests {

    // MARK: - requestPermission

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

    // MARK: - scheduleDaily

    @Test("scheduleDaily 正常调用记录参数")
    func scheduleDailyRecordsParameters() async throws {
        let mock = NotificationServiceMock()
        try await mock.scheduleDaily(at: 8, minute: 30)
        #expect(mock.scheduledHours.count == 1)
        #expect(mock.scheduledHours[0].hour == 8)
        #expect(mock.scheduledHours[0].minute == 30)
    }

    @Test("scheduleDaily 多次调用累积记录")
    func scheduleDailyMultipleTimes() async throws {
        let mock = NotificationServiceMock()
        try await mock.scheduleDaily(at: 8, minute: 0)
        try await mock.scheduleDaily(at: 20, minute: 30)
        #expect(mock.scheduledHours.count == 2)
    }

    @Test("scheduleDaily 模拟错误时应抛出")
    func scheduleDailyThrowsWhenSimulated() async throws {
        let mock = NotificationServiceMock()
        mock.simulatedError = NSError(domain: "test", code: 1)
        // `(any Error).self` 是 Swift Testing #expect(throws:) 捕获任意错误的标准语法，
        // 不等同于声明 any 存在类型变量，不违反 any existentials 禁令。
        await #expect(throws: (any Error).self) {
            try await mock.scheduleDaily(at: 8, minute: 0)
        }
        #expect(mock.scheduledHours.isEmpty)
    }

    // MARK: - cancelAll

    @Test("cancelAll 递增调用计数")
    func cancelAllIncrementsCount() {
        let mock = NotificationServiceMock()
        mock.cancelAll()
        mock.cancelAll()
        #expect(mock.cancelAllCallCount == 2)
    }

    // MARK: - reset

    @Test("reset 清空所有追踪状态")
    func resetClearsAllState() async throws {
        let mock = NotificationServiceMock()
        _ = await mock.requestPermission()
        try await mock.scheduleDaily(at: 9, minute: 0)
        mock.cancelAll()

        mock.reset()

        #expect(mock.requestPermissionCallCount == 0)
        #expect(mock.scheduledHours.isEmpty)
        #expect(mock.cancelAllCallCount == 0)
        #expect(mock.simulatedPermissionGranted == true)
        #expect(mock.simulatedError == nil)
    }
}
