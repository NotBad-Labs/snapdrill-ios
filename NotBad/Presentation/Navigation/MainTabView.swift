//
//  MainTabView.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import ReviewKit

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
    var title: LocalizedStringKey {
        switch self {
        case .dashboard: "tab_dashboard"
        case .library: "tab_library"
        case .capture: "tab_capture"
        case .review: "tab_review"
        case .profile: "tab_profile"
        }
    }

    /// 默认图标
    var icon: String {
        switch self {
        case .dashboard: "house"
        case .library: "books.vertical"
        case .capture: "plus.circle"
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

    // MARK: - Environment
    
    @Bindable private var router = NavigationRouter.shared

    // MARK: - State
    
    // 预加载各 Tab 视图，避免切换时重新创建
    @State private var loadedTabs: Set<Tab> = [.dashboard]

    // MARK: - Body

    var body: some View {
        TabView(selection: $router.selectedTab) {
            ForEach(Tab.allCases) { tab in
                LazyTabContent(tab: tab, isLoaded: loadedTabs.contains(tab))
                    .tabItem {
                        tabLabel(for: tab)
                    }
                    .tag(tab)
            }
        }
        .tint(Color.brand.primary)
        .onChange(of: router.selectedTab) { _, newValue in
            // 标记当前 Tab 为已加载
            loadedTabs.insert(newValue)
        }
        .task {
            // 后台预加载其他 Tab（延迟执行，不阻塞首屏）
            try? await Task.sleep(for: .milliseconds(500))
            await MainActor.run {
                loadedTabs = Set(Tab.allCases)
            }
        }
    }

    // MARK: - Tab Label

    private func tabLabel(for tab: Tab) -> some View {
        let isSelected = router.selectedTab == tab

        return Label {
            Text(tab.title)
        } icon: {
            Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
        }
        .accessibilityLabel(tab.title)
    }
}

// MARK: - Lazy Tab Content

/// 懒加载 Tab 内容容器
private struct LazyTabContent: View {
    let tab: Tab
    let isLoaded: Bool
    
    var body: some View {
        if isLoaded {
            tabView
        } else {
            // 占位视图，防止布局跳动
            Color.clear
                .overlay {
                    ProgressView()
                        .scaleEffect(0.8)
                }
        }
    }
    
    @ViewBuilder
    private var tabView: some View {
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
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
