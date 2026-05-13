//
//  PrivacyConsentService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  隐私授权服务。ATT 已移除（ADR-002），遥测授权委托给 TelemetryGate。
//

import Foundation

// MARK: - 隐私授权服务

/// 隐私授权服务
///
/// ATT 授权逻辑已根据 ADR-002 移除（NSPrivacyTracking=false 下弹 ATT 违反 Rule 5.1.2）。
/// Analytics/Crashlytics 的 opt-in 统一由 `TelemetryGate` 管理。
public final class PrivacyConsentService {

    // MARK: - Properties

    /// 共享实例
    public static let shared = PrivacyConsentService()

    // MARK: - Initialization

    /// 创建隐私授权服务实例
    public init() {}

    public var telemetryState: TelemetryGate.State {
        get { TelemetryGate.state }
        set { TelemetryGate.state = newValue }
    }

    public var telemetryConsent: TelemetryGate.State {
        get { telemetryState }
        set { telemetryState = newValue }
    }

    public var isTelemetryEnabled: Bool {
        get { TelemetryGate.isGranted }
        set { TelemetryGate.setGranted(newValue) }
    }
}
