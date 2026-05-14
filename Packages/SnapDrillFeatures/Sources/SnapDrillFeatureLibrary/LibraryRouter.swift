//
//  LibraryRouter.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  题库模块路由，管理题库浏览导航。
//

import SwiftUI
import Observation
import SnapDrillUI
import SnapDrillData

/// 题库模块导航目标
public enum LibraryDestination: Hashable {
    /// 占位页面
    case placeholder
    /// 题目详情
    case detail(ReviewItemModel)
}

/// 题库模块路由器
///
/// 管理整个题库浏览流程的导航状态。
/// 目前支持从列表跳转到详情页查看完整内容。
///
/// ## 导航路径
/// - **列表页**: 模块首页，展示题目列表。
/// - **详情页**: `.detail(ReviewItemModel)`，展示题目的图片、完整文本及元数据。
@MainActor
@Observable
public final class LibraryRouter: @MainActor FeatureRouter {

    // MARK: - Properties

    /// 导航路径栈
    ///
    /// 驱动 `NavigationStack` 的状态源。
    /// - Note: 此路径栈可能会被深度嵌套的详情页操作修改。
    public var path = NavigationPath()

    /// 目标类型别名
    public typealias Destination = LibraryDestination

    // MARK: - Initialization

    /// 初始化路由器
    public init() {}
}
