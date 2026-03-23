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
@MainActor
final class DependencyContainer {
    
    // MARK: - Properties
    
    static let shared = DependencyContainer()
    
    /// 全局服务容器 (Firebase, OCR, Analytics 等)
    let services: any ServiceContainer
    
    /// 全局数据仓库容器 (SwiftData Repositories)
    let repositories: RepositoryContainer

    /// 顶级导航路由器
    let router: AppRouter
    
    // MARK: - Initialization
    
    private init() {
        // 1. 配置 Firebase（基础设施层）
        FirebaseBootstrap.configure()

        // 1b. 读取用户隐私偏好，同步到 Firebase SDK
        FirebaseBootstrap.setCrashlyticsEnabled(
            AppConfiguration.FeatureFlags.crashReportingEnabled
        )
        FirebaseBootstrap.setAnalyticsEnabled(
            AppConfiguration.FeatureFlags.analyticsEnabled
        )

        // 2. 初始化 Firebase 具体服务
        let analyticsService = FirebaseAnalyticsService()
        analyticsService.markConfigured()

        // 3. 注册远程配置服务
        let remoteConfig = FirebaseRemoteConfigService()
        AppConfiguration.FeatureFlags.registerRemoteProvider(remoteConfig)
        Task {
            try? await remoteConfig.fetchAndActivate()
        }

        // 4. 初始化核心服务容器（注入 Firebase 实现）
        let liveServices = LiveServiceContainer(
            analytics: analyticsService
        )
        self.services = liveServices
        
        // 5. 初始化持久化仓库层
        let repos = RepositoryContainer()
        self.repositories = repos

        // 6. 首次启动时初始化默认分类数据
        repos.subject.seedDefaultsIfNeeded()
        repos.source.seedDefaultsIfNeeded()
        repos.grade.seedDefaultsIfNeeded()

        // 7. 初始化顶级路由器
        self.router = AppRouter()

        // 8. 监听隐私偏好变更，运行时同步到 Firebase SDK
        // 使用 async for await 替代 addObserver 回调（conventions.md 并发规则）
        Task { [weak analyticsService] in
            for await _ in NotificationCenter.default.notifications(named: UserDefaults.didChangeNotification) {
                guard analyticsService != nil else { break }
                FirebaseBootstrap.setCrashlyticsEnabled(
                    AppConfiguration.FeatureFlags.crashReportingEnabled
                )
                FirebaseBootstrap.setAnalyticsEnabled(
                    AppConfiguration.FeatureFlags.analyticsEnabled
                )
            }
        }

        SnapDrillLogger.generic.info("DependencyContainer: Composition Root initialized successfully.")
    }
}
