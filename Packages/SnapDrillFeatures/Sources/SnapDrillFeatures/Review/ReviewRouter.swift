//
//  ReviewRouter.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  复习模块路由，管理复习卡片页面的导航路径。
//

import SwiftUI
import Observation
import SnapDrillUI

/// 复习模块导航目标
public enum ReviewDestination: Hashable {
    /// 占位页面
    case placeholder
}

/// 复习模块路由器
///
/// 管理整个复习会话流程的导航。
/// 目前复习会话主要在单页内通过状态切换完成（Flashcard 模式），
/// 未来可能会扩展到多页流程（如复习结果摘要页）。
///
/// ## 导航路径
/// - **首页**: 模块主入口，展示复习卡片。
/// - **ReviewDestination**: 预留的枚举，用于扩展子页面。
@MainActor
@Observable
public final class ReviewRouter: FeatureRouter {
    
    // MARK: - Properties
    
    /// 导航路径栈
    public var path = NavigationPath()
    
    /// 目标类型别名
    public typealias Destination = ReviewDestination
    
    /// 跳转到题库的回调
    public var onNavigateToLibrary: (() -> Void)?
    
    /// 跳转到采集的回调
    public var onNavigateToCapture: (() -> Void)?
    
    // MARK: - Initialization
    
    /// 初始化路由器
    public init() {}
}
