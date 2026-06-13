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

/// 应用的依赖注入容器 (Composition Root)
///
/// 集中管理所有全局单例和长生命周期对象，确保应用拓扑结构清晰。
final class DependencyContainer {

    // MARK: - Properties

    /// UI 测试模式标志（通过 --uitesting launch argument 激活）
    static let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")

    static let shared = DependencyContainer()

    /// 全局服务容器 (OCR, Analytics 等)
    let services: any ServiceContainer

    /// 顶级导航路由器
    let router: AppRouter

    // MARK: - Initialization

    private init() {
        // UI 测试模式：使用 mock services 与 in-memory 存储。
        if Self.isUITesting {
            self.services = MockServiceContainer()
            self.router = AppRouter()
            // 引导页通过 launch argument -hasCompletedOnboarding YES 跳过（进程级，不持久化）
            SnapDrillLogger.generic.info("DependencyContainer: UI 测试模式初始化完成")
            return
        }

        // 1. 分析服务：全球生产基线为零后端行为采集。
        //    Firebase SDK 已删除；生产注入无网络副作用的 NoOpAnalyticsService。
        let analyticsService = NoOpAnalyticsService()

        // 2. 初始化核心服务容器（注入分析实现）
        // Remote Config 已随 Firebase 基础设施删除。
        let liveServices = LiveServiceContainer(
            analytics: analyticsService
        )
        self.services = liveServices

        // 3. 初始化顶级路由器
        self.router = AppRouter()

        SnapDrillLogger.generic.info("DependencyContainer: Composition Root initialized successfully.")
    }

    @MainActor
    func createProfileManager() async -> ProfileManager {
        let manager = await ProfileManager.create(inMemory: Self.isUITesting)
        // L3：种入内置维度（学科/来源/年级/标签），替代旧 3 个分类 seed（S6 删旧）
        manager.activeRepositories.dimension.seedDefaultsIfNeeded()
        return manager
    }
}
