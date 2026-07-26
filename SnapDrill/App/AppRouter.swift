//
//  AppRouter.swift
//  SnapDrill
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  应用层级路由管理，定义一级 Tab 和全局导航状态
//

import SwiftUI
import Observation
import SnapDrillFeatureCapture
import SnapDrillFeatureLibrary
import SnapDrillFeatureReview
import SnapDrillFeatureDashboard
import SnapDrillFeatureSettings

/// 应用的一级导航标签
enum AppTab: Hashable {
    /// 首页看板
    case dashboard
    /// 题库浏览
    case library
    /// 题目采集
    case capture
    /// 复习计划
    case review
    /// 系统设置
    case settings
}

/// 应用层级路由器
///
/// 负责管理一级 Tab 切换和各功能模块的子路由。
@Observable
final class AppRouter {
    
    // MARK: - Properties
    
    /// 当前选中的 Tab
    var selectedTab: AppTab = .dashboard
    
    /// 首页模块路由
    let dashboardRouter = DashboardRouter()
    /// 题库模块路由
    let libraryRouter = LibraryRouter()
    /// 采集模块路由
    let captureRouter = CaptureRouter()
    /// 复习模块路由
    let reviewRouter = ReviewRouter()
    /// 设置模块路由
    let settingsRouter = SettingsRouter()
    
    // MARK: - Initialization
    
    /// 初始化并设立绑定
    init() {
        dashboardRouter.onNavigateToReview = { [weak self] in
            self?.selectedTab = .review
        }
        
        dashboardRouter.onNavigateToCapture = { [weak self] draft in
            withAnimation(.spring(duration: 0.4)) {
                self?.selectedTab = .capture
            }
            if let draft = draft {
                self?.captureRouter.restoreDraft(draft)
            }
        }
        
        reviewRouter.onNavigateToLibrary = { [weak self] in
            self?.selectedTab = .library
        }
        
        reviewRouter.onNavigateToCapture = { [weak self] in
            self?.selectedTab = .capture
        }
    }

}
