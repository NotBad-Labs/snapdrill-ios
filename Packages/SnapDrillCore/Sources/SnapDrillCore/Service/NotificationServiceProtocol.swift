//
//  NotificationServiceProtocol.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  通知服务协议，封装每日复习提醒的调度与权限请求。
//

import Foundation

/// 通知服务协议
///
/// 抽象 `UNUserNotificationCenter` 的权限请求和每日提醒调度，
/// 使 SettingsViewModel 不直接依赖系统 API。
///
public protocol NotificationServiceProtocol: Sendable {
    /// 请求通知权限
    ///
    /// - Returns: 用户是否授予了通知权限
    func requestPermission() async -> Bool

    /// 安排每日回顾提醒
    ///
    /// 以每日固定时间重复触发的本地通知替换现有提醒。
    /// - Parameters:
    ///   - hour: 触发小时（0-23）
    ///   - minute: 触发分钟（0-59）
    func scheduleDaily(at hour: Int, minute: Int) async throws

    /// 取消已安排的每日提醒
    func cancelDaily()

    /// 管理员/重置语义：取消 SnapDrill 管理的所有通知（一键注销 / GDPR 数据抹除场景）
    ///
    /// 通过 managed prefix filter 实现，**不**调用系统级
    /// `removeAllPendingNotificationRequests()`，不触碰第三方 app 的 pending request。
    func cancelAllSnapDrillNotifications() async
}
