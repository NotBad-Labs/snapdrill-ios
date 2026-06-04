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
    /// `profileManager` 是 computed property，`.environment(\.profileManager, x)` 经
    /// `swift_setAtWritableKeyPath` 做 get-modify-set 注入——SET 前必先调 getter 读旧值，
    /// 此刻继承环境仍是默认值。若默认 `nil` 且 getter `fatalError`，冷启动注入瞬间即崩
    /// （与 AttributeGraph 求值顺序相关 → 间歇 EXC_BREAKPOINT）。
    /// 故默认值改为 benign 占位、getter 不再 fatal；「忘记注入」由 AppRootView 的
    /// `if let profileManager { ... }` loading gate 在更上层守卫——真实例注入后才渲染消费方，
    /// 占位实例在生产中永不被真正读到（保留 49172637 零信任 ProfileScope 隔离意图，
    /// 只是把守卫层从 getter 上移到 root gate）。
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
