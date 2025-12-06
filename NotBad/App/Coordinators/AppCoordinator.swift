//
//  AppCoordinator.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import Foundation
import SwiftUI
import SwiftData
import Observation
import OSLog

// MARK: - AppCoordinator

/// 应用级协调器
///
/// 作为协调器层次结构的根节点，负责：
/// - 持有和管理所有子协调器
/// - 协调应用启动流程
/// - 处理全局事件（Deep Link、Spotlight、Widget 同步等）
///
/// ## 协调器层次结构
///
/// ```
/// AppCoordinator (应用协调器)
///     ├── RootCoordinator (根协调器 - 启动/错误/维护)
///     ├── MainFlowCoordinator (主流程 - Onboarding/权限)
///     │   └── TabCoordinator (Tab 导航)
///     │       ├── DashboardFeatureCoordinator
///     │       ├── LibraryFeatureCoordinator
///     │       ├── CaptureFeatureCoordinator
///     │       ├── ReviewFeatureCoordinator
///     │       └── ProfileFeatureCoordinator
///     ├── WidgetSyncCoordinator (Widget 同步)
///     ├── DeepLinkCoordinator (Deep Link 路由)
///     └── SpotlightCoordinator (Spotlight 导航)
/// ```
@MainActor
@Observable
final class AppCoordinator {
    
    // MARK: - Core Coordinators
    
    /// 根协调器
    let root: RootCoordinator
    
    /// 主流程协调器
    let mainFlow: MainFlowCoordinator
    
    /// Tab 协调器
    let tab: TabCoordinator
    
    // MARK: - Service Coordinators
    
    /// Widget 同步协调器
    let widgetSync: WidgetSyncCoordinator
    
    /// Deep Link 协调器
    let deepLink: DeepLinkCoordinator
    
    /// Spotlight 协调器
    let spotlight: SpotlightCoordinator
    
    // MARK: - Legacy Support
    
    /// Onboarding 协调器（兼容旧代码）
    var onboarding: OnboardingCoordinator {
        mainFlow.onboardingCoordinator
    }
    
    // MARK: - Dependencies
    
    /// 模型容器
    private let modelContainer: ModelContainer
    
    // MARK: - Initialization
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        
        // 创建 Tab 协调器
        let tabCoordinator = TabCoordinator()
        self.tab = tabCoordinator
        
        // 创建 Onboarding 协调器
        let onboardingCoordinator = OnboardingCoordinator()
        
        // 创建主流程协调器
        self.mainFlow = MainFlowCoordinator(
            tabCoordinator: tabCoordinator,
            onboardingCoordinator: onboardingCoordinator
        )
        
        // 创建根协调器
        self.root = RootCoordinator()
        
        // 创建服务协调器
        self.widgetSync = WidgetSyncCoordinator(modelContainer: modelContainer)
        self.deepLink = DeepLinkCoordinator(tabCoordinator: tabCoordinator)
        self.spotlight = SpotlightCoordinator(tabCoordinator: tabCoordinator)
        
        Logger.app.debug("✅ AppCoordinator 初始化完成")
    }
    
    // MARK: - Lifecycle
    
    /// 应用启动时调用
    func onAppear() {
        mainFlow.checkInitialState()
    }
    
    /// 处理 URL 打开事件
    func handleOpenURL(_ url: URL) {
        deepLink.handle(url)
    }
    
    /// 处理 User Activity（Handoff / Spotlight）
    func handleUserActivity(_ activity: NSUserActivity) {
        spotlight.handle(activity)
    }
    
    /// 处理 Handoff Tab 导航
    func handleHandoffTab(_ tab: Tab) {
        self.tab.selectTab(tab)
    }
    
    /// 启动 Widget 数据同步
    func startWidgetSync() async {
        await widgetSync.sync()
    }
    
    /// 调度 Widget 同步（防抖）
    func scheduleWidgetSync() {
        widgetSync.scheduleSync()
    }
}

// MARK: - Environment Key

private struct AppCoordinatorKey: EnvironmentKey {
    static let defaultValue: AppCoordinator? = nil
}

extension EnvironmentValues {
    var appCoordinator: AppCoordinator? {
        get { self[AppCoordinatorKey.self] }
        set { self[AppCoordinatorKey.self] = newValue }
    }
}
