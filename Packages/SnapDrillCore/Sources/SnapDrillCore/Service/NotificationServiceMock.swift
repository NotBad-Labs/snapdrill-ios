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

    /// 按 Profile 追踪 schedule 调用参数（每个 profile 仅保留最近一次，符合 Live 服务覆盖语义）
    public private(set) var schedulesByProfile: [UUID: (hour: Int, minute: Int)] = [:]

    /// 按时序记录 cancelDaily 被调用的 profile（追加，便于断言顺序）
    public private(set) var cancelledProfileIds: [UUID] = []

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

    public func scheduleDaily(at hour: Int, minute: Int, for scope: ProfileScope) async throws {
        if let error = simulatedError {
            throw error
        }
        schedulesByProfile[scope.id] = (hour, minute)
    }

    public func cancelDaily(for scope: ProfileScope) {
        cancelledProfileIds.append(scope.id)
        schedulesByProfile[scope.id] = nil
    }

    public func cancelAllSnapDrillNotifications() async {
        cancelAllSnapDrillCallCount += 1
        schedulesByProfile.removeAll()
    }

    // MARK: - 测试辅助

    /// 重置所有追踪状态
    public func reset() {
        requestPermissionCallCount = 0
        schedulesByProfile.removeAll()
        cancelledProfileIds.removeAll()
        cancelAllSnapDrillCallCount = 0
        simulatedError = nil
        simulatedPermissionGranted = true
    }
}
