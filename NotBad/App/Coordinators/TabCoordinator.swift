//
//  TabCoordinator.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import Observation

// MARK: - TabCoordinator

/// Tab 导航协调器
///
/// 负责管理 Tab 切换和各 Tab 内的导航状态，包括：
/// - Tab 选择状态
/// - 各 Tab 的导航堆栈
/// - 跨 Tab 导航（如 Spotlight 搜索结果）
/// - Deep Link 路由
///
/// ## 使用方式
///
/// ```swift
/// // 切换 Tab
/// tabCoordinator.selectTab(.library)
///
/// // 导航到错题详情
/// tabCoordinator.navigateToItemDetail(itemId: uuid)
///
/// // 重置当前 Tab 的导航堆栈
/// tabCoordinator.resetCurrentTab()
/// ```
@MainActor
@Observable
final class TabCoordinator {
    
    // MARK: - State
    
    /// 当前选中的 Tab
    var selectedTab: Tab = .dashboard
    
    /// 首页导航堆栈
    var dashboardPath = NavigationPath()
    
    /// 题库导航堆栈
    var libraryPath = NavigationPath()
    
    /// 录入导航堆栈
    var capturePath = NavigationPath()
    
    /// 复习导航堆栈
    var reviewPath = NavigationPath()
    
    /// 个人中心导航堆栈
    var profilePath = NavigationPath()
    
    /// 待导航的错题 ID（用于 Spotlight 等外部导航）
    var pendingItemDetailId: UUID?
    
    // MARK: - Feature Coordinators
    
    /// Dashboard 功能协调器
    private(set) var dashboardFeature: DashboardFeatureCoordinator!
    
    /// Library 功能协调器
    private(set) var libraryFeature: LibraryFeatureCoordinator!
    
    /// Capture 功能协调器
    private(set) var captureFeature: CaptureFeatureCoordinator!
    
    /// Review 功能协调器
    private(set) var reviewFeature: ReviewFeatureCoordinator!
    
    /// Profile 功能协调器
    private(set) var profileFeature: ProfileFeatureCoordinator!
    
    // MARK: - Initialization
    
    init() {
        // 初始化后设置 Feature 协调器（因为需要 self 引用）
        self.dashboardFeature = DashboardFeatureCoordinator(parent: self)
        self.libraryFeature = LibraryFeatureCoordinator(parent: self)
        self.captureFeature = CaptureFeatureCoordinator(parent: self)
        self.reviewFeature = ReviewFeatureCoordinator(parent: self)
        self.profileFeature = ProfileFeatureCoordinator(parent: self)
    }
    
    // MARK: - Tab Selection
    
    /// 切换 Tab
    func selectTab(_ tab: Tab) {
        selectedTab = tab
    }
    
    /// 重置当前 Tab 的导航堆栈
    func resetCurrentTab() {
        switch selectedTab {
        case .dashboard: dashboardPath = NavigationPath()
        case .library: libraryPath = NavigationPath()
        case .capture: capturePath = NavigationPath()
        case .review: reviewPath = NavigationPath()
        case .profile: profilePath = NavigationPath()
        }
    }
    
    /// 重置所有 Tab 的导航堆栈
    func resetAllTabs() {
        dashboardPath = NavigationPath()
        libraryPath = NavigationPath()
        capturePath = NavigationPath()
        reviewPath = NavigationPath()
        profilePath = NavigationPath()
    }
    
    // MARK: - Cross-Tab Navigation
    
    /// 导航到错题详情页
    ///
    /// - Parameter itemId: 错题 ID
    func navigateToItemDetail(itemId: UUID) {
        // 切换到题库 Tab
        selectedTab = .library
        
        // 设置待导航 ID，由 LibraryView 处理实际导航
        pendingItemDetailId = itemId
    }
    
    /// 从 Dashboard 快速开始复习
    func startReviewFromDashboard() {
        selectedTab = .review
    }
    
    /// 从任意位置开始录入
    func startCapture() {
        selectedTab = .capture
    }
    
    // MARK: - Navigation Path Binding
    
    /// 获取当前 Tab 的导航路径绑定
    func pathBinding(for tab: Tab) -> Binding<NavigationPath> {
        switch tab {
        case .dashboard: return Binding(get: { self.dashboardPath }, set: { self.dashboardPath = $0 })
        case .library: return Binding(get: { self.libraryPath }, set: { self.libraryPath = $0 })
        case .capture: return Binding(get: { self.capturePath }, set: { self.capturePath = $0 })
        case .review: return Binding(get: { self.reviewPath }, set: { self.reviewPath = $0 })
        case .profile: return Binding(get: { self.profilePath }, set: { self.profilePath = $0 })
        }
    }
}

// MARK: - TabFlowView

/// Tab 流程视图
///
/// 根据设备类型显示适配的 Tab 导航界面
struct TabFlowView: View {
    
    // MARK: - Environment
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - Coordinator
    
    let coordinator: TabCoordinator
    
    // MARK: - State
    
    /// 当前选中的侧边栏项（iPad）
    @State private var selectedSidebarItem: SidebarItem? = .dashboard
    
    /// 侧边栏可见性（iPad）
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    /// 已加载的 Tab（懒加载优化）
    @State private var loadedTabs: Set<Tab> = [.dashboard]
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .onChange(of: coordinator.selectedTab) { _, newValue in
            if let item = SidebarItem(rawValue: newValue.rawValue) {
                selectedSidebarItem = item
            }
            loadedTabs.insert(newValue)
        }
        .onChange(of: selectedSidebarItem) { _, newValue in
            if let item = newValue, let tab = Tab(rawValue: item.rawValue) {
                coordinator.selectedTab = tab
            }
        }
        // Handoff Support
        .userActivity(UserActivityType.viewDashboard, isActive: coordinator.selectedTab == .dashboard) { activity in
            activity.title = String(localized: "tab_dashboard")
        }
        .userActivity(UserActivityType.viewLibrary, isActive: coordinator.selectedTab == .library) { activity in
            activity.title = String(localized: "tab_library")
        }
        .userActivity(UserActivityType.captureItem, isActive: coordinator.selectedTab == .capture) { activity in
            activity.title = String(localized: "tab_capture")
        }
        .userActivity(UserActivityType.reviewSession, isActive: coordinator.selectedTab == .review) { activity in
            activity.title = String(localized: "tab_review")
        }
        .userActivity(UserActivityType.viewProfile, isActive: coordinator.selectedTab == .profile) { activity in
            activity.title = String(localized: "tab_profile")
        }
        .task {
            // 后台预加载其他 Tab
            try? await Task.sleep(for: .milliseconds(500))
            loadedTabs = Set(Tab.allCases)
        }
    }
    
    // MARK: - iPhone Layout
    
    private var iPhoneLayout: some View {
        TabView(selection: Binding(
            get: { coordinator.selectedTab },
            set: { coordinator.selectTab($0) }
        )) {
            ForEach(Tab.allCases) { tab in
                LazyTabContent(tab: tab, isLoaded: loadedTabs.contains(tab))
                    .tabItem {
                        tabLabel(for: tab)
                    }
                    .tag(tab)
            }
        }
        .tint(Color.brand.primary)
    }
    
    // MARK: - iPad Layout
    
    private var iPadLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarContent
                .navigationTitle("app_name")
        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Color.brand.primary)
    }
    
    // MARK: - Sidebar Content
    
    private var sidebarContent: some View {
        List(selection: $selectedSidebarItem) {
            Section {
                ForEach(SidebarItem.allCases.prefix(4)) { item in
                    sidebarRow(for: item)
                }
            } header: {
                Text("sidebar_section_main")
            }
            
            Section {
                sidebarRow(for: .profile)
            } header: {
                Text("sidebar_section_settings")
            }
        }
        .listStyle(.sidebar)
    }
    
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
    
    @ViewBuilder
    private var detailContent: some View {
        switch selectedSidebarItem {
        case .dashboard: DashboardView()
        case .library: LibraryView()
        case .capture: CaptureView()
        case .review: ReviewView()
        case .profile: ProfileView()
        case .none: DashboardView()
        }
    }
    
    // MARK: - Tab Label
    
    private func tabLabel(for tab: Tab) -> some View {
        let isSelected = coordinator.selectedTab == tab
        return Label {
            Text(tab.title)
        } icon: {
            Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
        }
        .accessibilityLabel(tab.title)
    }
}

// MARK: - Lazy Tab Content

private struct LazyTabContent: View {
    let tab: Tab
    let isLoaded: Bool
    
    var body: some View {
        if isLoaded {
            tabView
        } else {
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
        case .dashboard: DashboardView()
        case .library: LibraryView()
        case .capture: CaptureView()
        case .review: ReviewView()
        case .profile: ProfileView()
        }
    }
}

// MARK: - Environment Key

private struct TabCoordinatorKey: EnvironmentKey {
    static let defaultValue: TabCoordinator? = nil
}

extension EnvironmentValues {
    var tabCoordinator: TabCoordinator? {
        get { self[TabCoordinatorKey.self] }
        set { self[TabCoordinatorKey.self] = newValue }
    }
}
