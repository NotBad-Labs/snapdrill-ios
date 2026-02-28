//
//  NotificationServiceProtocol.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/28.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  通知服务协议，封装每日复习提醒的调度与权限请求。
//

import Foundation

/// 通知服务协议
///
/// 抽象 `UNUserNotificationCenter` 的权限请求和每日提醒调度，
/// 使 SettingsViewModel 不直接依赖系统 API。
@MainActor
public protocol NotificationServiceProtocol: Sendable {
    /// 请求通知权限
    ///
    /// - Returns: 用户是否授予了通知权限
    func requestPermission() async -> Bool

    /// 安排每日复习提醒
    ///
    /// 以每日固定时间重复触发的本地通知替换所有现有提醒。
    /// - Parameters:
    ///   - hour: 触发小时（0-23）
    ///   - minute: 触发分钟（0-59）
    func scheduleDaily(at hour: Int, minute: Int) async throws

    /// 取消所有已安排的通知
    func cancelAll()
}
