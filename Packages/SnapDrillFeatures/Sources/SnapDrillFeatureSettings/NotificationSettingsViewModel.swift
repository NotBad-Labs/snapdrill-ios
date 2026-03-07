//
//  NotificationSettingsViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/03/01.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  通知设置 ViewModel，封装权限请求与每日提醒调度，不直接暴露 UNUserNotificationCenter。
//

import Foundation
import Observation
import SnapDrillCore

/// 通知设置 ViewModel
@Observable
@MainActor
final class NotificationSettingsViewModel {

    // MARK: - Properties

    /// 用户拒绝权限时置 true，用于展示引导 Alert
    var isPermissionDenied: Bool = false
    /// enable() 执行期间为 true，防止并发重入（View 层据此禁用 Toggle）
    var isRequesting: Bool = false
    /// reschedule() 失败时赋值，View 层据此展示错误 Alert
    var rescheduleError: String?

    // MARK: - Dependencies

    private let notificationService: NotificationServiceProtocol

    // MARK: - Initialization

    init(notificationService: NotificationServiceProtocol) {
        self.notificationService = notificationService
    }

    // MARK: - Public API

    /// 用户开启通知开关时调用：请求权限，成功后安排每日提醒
    ///
    /// - Returns: 权限是否已授予（用于回写 @AppStorage）
    func enable(hour: Int, minute: Int) async -> Bool {
        guard !isRequesting else { return false }
        isRequesting = true
        defer { isRequesting = false }

        let granted = await notificationService.requestPermission()
        guard granted else {
            isPermissionDenied = true
            return false
        }
        do {
            try await notificationService.scheduleDaily(at: hour, minute: minute)
        } catch {
            SnapDrillLogger.generic.error("安排每日通知失败: \(error.localizedDescription)")
        }
        return true
    }

    /// 用户关闭通知开关时调用：取消所有已安排的通知
    func disable() {
        notificationService.cancelAll()
    }

    /// 用户修改提醒时间时调用：重新安排（仅在已开启状态下生效）
    func reschedule(hour: Int, minute: Int) async {
        do {
            try await notificationService.scheduleDaily(at: hour, minute: minute)
        } catch {
            SnapDrillLogger.generic.error("更新通知时间失败: \(error.localizedDescription)")
            rescheduleError = error.localizedDescription
        }
    }
}
