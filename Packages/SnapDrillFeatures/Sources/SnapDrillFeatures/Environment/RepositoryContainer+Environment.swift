//
//  RepositoryContainer+Environment.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//

import SwiftUI
import SnapDrillData

// MARK: - Environment Key

/// 仓库容器 Environment Key
///
/// 默认值为真实的 `DefaultRepositoryContainer`，供全部特性模块（Features）使用。
/// 用于替代之前直接通过 `@Environment(\.modelContext)` 来操控底层的做法。
@MainActor
private struct RepositoryContainerKey: EnvironmentKey {
    nonisolated static let defaultValue: any RepositoryContainer = {
        MainActor.assumeIsolated {
            DefaultRepositoryContainer()
        }
    }()
}

// MARK: - EnvironmentValues 扩展

public extension EnvironmentValues {
    /// 数据仓库容器
    ///
    /// 在 View 中使用 `@Environment(\.repositories)` 获取。
    var repositories: any RepositoryContainer {
        get { self[RepositoryContainerKey.self] }
        set { self[RepositoryContainerKey.self] = newValue }
    }
}
