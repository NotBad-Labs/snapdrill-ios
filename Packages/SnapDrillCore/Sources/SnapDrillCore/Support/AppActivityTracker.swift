//
//  AppActivityTracker.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/04/09.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  中心状态机，追踪全局进行中的操作。
//  Profile 切换前检查此状态，避免数据丢失。
//

import Foundation

/// 应用级活动类型
public enum AppActivity: Sendable, Hashable {
    /// 采集流程进行中（含 OCR）
    case capturing
    /// 导出进行中（PDF/CSV/ZIP 等）
    case exporting
    /// 打印进行中
    case printing
    /// 备份/恢复进行中
    case backupRestore
}

/// 中心活动追踪器（全局单例，与 App 生命周期等长）
///
/// 各 ViewModel 在开始/结束操作时调用 `begin/end`，
/// `ProfileManager` 切换前通过 `canSwitchProfile` 检查。
@Observable public final class AppActivityTracker {

    public static let shared = AppActivityTracker()

    /// 当前进行中的活动集合
    public private(set) var activeActivities: Set<AppActivity> = []

    /// 是否可以安全切换 Profile
    public var canSwitchProfile: Bool {
        activeActivities.isEmpty
    }

    // 阻塞切换的原因描述（用于 UI 提示）
    public var switchBlockReason: String? {
        guard !canSwitchProfile else { return nil }
        let descriptions = activeActivities.map { activity -> String in
            switch activity {
            case .capturing: return L10n.Activity.capturing
            case .exporting: return L10n.Activity.exporting
            case .printing: return L10n.Activity.printing
            case .backupRestore: return L10n.Activity.backupRestore
            }
        }
        return descriptions.joined(separator: ", ")
    }

    public init() {}

    /// 标记活动开始
    public func begin(_ activity: AppActivity) {
        activeActivities.insert(activity)
    }

    /// 标记活动结束
    public func end(_ activity: AppActivity) {
        activeActivities.remove(activity)
    }
}
