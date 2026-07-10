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
    /// 默认值：一个 inMemory 占位 ProfileManager（永不写真实数据）。
    ///
    /// 为何不再用 `nil` + getter `fatalError` 守卫缺失注入：
    /// SwiftUI/AttributeGraph 在解析 Environment 时可能先读取继承环境的默认值；若默认
    /// `nil` 且 getter `fatalError`，冷启动注入期间会间歇触发 EXC_BREAKPOINT。
    /// 故默认值改为 benign 占位、getter 不再 fatal；「忘记注入」由 AppRootView 的
    /// `if let profileManager { ... }` loading gate 在更上层守卫——真实例注入后才渲染消费方，
    /// 占位实例只使用内存数据栈且不修改 process-level UserDefaults（保留 49172637
    /// 零信任 ProfileScope 隔离意图，只把守卫层从 getter 上移到 root gate）。
    nonisolated static let defaultValue: ProfileManager = {
        MainActor.assumeIsolated { ProfileManager(inMemory: true) }
    }()
}

// MARK: - EnvironmentValues 扩展

public extension EnvironmentValues {
    /// Profile 管理器，用于学习者切换和管理
    var profileManager: ProfileManager {
        get { self[ProfileManagerKey.self] }
        set { self[ProfileManagerKey.self] = newValue }
    }
}
