//
//  DependencyContainer.swift
//  NotBad
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  依赖注入容器，管理全局服务实例。
//

import Foundation

// 注意：实际项目中需要将 NotBadUtils 和 NotBadSupport 添加到主 Target 的 Link Binary With Libraries 中
// import NotBadUtils
// import NotBadSupport

/// [Placeholder] 依赖注入容器
///
/// 这是一个架构占位符，用于未来集中管理依赖注入。
/// 在大型应用中，这里会初始化所有的 Service 和 Repository，并将它们注入到 ViewModel 或 Router 中。
///
/// 目前 NotBad 采用手动组合的方式在 `NotBadApp` 中完成这一工作。
@MainActor
final class DependencyContainer {
    static let shared = DependencyContainer()
    
    private init() {
        // Init Logger
        // NBLogger.info("App Initialized")
    }
}
