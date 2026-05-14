//
//  ServiceContainer+Environment.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SwiftUI Environment 集成，使 View 可通过 @Environment 获取服务
//

import SwiftUI

// MARK: - Environment Key

/// 服务容器 Environment Key
///
/// 默认值为 Mock 容器，确保 Preview 无需额外配置即可运行。
private struct ServiceContainerKey: EnvironmentKey {
    nonisolated static let defaultValue: any ServiceContainer = {
        // 使用 MainActor.assumeIsolated 来安全创建默认值
        // 在 SwiftUI 的 Environment 中，此值仅在主线程访问
        MainActor.assumeIsolated {
            MockServiceContainer()
        }
    }()
}

// MARK: - EnvironmentValues 扩展

public extension EnvironmentValues {
    /// 服务容器
    ///
    /// 在 View 中使用 `@Environment(\.services)` 获取。
    /// ```swift
    /// @Environment(\.services) private var services
    /// ```
    var services: any ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}
