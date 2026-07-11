//
//  NotificationServiceMock.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  通知服务 Mock 实现，用于单元测试和 SwiftUI Preview。
//

import Foundation

/// 通知服务 Mock 实现
///
/// 记录所有方法调用，不依赖 `UNUserNotificationCenter`，适用于单元测试和 Preview。
public final class NotificationServiceMock: NotificationServiceProtocol {

    // MARK: - 测试追踪

    /// 模拟的权限请求返回值
    public var simulatedPermissionGranted: Bool = true

    /// 模拟 `scheduleDaily` 时抛出的错误（nil 表示成功）
    public var simulatedError: Error?

    /// `requestPermission()` 被调用的次数
    public private(set) var requestPermissionCallCount = 0

    /// 最近一次 schedule 调用参数
    public private(set) var scheduledTime: (hour: Int, minute: Int)?

    /// `cancelDaily()` 被调用的次数
    public private(set) var cancelDailyCallCount = 0

    /// `cancelAllSnapDrillNotifications()` 被调用的次数
    public private(set) var cancelAllSnapDrillCallCount = 0

    // MARK: - Initialization

    /// 创建通知服务 Mock 实例，默认模拟授权成功
    public init() {}

    // MARK: - NotificationServiceProtocol

    public func requestPermission() async -> Bool {
        requestPermissionCallCount += 1
        return simulatedPermissionGranted
    }

    public func scheduleDaily(at hour: Int, minute: Int) async throws {
        if let error = simulatedError {
            throw error
        }
        scheduledTime = (hour, minute)
    }

    public func cancelDaily() {
        cancelDailyCallCount += 1
        scheduledTime = nil
    }

    public func cancelAllSnapDrillNotifications() async {
        cancelAllSnapDrillCallCount += 1
        scheduledTime = nil
    }

    // MARK: - 测试辅助

    /// 重置所有追踪状态
    public func reset() {
        requestPermissionCallCount = 0
        scheduledTime = nil
        cancelDailyCallCount = 0
        cancelAllSnapDrillCallCount = 0
        simulatedError = nil
        simulatedPermissionGranted = true
    }
}
