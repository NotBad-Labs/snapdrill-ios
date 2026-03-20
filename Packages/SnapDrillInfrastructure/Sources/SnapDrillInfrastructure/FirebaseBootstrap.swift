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

/// Firebase 引导程序
///
/// 用于封装 Firebase 的初始化逻辑，避免主 App Target 直接依赖 Firebase 子模块。
public enum FirebaseBootstrap {
    /// 配置 Firebase 环境
    public static func configure() {
        FirebaseApp.configure()
    }

    /// 设置 Crashlytics 数据收集开关（持久化跨启动）
    ///
    /// 在 `configure()` 之后调用，读取用户隐私偏好。
    /// - Parameter enabled: 是否允许收集崩溃报告
    public static func setCrashlyticsEnabled(_ enabled: Bool) {
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(enabled)
    }

    /// 设置 Analytics 数据收集开关
    ///
    /// - Parameter enabled: 是否允许收集匿名使用数据
    public static func setAnalyticsEnabled(_ enabled: Bool) {
        Analytics.setAnalyticsCollectionEnabled(enabled)
    }
}
