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

// NOTE: Firebase SDK 接入后取消注释
// import FirebaseCore

// MARK: - AppDelegate（Firebase 初始化）

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // NOTE: Firebase SDK 接入后取消注释
        // FirebaseApp.configure()
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
    
    /// 网络监控服务
    @State private var networkMonitor = NetworkMonitor()
    
    /// 外观模式设置 (0=System, 1=Light, 2=Dark)
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    
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
                .environment(networkMonitor)
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
        }
    }
}
