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
/// **Multi-Profile 隔离**：所有 schedule/cancel 操作必须传 `ProfileScope` 作为
/// 编译期隔离通行证；同一通知 ID 包含 profileId 形成 per-profile 命名空间，
/// 切换 Profile 不会跨边界擦除其他 Profile 的 pending notification。
public protocol NotificationServiceProtocol: Sendable {
    /// 请求通知权限
    ///
    /// - Returns: 用户是否授予了通知权限
    func requestPermission() async -> Bool

    /// 安排指定 Profile 的每日复习提醒
    ///
    /// 以每日固定时间重复触发的本地通知替换**同一 Profile** 的现有提醒，
    /// 不影响其他 Profile 的 pending notification。
    /// - Parameters:
    ///   - hour: 触发小时（0-23）
    ///   - minute: 触发分钟（0-59）
    ///   - scope: Profile 隔离作用域
    func scheduleDaily(at hour: Int, minute: Int, for scope: ProfileScope) async throws

    /// 取消指定 Profile 已安排的每日提醒（不影响其他 Profile）
    func cancelDaily(for scope: ProfileScope)

    /// 管理员/重置语义：取消 SnapDrill 管理的所有通知（一键注销 / GDPR 数据抹除场景）
    ///
    /// 通过 managed prefix filter 实现，**不**调用系统级
    /// `removeAllPendingNotificationRequests()`，不触碰第三方 app 的 pending request。
    func cancelAllSnapDrillNotifications() async
}
