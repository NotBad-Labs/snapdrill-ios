//
//  UseCaseContainer+Environment.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/27.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  将 UseCaseContainer 注册为 SwiftUI 环境变量键。
//

import SwiftUI
import SnapDrillDomain
import SnapDrillData

// MARK: - Environment Key

@MainActor
private struct UseCaseContainerKey: EnvironmentKey {
    nonisolated static let defaultValue: any UseCaseContainer = {
        MainActor.assumeIsolated {
            // 链接 RepositoryContainer
            let repos = DefaultRepositoryContainer()
            return DefaultUseCaseContainer(repositories: repos)
        }
    }()
}

// MARK: - EnvironmentValues 扩展

public extension EnvironmentValues {
    /// 业务用例容器
    var useCases: any UseCaseContainer {
        get { self[UseCaseContainerKey.self] }
        set { self[UseCaseContainerKey.self] = newValue }
    }
}
