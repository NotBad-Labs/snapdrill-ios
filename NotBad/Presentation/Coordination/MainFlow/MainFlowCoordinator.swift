//
//  TabConfig.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//


//
//  MainFlowCoordinator.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//

import SwiftUI
import Combine

// MARK: - Tab Configuration

/// 定义主标签栏的配置
/// 用于在 MainTabView 中渲染 TabBar
struct TabConfig: Identifiable, Hashable {
    let id: TabFlow
    let title: String
    let iconName: String
}

/// 定义每个 Tab 对应的子流程
enum TabFlow: CaseIterable {
    case dashboard
    case studyPractice
    case questionCapture
    case discovery
    case userProfile
}

// MARK: - Main Flow Coordinator

/// 主应用流程协调器
///
/// 职责：
/// - 管理主标签栏的视图和导航
/// - 协调五个主要功能模块的交互
/// - 作为 MainFlowView 的 ViewModel，连接视图和业务逻辑
@MainActor
final class MainFlowCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 当前选中的 Tab
    @Published var selectedTab: TabFlow = .dashboard
    
    // MARK: - Public Properties
    
    /// 所有 Tab 的配置
    let tabs: [TabConfig] = [
        .init(id: .dashboard, title: "主页", iconName: "house.fill"),
        .init(id: .studyPractice, title: "练习", iconName: "pencil.and.ruler.fill"),
        .init(id: .questionCapture, title: "录题", iconName: "camera.fill"),
        .init(id: .discovery, title: "发现", iconName: "magnifyingglass"),
        .init(id: .userProfile, title: "我的", iconName: "person.fill")
    ]
}

// MARK: - Main Tab View

/// 主标签栏视图
///
/// 职责：
/// - 渲染 TabBar UI
/// - 根据选中的 Tab 显示对应的子视图
/// - 自身不包含任何业务逻辑，由 MainFlowCoordinator 驱动
struct MainTabView: View {
    @ObservedObject var coordinator: MainFlowCoordinator
    
    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            ForEach(coordinator.tabs, id: \.self) { tab in
                mainFlowView(for: tab.id)
                    .tabItem {
                        Label(tab.title, systemImage: tab.iconName)
                    }
                    .tag(tab.id)
            }
        }
    }
    
    @ViewBuilder
    private func mainFlowView(for flow: TabFlow) -> some View {
        switch flow {
        case .dashboard:
            Text("主页内容")
        case .studyPractice:
            Text("学习练习内容")
        case .questionCapture:
            Text("录题内容")
        case .discovery:
            Text("发现内容")
        case .userProfile:
            Text("用户资料内容")
        }
    }
}

// MARK: - Main Flow View (RootView's entry point)

/// RootView 的主应用入口视图
///
/// 职责：
/// - 初始化 MainFlowCoordinator
/// - 将 MainFlowCoordinator 作为环境对象传递给 MainTabView
/// - 自身不包含任何业务逻辑
struct MainFlowView: View {
    
    @StateObject private var coordinator = MainFlowCoordinator()
    
    var body: some View {
        MainTabView(coordinator: coordinator)
            .environmentObject(coordinator)
    }
}
