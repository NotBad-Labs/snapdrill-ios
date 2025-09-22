//
//  RootView.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI

/// 根视图
/// 专门负责应用的主要界面路由和状态展示
struct RootView: View {
    
    // MARK: - Environment Dependencies
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @EnvironmentObject private var errorHandler: AppErrorHandler
    @EnvironmentObject private var mainCoordinator: MainCoordinator
    
    // MARK: - State
    @State private var isLaunching = true
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if isLaunching {
                LaunchScreenView()
                    .task {
                        await performInitialization()
                    }
            } else {
                MainTabView(coordinator: mainCoordinator)
                    .task {
                        mainCoordinator.start()
                    }
            }
        }
        .animation(
            AppConfiguration.UI.Animation.defaultEasing,
            value: isLaunching
        )
    }
}

// MARK: - Private Methods
private extension RootView {
    
    /// 执行初始化流程（使用新的启动管理器）
    func performInitialization() async {
        let startupResult = await appEnvironment.startupManager.performStartup()
        
        await MainActor.run {
            if startupResult.success {
                withAnimation(AppConfiguration.UI.Animation.defaultEasing) {
                    isLaunching = false
                }
                
                #if DEBUG
                print("🚀 \(startupResult.description)")
                #endif
            } else {
                // 即使启动失败，也要显示主界面（优雅降级）
                withAnimation(AppConfiguration.UI.Animation.defaultEasing) {
                    isLaunching = false
                }
                
                #if DEBUG
                print("⚠️ \(startupResult.description)")
                #endif
            }
        }
    }
}

// MARK: - Preview
#Preview {
    RootView()
        .withAppEnvironment()
}