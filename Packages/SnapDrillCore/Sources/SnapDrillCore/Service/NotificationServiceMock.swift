//
//  NotificationServiceMock.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/28.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  通知服务 Mock 实现，用于单元测试和 SwiftUI Preview。
//

import Foundation

/// 通知服务 Mock 实现
///
/// 记录所有方法调用，不依赖 `UNUserNotificationCenter`，适用于单元测试和 Preview。
@MainActor
public final class NotificationServiceMock: NotificationServiceProtocol {

    // MARK: - 测试追踪

    /// 模拟的权限请求返回值
    public var simulatedPermissionGranted: Bool = true

    /// 模拟 `scheduleDaily` 时抛出的错误（nil 表示成功）
    public var simulatedError: Error?

    /// `requestPermission()` 被调用的次数
    public private(set) var requestPermissionCallCount = 0

    /// `scheduleDaily(at:minute:)` 被调用时记录的参数
    public private(set) var scheduledHours: [(hour: Int, minute: Int)] = []

    /// `cancelAll()` 被调用的次数
    public private(set) var cancelAllCallCount = 0

    // MARK: - Initialization

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
        scheduledHours.append((hour, minute))
    }

    public func cancelAll() {
        cancelAllCallCount += 1
    }

    // MARK: - 测试辅助

    /// 重置所有追踪状态
    public func reset() {
        requestPermissionCallCount = 0
        scheduledHours.removeAll()
        cancelAllCallCount = 0
        simulatedError = nil
        simulatedPermissionGranted = true
    }
}
