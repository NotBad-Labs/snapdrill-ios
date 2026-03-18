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

        // 1b. 读取用户偏好设置 Crashlytics 收集开关
        FirebaseBootstrap.setCrashlyticsEnabled(
            AppConfiguration.FeatureFlags.crashReportingEnabled
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

        SnapDrillLogger.generic.info("DependencyContainer: Composition Root initialized successfully.")
    }
}
