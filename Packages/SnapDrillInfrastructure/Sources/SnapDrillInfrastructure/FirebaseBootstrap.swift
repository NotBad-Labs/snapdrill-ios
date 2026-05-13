//
//  FirebaseBootstrap.swift
//  SnapDrillInfrastructure
//
//  Created by NotBad Labs on 2026/02/26.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Firebase 初始化引导，封装 FirebaseApp.configure 及数据收集开关。
//

import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics
import os
import SnapDrillCore

/// Firebase 引导程序
///
/// 用于封装 Firebase 的初始化逻辑，避免主 App Target 直接依赖 Firebase 子模块。
public enum FirebaseBootstrap {
    /// Firebase 是否已完成初始化（幂等保护）
    private static let isConfigured = OSAllocatedUnfairLock(initialState: false)

    /// 配置 Firebase 环境（幂等，重复调用安全）
    ///
    /// plist 中预设 `FIREBASE_ANALYTICS_COLLECTION_DEACTIVATED = YES`
    /// 和 `FirebaseCrashlyticsCollectionEnabled = NO`，确保 configure 时
    /// 不生成 `app_instance_id`、不上报数据。初始化后立即按 `TelemetryGate`
    /// 同步 Analytics 和 Crashlytics 的统一授权状态。
    public static func configure() {
        isConfigured.withLock { isConfigured in
            guard !isConfigured else { return }
            FirebaseApp.configure()
            isConfigured = true
        }
        syncTelemetryGate()
    }

    /// 将 Firebase SDK 数据收集状态同步为当前遥测授权状态。
    public static func syncTelemetryGate() {
        guard isConfigured.withLock({ $0 }) else { return }
        let enabled = TelemetryGate.isGranted
        setCrashlyticsEnabled(enabled)
        setAnalyticsEnabled(enabled)
    }

    private static func setCrashlyticsEnabled(_ enabled: Bool) {
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(enabled)
    }

    private static func setAnalyticsEnabled(_ enabled: Bool) {
        Analytics.setAnalyticsCollectionEnabled(enabled)
    }
}
