//
//  LiveNotificationService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  封装 UNUserNotificationCenter 的通知服务生产实现。
//

import Foundation
import UserNotifications

/// 通知服务生产实现
///
/// 封装 `UNUserNotificationCenter`，提供权限请求和每日复习提醒调度。
public final class LiveNotificationService: NotificationServiceProtocol {

    // MARK: - Initialization

    /// 创建通知服务生产实例
    public init() {}

    // MARK: - NotificationServiceProtocol

    /// 请求通知权限（.alert + .sound，不请求 .badge — product-requirements:178 不使用角标）
    public func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            SnapDrillLogger.generic.error("通知权限请求失败: \(error.localizedDescription)")
            return false
        }
    }

    /// 安排每日固定时间的复习提醒
    ///
    /// 先取消所有现有提醒，再注册新的每日重复通知。
    public func scheduleDaily(at hour: Int, minute: Int) async throws {
        cancelAll()

        let content = UNMutableNotificationContent()
        content.title = L10n.Notification.dailyTitle
        content.body = L10n.Notification.dailyBody
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "com.snapdrill.daily-review",
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)
        SnapDrillLogger.generic.info("已安排每日复习提醒：\(hour):\(String(format: "%02d", minute))")
    }

    /// 取消所有已安排的本地通知
    public func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        SnapDrillLogger.generic.info("已取消所有待发送通知")
    }
}
