//
//  CoordinatorView.swift
//  NotBad
//
//  Created by Yiming Liao on 10/7/25.
//

import SwiftUI

/// 协调器视图
///
/// 职责：
/// - 管理导航容器
/// - 处理页面跳转
/// - 连接协调器和视图
@MainActor
struct CoordinatorView: View {
    
    // MARK: - Properties
    
    // 从 App 注入的协调器
    @EnvironmentObject var coordinator: AppCoordinator
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            rootView()
                .navigationDestination(for: AppCoordinator.Destination.self) { destination in
                    destinationView(for: destination)
                }
                .sheet(item: $coordinator.presentedSheet) { destination in
                    sheetView(for: destination)
                }
                .fullScreenCover(item: $coordinator.presentedFullScreenCover) { destination in
                    fullScreenCoverView(for: destination)
                }
        }
        // Coordinator 由上层通过 .environmentObject 注入，不需要额外设置 environment
    }
    
    // MARK: - View Builders
    
    /// 根视图
    @ViewBuilder
    private func rootView() -> some View {
        WelcomeView()
    }
    
    /// 根据目的地创建视图
    @ViewBuilder
    private func destinationView(for destination: AppCoordinator.Destination) -> some View {
        switch destination {
        case .welcome:
            WelcomeView()
            
        case .home:
            HomeView()
            
        case .questionList:
            Text("错题列表")
                .navigationTitle("错题列表")
            
        case .questionDetail(let id):
            Text("错题详情: \(id)")
                .navigationTitle("错题详情")
            
        case .camera:
            Text("拍照识别")
                .navigationTitle("拍照")
            
        case .settings:
            Text("设置")
                .navigationTitle("设置")
            
        case .profile:
            Text("个人中心")
                .navigationTitle("个人")
        }
    }
    
    /// Sheet 视图
    @ViewBuilder
    private func sheetView(for destination: AppCoordinator.Destination) -> some View {
        NavigationStack {
            destinationView(for: destination)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭") {
                            coordinator.dismiss()
                        }
                    }
                }
        }
    }
    
    /// 全屏视图
    @ViewBuilder
    private func fullScreenCoverView(for destination: AppCoordinator.Destination) -> some View {
        destinationView(for: destination)
    }
}

// MARK: - Destination Identifiable

extension AppCoordinator.Destination: Identifiable {
    var id: String {
        switch self {
        case .welcome: return "welcome"
        case .home: return "home"
        case .questionList: return "questionList"
        case .questionDetail(let id): return "questionDetail-\(id)"
        case .camera: return "camera"
        case .settings: return "settings"
        case .profile: return "profile"
        }
    }
}

// MARK: - Preview

#Preview {
    CoordinatorView()
        .modelContainer(for: [], inMemory: true)
        .environmentObject(AppCoordinator())
}
