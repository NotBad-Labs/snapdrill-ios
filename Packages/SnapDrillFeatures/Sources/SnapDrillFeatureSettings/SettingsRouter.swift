//
//  SettingsRouter.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  设置模块路由，管理应用配置页面导航
//

import SwiftUI
import Observation
import SnapDrillUI

/// 设置模块导航目标
public enum SettingsDestination: Hashable {
    /// 占位页面
    case placeholder
    /// 开源许可页面
    case licenses
    /// 隐私政策页面
    case privacyPolicy
    /// 用户协议页面
    case termsOfService
    /// 资料空间管理页面
    case profileList
}

/// 设置模块路由器
///
/// 管理设置和偏好页面的导航流程。
/// 未来可扩展到包括账号管理、数据同步设置、提醒设置等多级子页面。
///
/// ## 扩展性
/// - **SettingsDestination**: 目前虽仅有占位符，但设计上支持嵌套的设置详情页。
@MainActor
@Observable
public final class SettingsRouter: @MainActor FeatureRouter {
    
    // MARK: - Properties
    
    /// 导航路径栈
    public var path = NavigationPath()
    
    /// 目标类型别名
    public typealias Destination = SettingsDestination
    
    // MARK: - Initialization

    /// 初始化路由器
    public init() {}
}

enum SettingsReleaseSurface {
    static var exposesOptionalCapabilities: Bool {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("--uitesting")
            && arguments.contains("--ui-test-optional-surface")
            && !arguments.contains("--ui-test-core-surface")
#else
        return false
#endif
    }
}
