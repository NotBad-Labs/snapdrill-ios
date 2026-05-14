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
    nonisolated static let defaultValue: ProfileManager? = nil
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
