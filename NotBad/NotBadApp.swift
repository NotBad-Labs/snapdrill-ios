//
//  NotBadApp.swift
//  NotBad
//
//  Created by Yiming Liao on 9/20/25.
//

import SwiftUI
import SwiftData

/// NotBad 错题本应用主入口
///
/// 职责：
/// - 应用配置和启动
/// - 场景管理
/// - 根视图展示
@main
struct NotBadApp: App {
    
    // MARK: - App-level objects
    
    /// 应用级别协调器（Observation 风格注入）
    private let appCoordinator = AppCoordinator()
    
    /// 支持监听前后台等场景事件
    @Environment(\.scenePhase) private var scenePhase
    
    /// 可注入的 ModelContainer。默认使用 DataManager.shared.container，测试或预览可通过 init 注入自定义 container
    private let modelContainer: ModelContainer
    
    // MARK: - Initialization
    
    init(modelContainer: ModelContainer? = nil) {
        if let container = modelContainer {
            self.modelContainer = container
        } else {
            // 使用 DataManager 提供的容器（保持向后兼容）
            self.modelContainer = DataManager.shared.container
        }
        // 在这里可以初始化日志/遥测/远程配置等
        // Logger.shared.setup(...)
    }
    
    // MARK: - Scene
    
    var body: some Scene {
        WindowGroup {
            CoordinatorView()
                .modelContainer(modelContainer)
                .environment(appCoordinator)
                .onChange(of: scenePhase) { newPhase, _ in
                    switch newPhase {
                    case .active:
                        // 前台恢复、刷新短期数据
                        print("App 进入前台")
                    case .background:
                        // 后台保存数据
                        print("App 进入后台 - 尝试保存")
                        // 这里可触发持久化保存逻辑
                    case .inactive:
                        print("App 处于非活动状态")
                    @unknown default:
                        break
                    }
                }
        }
    }
}
