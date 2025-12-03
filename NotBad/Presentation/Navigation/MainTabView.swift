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

    // MARK: - Bindings

    /// 外部 Tab 选择绑定（用于 Deep Link）
    @Binding var selectedTab: Int

    // MARK: - State

    @State private var currentTab: Tab = .dashboard

    // MARK: - Init

    init(selectedTab: Binding<Int> = .constant(0)) {
        _selectedTab = selectedTab
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $currentTab) {
            ForEach(Tab.allCases) { tab in
                tabContent(for: tab)
                    .tabItem {
                        tabLabel(for: tab)
                    }
                    .tag(tab)
            }
        }
        .tint(Color.brand.primary)
        .onChange(of: selectedTab) { _, newValue in
            if let tab = Tab(rawValue: newValue) {
                currentTab = tab
            }
        }
        .onChange(of: currentTab) { _, newValue in
            selectedTab = newValue.rawValue
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToCapture)) { _ in
            currentTab = .capture
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToReview)) { _ in
            currentTab = .review
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToLibrary)) { _ in
            currentTab = .library
        }
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
        let isSelected = currentTab == tab

        return Label {
            Text(tab.title)
        } icon: {
            Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
        }
        .accessibilityLabel(tab.title)
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: ReviewItem.self, inMemory: true)
}
