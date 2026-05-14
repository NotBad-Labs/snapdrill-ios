//
//  ProfileManager+Environment.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  将 ProfileManager 注册为 SwiftUI 环境变量，供 Settings UI 使用。
//

import SwiftUI

// MARK: - Environment Key

private struct ProfileManagerKey: EnvironmentKey {
    /// 默认值：仅在测试运行时（XCTest / Swift Testing）返回 inMemory ProfileManager，
    /// 生产代码保持 nil 强制注入触发 fatal——保留 49172637 零信任 ProfileScope 隔离意图。
    ///
    /// 检测方式：`XCTestConfigurationFilePath` 环境变量由 Xcode test runner 注入，
    /// 也被 Swift Testing 框架沿用。生产 App 启动时该 env 不存在。
    nonisolated static let defaultValue: ProfileManager? = {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil else {
            return nil
        }
        return MainActor.assumeIsolated { ProfileManager(inMemory: true) }
    }()
}

// MARK: - EnvironmentValues 扩展

public extension EnvironmentValues {
    /// Profile 管理器，用于学习者切换和管理
    var profileManager: ProfileManager {
        get {
            guard let manager = self[ProfileManagerKey.self] else {
                fatalError("ProfileManager missing from SwiftUI environment. Inject one after await ProfileManager.create().")
            }
            return manager
        }
        set { self[ProfileManagerKey.self] = newValue }
    }
}
