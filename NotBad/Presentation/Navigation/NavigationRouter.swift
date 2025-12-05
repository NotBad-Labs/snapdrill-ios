//
//  NavigationRouter.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import Observation

// MARK: - Navigation Router

/// 全局导航路由器
///
/// 负责管理应用的顶层导航状态（Tab 切换）和各 Tab 内的导航堆栈。
/// 替代 NotificationCenter 进行页面跳转。
///
/// ## 功能特性
///
/// - Tab 切换
/// - 各 Tab 独立的导航堆栈
/// - 支持 Spotlight 搜索结果导航
/// - 支持 Deep Link 导航
@MainActor
@Observable
final class NavigationRouter {
    
    /// 单例实例（用于 App Intents 等外部调用）
    static let shared = NavigationRouter()
    
    // MARK: - Tab Selection
    
    /// 当前选中的 Tab
    var selectedTab: Tab = .dashboard
    
    // MARK: - Navigation Paths
    
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
    
    // MARK: - Pending Navigation
    
    /// 待导航的错题 ID（用于 Spotlight 等外部导航）
    var pendingItemDetailId: UUID?
    
    // MARK: - Actions
    
    /// 切换 Tab
    func switchTab(to tab: Tab) {
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
    
    /// 导航到错题详情页
    ///
    /// - Parameter itemId: 错题 ID
    func navigateToItemDetail(itemId: UUID) {
        // 切换到题库 Tab
        selectedTab = .library
        
        // 设置待导航 ID，由 LibraryView 处理实际导航
        pendingItemDetailId = itemId
    }
}

// MARK: - Router Environment Key

private struct RouterEnvironmentKey: @preconcurrency EnvironmentKey {
    @MainActor static var defaultValue: NavigationRouter { NavigationRouter.shared }
}

extension EnvironmentValues {
    var router: NavigationRouter {
        get { self[RouterEnvironmentKey.self] }
        set { self[RouterEnvironmentKey.self] = newValue }
    }
}
