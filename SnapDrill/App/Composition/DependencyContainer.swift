//
//  DependencyContainer.swift
//  SnapDrill
//
//  Created by SnapDrill Labs on 2025/12/29.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  依赖注入容器，管理全局服务实例。
//

import Foundation
import SnapDrillCore
import SnapDrillData
import SnapDrillFeatures
import SnapDrillDomain

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
    let repositories: any RepositoryContainer

    /// 业务用例容器（Clean Architecture UseCase 层）
    let useCaseContainer: any UseCaseContainer

    /// 顶级导航路由器
    let router: AppRouter
    
    // MARK: - Initialization
    
    private init() {
        // 1. 配置 Firebase (基础设施)
        FirebaseBootstrap.configure()
        
        // 2. 初始化核心服务层
        let liveServices = LiveServiceContainer()
        
        // 执行服务特定初始化
        if let analytics = liveServices.analytics as? FirebaseAnalyticsService {
            analytics.markConfigured()
        }
        if let crash = liveServices.crashReporting as? CrashReportingService {
            crash.markConfigured()
        }
        
        // 注册远程配置服务
        let remoteConfig = FirebaseRemoteConfigService()
        AppConfiguration.FeatureFlags.registerRemoteProvider(remoteConfig)
        Task {
            try? await remoteConfig.fetchAndActivate()
        }
        
        self.services = liveServices
        
        // 3. 初始化持久化仓库层
        let repos = DefaultRepositoryContainer()
        self.repositories = repos

        // 3.5 初始化 UseCase 层（Clean Architecture）
        self.useCaseContainer = DefaultUseCaseContainer(repositories: repos)

        // 4. 首次启动时初始化默认学科数据
        repos.subject.seedDefaultsIfNeeded()

        // 5. 初始化顶级路由器
        self.router = AppRouter()

        SnapDrillLogger.generic.info("DependencyContainer: Composition Root initialized successfully.")
    }
}
