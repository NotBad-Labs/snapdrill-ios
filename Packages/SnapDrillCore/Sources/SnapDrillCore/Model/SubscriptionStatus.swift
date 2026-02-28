//
//  SubscriptionStatus.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  订阅状态枚举，定义用户的付费等级
//

import Foundation

// MARK: - 订阅状态

/// 用户订阅状态
///
/// 表示用户当前的订阅等级，用于控制功能权限门控。
/// Represents the user's current subscription tier for feature gating.
public enum SubscriptionStatus: String, Sendable, Codable {
    /// 免费用户
    case free
    /// 高级会员（活跃订阅中）
    case premium
    /// 订阅已过期
    case expired
    /// 正在加载状态
    case loading
}

// MARK: - 功能权限

/// 订阅功能枚举
///
/// 定义需要高级订阅才能使用的功能列表。
/// Defines which features require a premium subscription.
public enum PremiumFeature: String, Sendable, CaseIterable {
    /// 无限制练习次数
    case unlimitedDrills
    /// PDF 导出
    case pdfExport
    /// 高级数据统计
    case advancedStats
    /// 自定义主题
    case customThemes
}

// MARK: - 权限检查扩展

extension SubscriptionStatus {
    /// 检查当前订阅状态是否有权访问指定功能
    ///
    /// Check if the current subscription status grants access to a specific feature.
    /// - Parameter feature: 需要检查权限的功能
    /// - Returns: 是否有权访问
    public func hasAccess(to feature: PremiumFeature) -> Bool {
        switch self {
        case .premium:
            return true
        case .free, .expired, .loading:
            return false
        }
    }

    /// 当前状态是否为活跃付费用户
    ///
    /// Whether the user currently has an active paid subscription.
    public var isPremium: Bool {
        self == .premium
    }
}
