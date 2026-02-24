//
//  DashboardRouter.swift
//  SnapDrillFeatureDashboard
//
//  Created by SnapDrill Labs on 2025/12/29.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  首页看板路由，负责首页导航逻辑
//

import SwiftUI
import Observation
import SnapDrillUI

/// 首页看板导航目标
public enum DashboardDestination: Hashable {
    /// 占位页面
    case placeholder
}

/// 首页看板路由器
///
/// 负责应用启动默认页（首页）的导航逻辑。
///
/// ## 职责
/// - 作为应用的入口路由，未来可能处理 DeepLink 跳转到其他模块的逻辑。
/// - 管理 Dashboard 内部的任何子页面跳转。
@MainActor
@Observable
public final class DashboardRouter: FeatureRouter {
    /// 导航路径栈
    public var path = NavigationPath()
    
    /// 目标类型别名
    public typealias Destination = DashboardDestination
    
    /// 跳转到复习模块的回调
    ///
    /// 由父级协调器（AppRouter）注入具体实现。
    public var onNavigateToReview: (() -> Void)?
    
    /// 跳转到采集模块的回调 (Optional draft to restore)
    public var onNavigateToCapture: ((CaptureDraftService.Draft?) -> Void)?
    
    /// 初始化路由器
    public init() {}
    
    /// 请求导航到复习页面
    public func navigateToReview() {
        onNavigateToReview?()
    }
    
    /// 请求导航到采集页面
    public func navigateToCapture(withDraft draft: CaptureDraftService.Draft? = nil) {
        onNavigateToCapture?(draft)
    }
}
