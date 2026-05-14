//
//  DependencyContainer.swift
//  SnapDrill
//
//  Created by NotBad Labs.
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

    /// UI 测试模式标志（通过 --uitesting launch argument 激活）
    static let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")

    static let shared = DependencyContainer()

    /// 全局服务容器 (Firebase, OCR, Analytics 等)
    let services: any ServiceContainer

    /// 顶级导航路由器
    let router: AppRouter

    // MARK: - Initialization

    private init() {
        // UI 测试模式：跳过 Firebase，使用 in-memory 存储
        if Self.isUITesting {
            self.services = MockServiceContainer()
            self.router = AppRouter()
            // 引导页通过 launch argument -hasCompletedOnboarding YES 跳过（进程级，不持久化）
            SnapDrillLogger.generic.info("DependencyContainer: UI 测试模式初始化完成")
            return
        }

        // 1. 配置 Firebase（基础设施层）
        // plist 预设 DEACTIVATED/Disabled，configure 时不生成 persistent ID
        FirebaseBootstrap.configure()

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

        // 5. 初始化顶级路由器
        self.router = AppRouter()

        // 6. 监听遥测授权变更，运行时同步到 Firebase SDK
        Task { [weak analyticsService] in
            for await _ in NotificationCenter.default.notifications(named: TelemetryGate.didChangeNotification) {
                guard analyticsService != nil else { break }
                FirebaseBootstrap.syncTelemetryGate()
            }
        }

        SnapDrillLogger.generic.info("DependencyContainer: Composition Root initialized successfully.")
    }

    @MainActor
    func createProfileManager() async -> ProfileManager {
        let manager = await ProfileManager.create(inMemory: Self.isUITesting)
        manager.activeRepositories.subject.seedDefaultsIfNeeded()
        manager.activeRepositories.source.seedDefaultsIfNeeded()
        manager.activeRepositories.grade.seedDefaultsIfNeeded()
        return manager
    }
}
