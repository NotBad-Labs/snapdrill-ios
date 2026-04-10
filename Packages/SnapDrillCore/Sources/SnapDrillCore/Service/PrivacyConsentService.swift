//
//  PrivacyConsentService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  隐私授权服务。ATT 已移除（ADR-002），保留空壳供 DI 容器兼容。
//

import Foundation

// MARK: - 隐私授权服务

/// 隐私授权服务
///
/// ATT 授权逻辑已根据 ADR-002 移除（NSPrivacyTracking=false 下弹 ATT 违反 Rule 5.1.2）。
/// Analytics/Crashlytics 的 opt-in 由设置页独立开关管理，不经过本服务。
/// 保留此类供 ServiceContainer DI 兼容，未来可承载非 ATT 的隐私相关功能。
public final class PrivacyConsentService {

    // MARK: - Properties

    /// 共享实例
    public static let shared = PrivacyConsentService()

    // MARK: - Initialization

    /// 创建隐私授权服务实例
    public init() {}
}
