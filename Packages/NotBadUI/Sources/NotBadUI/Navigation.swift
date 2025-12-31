//
//  Navigation.swift
//  NotBadUI
//
//  Created by Yiming Liao on 2025/12/29.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  Feature 模块路由协议定义，提供统一的导航契约
//

import SwiftUI

/// Feature 模块路由协议
///
/// 定义了驱动 `NavigationStack` 的最小契约。
/// 所有功能模块的 Router 都应遵守此协议，以保证导航行为的一致性。
///
/// ## 核心职责
/// - **状态管理**: 持有 `NavigationPath` 状态。
/// - **导航操作**: 提供 Push, Pop, Reset 的标准接口。
///
/// ## 使用范例
/// ```swift
/// @MainActor
/// class MyFeatureRouter: FeatureRouter {
///     typealias Destination = MyFeatureDestination
///     @Published var path = NavigationPath()
/// }
/// ```
@MainActor
public protocol FeatureRouter: AnyObject, Observable {
    /// 导航目标类型
    ///
    /// 通常是一个枚举，列出了该模块内所有可导航到的子页面。必须遵循 `Hashable` 以支持 SwiftUI 导航。
    associatedtype Destination: Hashable
    
    /// 导航路径栈
    ///
    /// SwiftUI 的 `NavigationStack` 绑定的状态源。
    var path: NavigationPath { get set }
    
    /// 推入一个新的页面
    /// - Parameter destination: 目标页面枚举值
    func push(_ destination: Destination)
    
    /// 弹出当前页面（返回上一页）
    ///
    /// 如果栈为空，则不执行任何操作。
    func pop()
    
    /// 重置导航栈（回到根页面）
    ///
    /// 清空所有路径，立即返回模块首页。
    func reset()
}

public extension FeatureRouter {
    func push(_ destination: Destination) {
        path.append(destination)
    }
    
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func reset() {
        path = NavigationPath()
    }
}
