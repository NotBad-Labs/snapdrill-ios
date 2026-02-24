//
//  SnapDrillApp.swift
//  SnapDrill
//
//  Created by SnapDrill Labs on 2025/12/29.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  应用入口文件，负责初始化应用和主界面配置
//

import SwiftUI
import SwiftData
import SnapDrillData
import SnapDrillFeatures
import SnapDrillCore
import TipKit

import FirebaseCore

// MARK: - AppDelegate（Firebase 初始化）

final class AppDelegate: NSObject, UIApplicationDelegate {
    /// 服务容器（在 didFinishLaunching 中初始化 Firebase 后注入）
    var serviceContainer: LiveServiceContainer?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        // 创建服务容器并标记 Firebase 就绪
        let container = LiveServiceContainer()
        if let analytics = container.analytics as? FirebaseAnalyticsService {
            analytics.markConfigured()
        }
        if let crash = container.crashReporting as? CrashReportingService {
            crash.markConfigured()
        }
        self.serviceContainer = container

        return true
    }
}

/// 应用的主入口
///
/// 负责配置应用的主窗口和根视图。
@main
struct SnapDrillApp: App {
    /// Firebase / 系统级别生命周期桥接
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    /// 顶级导航协调器 (Coordinator State)
    @State private var appRouter = AppRouter()
    
    /// 外观模式设置 (0=System, 1=Light, 2=Dark)
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    
    /// 服务容器（从 AppDelegate 获取或创建默认实例）
    private var services: any ServiceContainer {
        appDelegate.serviceContainer ?? LiveServiceContainer()
    }
    
    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
    
    var body: some Scene {
        WindowGroup {
            // 极简入口：仅负责注入环境和启动根视图
            AppRootView(router: appRouter)
                .modelContainer(PersistenceController.shared.container)
                .environment(\.services, services)
                .environment(services.networkMonitor)
                .preferredColorScheme(colorScheme)
                .onAppear {
                    // Initialize TipKit
                    try? Tips.configure([
                        .displayFrequency(.immediate),
                        .datastoreLocation(.applicationDefault)
                    ])
                    
                    // Initialize default subjects on first launch
                    let context = PersistenceController.shared.container.mainContext
                    let repository = SubjectRepository(modelContext: context)
                    repository.initializeDefaultsIfNeeded()
                }
                .task {
                    // ATT 隐私授权（遵循 Apple 延迟弹窗最佳实践）
                    await services.privacyConsent.requestTrackingAuthorizationIfNeeded()
                }
        }
    }
}
