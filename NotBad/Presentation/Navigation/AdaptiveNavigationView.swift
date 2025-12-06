//
//  AdaptiveNavigationView.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//  iPad 自适应导航视图
//

import SwiftUI
import ReviewKit

// MARK: - Sidebar Item

/// 侧边栏导航项
enum SidebarItem: Int, CaseIterable, Identifiable, Hashable {
    case dashboard = 0
    case library = 1
    case capture = 2
    case review = 3
    case profile = 4
    
    var id: Int { rawValue }
    
    /// 标题
    var title: LocalizedStringKey {
        switch self {
        case .dashboard: "tab_dashboard"
        case .library: "tab_library"
        case .capture: "tab_capture"
        case .review: "tab_review"
        case .profile: "tab_profile"
        }
    }
    
    /// 图标
    var icon: String {
        switch self {
        case .dashboard: "house"
        case .library: "books.vertical"
        case .capture: "plus.circle"
        case .review: "sparkles"
        case .profile: "person.crop.circle"
        }
    }
    
    /// 选中图标
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

// MARK: - AdaptiveNavigationView

/// iPad 自适应导航视图
///
/// 在 iPad 上使用 NavigationSplitView 提供侧边栏导航，
/// 在 iPhone 上回退到标准 TabView 导航。
///
/// ## 功能特性
///
/// - iPad: 双栏布局，左侧为功能导航，右侧为详细内容
/// - iPhone: 标准底部 Tab 导航
/// - 自动响应设备类型和屏幕尺寸
///
/// ## 使用示例
///
/// ```swift
/// AdaptiveNavigationView()
///     .modelContainer(for: ReviewItem.self)
/// ```
struct AdaptiveNavigationView: View {
    
    // MARK: - Environment
    
    /// 水平尺寸类
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    /// 导航路由器
    @Environment(\.router) private var router
    
    // MARK: - State
    
    /// 当前选中的侧边栏项
    @State private var selectedSidebarItem: SidebarItem? = .dashboard
    
    /// 侧边栏可见性
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad: 使用 NavigationSplitView
                iPadLayout
            } else {
                // iPhone: 使用 TabView
                MainTabView()
            }
        }
        .onChange(of: router.selectedTab) { _, newValue in
            if let item = SidebarItem(rawValue: newValue.rawValue) {
                selectedSidebarItem = item
            }
        }
        .onChange(of: selectedSidebarItem) { _, newValue in
            if let item = newValue, let tab = Tab(rawValue: item.rawValue) {
                router.selectedTab = tab
            }
        }
        // Handoff Support
        .userActivity(UserActivityType.viewDashboard, isActive: isCurrent(.dashboard)) { activity in
            activity.title = String(localized: "tab_dashboard")
        }
        .userActivity(UserActivityType.viewLibrary, isActive: isCurrent(.library)) { activity in
            activity.title = String(localized: "tab_library")
        }
        .userActivity(UserActivityType.captureItem, isActive: isCurrent(.capture)) { activity in
            activity.title = String(localized: "tab_capture")
        }
        .userActivity(UserActivityType.reviewSession, isActive: isCurrent(.review)) { activity in
            activity.title = String(localized: "tab_review")
        }
        .userActivity(UserActivityType.viewProfile, isActive: isCurrent(.profile)) { activity in
            activity.title = String(localized: "tab_profile")
        }
    }
    
    // MARK: - Helper
    
    private func isCurrent(_ item: SidebarItem) -> Bool {
        if horizontalSizeClass == .regular {
            return selectedSidebarItem == item
        } else {
            return router.selectedTab.rawValue == item.rawValue
        }
    }
    
    // MARK: - iPad Layout
    
    /// iPad 双栏布局
    private var iPadLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 侧边栏
            sidebarContent
                .navigationTitle("app_name")
        } detail: {
            // 详细内容
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Color.brand.primary)
    }
    
    // MARK: - Sidebar Content
    
    /// 侧边栏内容
    private var sidebarContent: some View {
        List(selection: $selectedSidebarItem) {
            // 主要功能区
            Section {
                ForEach(SidebarItem.allCases.prefix(4)) { item in
                    sidebarRow(for: item)
                }
            } header: {
                Text("sidebar_section_main")
            }
            
            // 设置区
            Section {
                sidebarRow(for: .profile)
            } header: {
                Text("sidebar_section_settings")
            }
        }
        .listStyle(.sidebar)
    }
    
    /// 侧边栏行
    private func sidebarRow(for item: SidebarItem) -> some View {
        Label {
            Text(item.title)
        } icon: {
            Image(systemName: selectedSidebarItem == item ? item.selectedIcon : item.icon)
                .foregroundStyle(selectedSidebarItem == item ? Color.brand.primary : .secondary)
        }
        .tag(item)
        .accessibilityLabel(item.title)
    }
    
    // MARK: - Detail Content
    
    /// 详细内容视图
    @ViewBuilder
    private var detailContent: some View {
        switch selectedSidebarItem {
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
        case .none:
            // 默认显示 Dashboard
            DashboardView()
        }
    }
    
    // MARK: - Deep Link
    
    /// 处理 Deep Link 导航
    private func handleDeepLink(_ item: SidebarItem) {
        if horizontalSizeClass == .regular {
            selectedSidebarItem = item
        } else {
            if let tab = Tab(rawValue: item.rawValue) {
                router.selectedTab = tab
            }
        }
    }
}

// MARK: - Preview

#Preview("iPad Layout") {
    AdaptiveNavigationView()
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}

#Preview("iPhone Layout") {
    AdaptiveNavigationView()
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
