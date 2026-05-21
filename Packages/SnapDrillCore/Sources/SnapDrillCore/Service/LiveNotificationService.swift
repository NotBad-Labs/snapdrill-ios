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

/// 通知中心抽象，用于在单元测试中注入 FakeCenter 而无需依赖系统 sandbox
public protocol UserNotificationScheduling: Sendable {
    func add(_ request: UNNotificationRequest) async throws
    func pendingNotificationRequests() async -> [UNNotificationRequest]
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: UserNotificationScheduling {}

/// SnapDrill 管理的通知 ID 命名空间
///
/// 命名层级：`com.snapdrill.notification.<type>.profile.<lowercase-uuid>`
/// - 第一级 `com.snapdrill` reverse-DNS app 域
/// - 第二级 `notification` 通知功能域（区分于其他子系统）
/// - 第三级 `<type>` 通知类型（daily-review / 未来错题提醒等）
/// - 第四级 `profile.<uuid>` Profile 隔离作用域
///
/// legacy `"com.snapdrill.daily-review"` 是修复前的硬编码 ID，
/// schedule 时级联清理以实现平滑升级。
public enum SnapDrillNotificationID {
    public static let legacyDailyReview = "com.snapdrill.daily-review"
    public static let managedPrefix = "com.snapdrill.notification."
    private static let dailyReviewPrefix = managedPrefix + "daily-review.profile."

    public static func dailyReview(for profileId: UUID) -> String {
        dailyReviewPrefix + profileId.uuidString.lowercased()
    }

    /// 判断 identifier 是否属于 SnapDrill 管理的通知（含 legacy ID）
    public static func isManaged(_ identifier: String) -> Bool {
        identifier == legacyDailyReview || identifier.hasPrefix(managedPrefix)
    }
}

/// 通知服务生产实现
///
/// 封装 `UNUserNotificationCenter`，提供权限请求和每日复习提醒调度。
public final class LiveNotificationService: NotificationServiceProtocol {

    private let notificationCenter: any UserNotificationScheduling

    // MARK: - Initialization

    /// 创建通知服务生产实例
    /// - Parameter notificationCenter: 默认使用 `UNUserNotificationCenter.current()`；测试可注入 FakeCenter
    public init(notificationCenter: any UserNotificationScheduling = UNUserNotificationCenter.current()) {
        self.notificationCenter = notificationCenter
    }

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

    /// 安排指定 Profile 的每日固定时间复习提醒
    ///
    /// 只替换同一 Profile 的每日提醒，**不影响其他 Profile**。
    /// 同时级联清理 legacy ID `"com.snapdrill.daily-review"`（平滑升级，无需 boot 阻塞）。
    public func scheduleDaily(at hour: Int, minute: Int, for scope: ProfileScope) async throws {
        let identifier = SnapDrillNotificationID.dailyReview(for: scope.id)
        // 级联清理当前 profile 旧 schedule + legacy 全局 ID（修复前的硬编码 ID）
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [identifier, SnapDrillNotificationID.legacyDailyReview]
        )

        let content = UNMutableNotificationContent()
        content.title = L10n.Notification.dailyTitle
        content.body = L10n.Notification.dailyBody
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        SnapDrillLogger.generic.info(
            "已安排每日复习提醒 profile=\(scope.id.uuidString) time=\(hour):\(String(format: "%02d", minute))"
        )
    }

    /// 取消指定 Profile 的每日提醒
    public func cancelDaily(for scope: ProfileScope) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [SnapDrillNotificationID.dailyReview(for: scope.id)]
        )
        SnapDrillLogger.generic.info("已取消每日复习提醒 profile=\(scope.id.uuidString)")
    }

    /// 管理员/重置语义：仅取消 SnapDrill 管理的通知，不触碰第三方 app pending request
    public func cancelAllSnapDrillNotifications() async {
        let identifiers = await notificationCenter.pendingNotificationRequests()
            .map(\.identifier)
            .filter(SnapDrillNotificationID.isManaged)
        guard !identifiers.isEmpty else { return }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        SnapDrillLogger.generic.info("已取消 SnapDrill 管理的通知 count=\(identifiers.count)")
    }
}
