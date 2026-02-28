//
//  PrivacyConsentService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ATT (App Tracking Transparency) 隐私授权服务
//

import AppTrackingTransparency
import Foundation
import OSLog

// MARK: - 隐私授权服务

/// ATT 隐私授权服务
///
/// 封装 App Tracking Transparency 框架的授权流程。
/// 遵循 Apple 最佳实践：在 App 启动后延迟弹窗，避免用户首次打开即被打断。
/// Wraps ATT authorization with Apple-recommended delayed prompt behavior.
@MainActor
public final class PrivacyConsentService {

    // MARK: - Properties

    /// 共享实例 - 建议使用 ServiceContainer 注入
    public static let shared = PrivacyConsentService()

    private let logger = Logger(subsystem: "com.snapdrill.app", category: "Privacy")

    /// 用户是否已经做出过追踪授权决策
    private static let hasRequestedTrackingKey = "privacyConsentRequested"

    // MARK: - Initialization

    public init() {}

    // MARK: - Public API

    /// 当前追踪授权状态
    ///
    /// Current ATT authorization status.
    public var trackingStatus: ATTrackingManager.AuthorizationStatus {
        ATTrackingManager.trackingAuthorizationStatus
    }

    /// 是否已获得追踪授权
    ///
    /// Whether the user has granted tracking authorization.
    public var isTrackingAuthorized: Bool {
        trackingStatus == .authorized
    }

    /// 请求追踪授权
    ///
    /// 直接请求系统彈窗，建议在预热界面点击“继续”后调用。
    /// Directly requests system prompt.
    public func requestTrackingAuthorization() async -> ATTrackingManager.AuthorizationStatus {
        let status = await ATTrackingManager.requestTrackingAuthorization()
        
        UserDefaults.standard.set(true, forKey: PrivacyConsentService.hasRequestedTrackingKey)
        
        switch status {
        case .authorized:
            logger.info("✅ 用户授权追踪")
        case .denied:
            logger.info("❌ 用户拒绝追踪")
        case .restricted:
            logger.info("⚠️ 追踪受限（可能是家长控制）")
        case .notDetermined:
            logger.info("❓ ATT 状态仍未确定")
        @unknown default:
            logger.warning("未知 ATT 状态: \(status.rawValue)")
        }
        
        return status
    }

    /// 是否需要显示自定义预弹窗说明
    ///
    /// 某些 App 会在系统弹窗之前先展示一个自定义的说明页，
    /// 解释为什么需要追踪授权，以提高用户同意率。
    /// Whether to show a custom pre-prompt explaining why tracking is needed.
    public var shouldShowPrePrompt: Bool {
        trackingStatus == .notDetermined &&
        !UserDefaults.standard.bool(forKey: PrivacyConsentService.hasRequestedTrackingKey)
    }
}
