//
//  SnapDrillApp.swift
//  SnapDrill
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  应用入口文件，负责初始化应用和主界面配置
//

import SwiftUI
import SnapDrillData
import SnapDrillCore
import SnapDrillUI
import SnapDrillFeatureCapture
import SnapDrillFeatureLibrary
import SnapDrillFeatureDashboard
import SnapDrillFeatureSettings
import TipKit

// MARK: - AppDelegate（应用启动引导）

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 访问单例即可触发 DependencyContainer 组合根初始化。
        // 当前全球生产基线注入 NoOpAnalyticsService，不包含 Firebase SDK。
        _ = DependencyContainer.shared
        return true
    }
}

/// 应用的主入口
///
/// 负责配置应用的主窗口和根视图。
@main
struct SnapDrillApp: App {
    
    // MARK: - Properties
    
    /// 系统级别生命周期桥接（AppDelegate）
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    /// 引导页状态管理
    @State private var onboardingManager = OnboardingManager.shared
    
    /// 外观模式设置 (0=System, 1=Light, 2=Dark)
    @AppStorage(UDKey.appearanceMode) private var appearanceMode: Int = 0

    /// 场景生命周期，用于追踪 session 事件
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Computed Properties
    
    private var container: DependencyContainer {
        DependencyContainer.shared
    }

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            // 极简入口：仅负责注入环境和启动根视图
            ZStack {
                AppRootView(
                    router: container.router,
                    makeProfileManager: { await container.createProfileManager() }
                )
                    .preferredColorScheme(colorScheme)
            }
                .environment(\.services, container.services)
                .fullScreenCover(isPresented: $onboardingManager.shouldShowOnboarding) {
                    OnboardingView(pages: OnboardingPage.defaultPages) {
                        onboardingManager.completeOnboarding()
                    }
                }
                .task {
                    // TipKit 初始化（与引导页状态无关，始终执行）
                    do {
                        try Tips.configure([
                            .displayFrequency(.immediate),
                            .datastoreLocation(.applicationDefault)
                        ])
                    } catch {
                        SnapDrillLogger.generic.error("TipKit 初始化失败: \(error.localizedDescription)")
                    }

                    // App 启动事件（每次冷启动追踪一次）
                    container.services.analytics.track(.appLaunched, parameters: [
                        "version": container.services.appConfig.fullVersion
                    ])

                    // MetricKit 订阅注册（设备级崩溃/性能诊断，本地消费，ADR-005 D6=A；关 RC-4）
                    container.services.metricService.startMonitoring()

                    guard !onboardingManager.shouldShowOnboarding else { return }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        container.services.analytics.startSession()
                    case .background:
                        container.services.analytics.endSession()
                    default:
                        break
                    }
                }
        }
    }
}
