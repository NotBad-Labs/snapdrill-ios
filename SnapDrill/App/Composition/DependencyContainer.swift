//
//  DependencyContainer.swift
//  SnapDrill
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  依赖注入容器（Composition Root），管理全局服务与仓库实例。
//

import Foundation
import SnapDrillCore
import SnapDrillData
import SnapDrillInfrastructure

/// 应用的依赖注入容器 (Composition Root)
///
/// 集中管理所有全局单例和长生命周期对象，确保应用拓扑结构清晰。
final class DependencyContainer {

    // MARK: - Properties

    static let shared = DependencyContainer()

    /// 全局服务容器 (Firebase, OCR, Analytics 等)
    let services: any ServiceContainer

    /// Profile 管理器（Vault 模式核心）
    let profileManager: ProfileManager

    /// 当前活跃的数据仓库容器（代理到 profileManager）
    var repositories: RepositoryContainer {
        profileManager.activeRepositories
    }

    /// 顶级导航路由器
    let router: AppRouter

    // MARK: - Initialization

    private init() {
        // 1. 配置 Firebase（基础设施层）
        // plist 预设 DEACTIVATED/Disabled，configure 时不生成 persistent ID
        FirebaseBootstrap.configure()

        // 1b. 仅当用户已显式 opt-in 时才激活数据收集
        // plist 预设 DEACTIVATED/Disabled，首启用户未设置时保持禁用状态
        // 只有用户在设置中显式开启过（UserDefaults 有值）才激活
        let defaults = UserDefaults.standard
        if defaults.object(forKey: UDKey.crashReportingEnabled) != nil {
            FirebaseBootstrap.setCrashlyticsEnabled(
                defaults.bool(forKey: UDKey.crashReportingEnabled)
            )
        }
        if defaults.object(forKey: UDKey.analyticsEnabled) != nil {
            FirebaseBootstrap.setAnalyticsEnabled(
                defaults.bool(forKey: UDKey.analyticsEnabled)
            )
        }

        // 2. 初始化 Firebase 具体服务
        let analyticsService = FirebaseAnalyticsService()
        analyticsService.markConfigured()

        // 3. 初始化核心服务容器（注入 Firebase 实现）
        // Remote Config 已移除：八方合规审计一致认定启动即 fetchAndActivate()
        // 违反"用户未 opt-in 时零数据外传"承诺（FID 传输给 Google）
        let liveServices = LiveServiceContainer(
            analytics: analyticsService
        )
        self.services = liveServices

        // 5. 初始化 ProfileManager（内含首次迁移 + ModelContainer 创建）
        let manager = ProfileManager()
        self.profileManager = manager

        // 6. 首次启动时初始化默认分类数据
        manager.activeRepositories.subject.seedDefaultsIfNeeded()
        manager.activeRepositories.source.seedDefaultsIfNeeded()
        manager.activeRepositories.grade.seedDefaultsIfNeeded()

        // 7. 初始化顶级路由器
        self.router = AppRouter()

        // 8. 监听隐私偏好变更，运行时同步到 Firebase SDK
        // 与 step 1b 相同的守卫：仅当用户显式设置过时才激活，
        // 防止首启任意 UserDefaults 变更触发 Analytics 意外激活（COPPA）
        Task { [weak analyticsService] in
            let defaults = UserDefaults.standard
            for await _ in NotificationCenter.default.notifications(named: UserDefaults.didChangeNotification) {
                guard analyticsService != nil else { break }
                if defaults.object(forKey: UDKey.crashReportingEnabled) != nil {
                    FirebaseBootstrap.setCrashlyticsEnabled(
                        AppConfiguration.FeatureFlags.crashReportingEnabled
                    )
                }
                if defaults.object(forKey: UDKey.analyticsEnabled) != nil {
                    FirebaseBootstrap.setAnalyticsEnabled(
                        AppConfiguration.FeatureFlags.analyticsEnabled
                    )
                }
            }
        }

        SnapDrillLogger.generic.info("DependencyContainer: Composition Root initialized successfully.")
    }
}
