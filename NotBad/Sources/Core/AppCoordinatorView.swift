//
//  AppCoordinatorView.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//  协调器视图 - 根据协调器状态显示不同界面
//

import SwiftUI

/// 协调器视图 - 作为应用的根视图，根据协调器状态展示相应界面
struct AppCoordinatorView: View {
    @ObservedObject var coordinator: AppCoordinator
    
    var body: some View {
        Group {
            if coordinator.isLoading {
                SplashView()
            } else {
                switch coordinator.currentFlow {
                case .splash:
                    SplashView()
                case .main:
                    MainTabView(createReviewItemUseCase: coordinator.createReviewItemUseCase)
                        .modelContainer(coordinator.modelContainer)
                }
            }
        }
        .animation(.easeInOut, value: coordinator.currentFlow)
    }
}

// MARK: - 基本视图

/// 启动画面
struct SplashView: View {
    var body: some View {
        ZStack {
            // 使用渐变背景，在浅色模式下更美观
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("NotBad")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("错题本")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.blue)
            }
        }
    }
}


// MARK: - 预览
#Preview {
    AppCoordinatorView(coordinator: AppCoordinator())
}
