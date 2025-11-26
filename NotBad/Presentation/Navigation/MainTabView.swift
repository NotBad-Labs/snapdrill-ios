//
//  MainTabView.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - Tab

/// 应用 Tab 枚举
enum Tab: Int, CaseIterable, Identifiable, Sendable {
    case dashboard = 0
    case library = 1
    case capture = 2
    case review = 3
    case profile = 4
    
    var id: Int { rawValue }
    
    /// Tab 标题
    var title: String {
        switch self {
        case .dashboard: "首页"
        case .library: "题库"
        case .capture: "录入"
        case .review: "复习"
        case .profile: "我的"
        }
    }
    
    /// 默认图标
    var icon: String {
        switch self {
        case .dashboard: "house"
        case .library: "books.vertical"
        case .capture: "plus.circle.fill"
        case .review: "sparkles"
        case .profile: "person.crop.circle"
        }
    }
    
    /// 选中状态图标
    var selectedIcon: String {
        switch self {
        case .dashboard: "house.fill"
        case .library: "books.vertical.fill"
        case .capture: "plus.circle.fill"
        case .review: "sparkles"
        case .profile: "person.crop.circle.fill"
        }
    }
}

// MARK: - MainTabView

/// 主界面 Tab 视图
///
/// 应用的核心导航结构，包含五个主要功能 Tab。
///
/// ## Tab 结构
///
/// 1. **首页** - 数据看板和快捷操作
/// 2. **题库** - 错题列表和管理
/// 3. **录入** - 快速录入新错题
/// 4. **复习** - 智能复习模式
/// 5. **我的** - 个人中心和设置
struct MainTabView: View {
    
    // MARK: - State
    
    @State private var selectedTab: Tab = .dashboard
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases) { tab in
                tabContent(for: tab)
                    .tabItem {
                        tabLabel(for: tab)
                    }
                    .tag(tab)
            }
        }
        .tint(.blue)
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView()
        case .library:
            LibraryView()
        case .capture:
            CaptureView()
        case .review:
            ReviewView()
        case .profile:
            ProfileView()
        }
    }
    
    // MARK: - Tab Label
    
    private func tabLabel(for tab: Tab) -> some View {
        let isSelected = selectedTab == tab
        
        return Label {
            Text(tab.title)
                .fontWeight(tab == .capture ? .semibold : .regular)
        } icon: {
            if tab == .capture {
                Image(systemName: tab.icon)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .blue)
            } else {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: ReviewItem.self, inMemory: true)
}
