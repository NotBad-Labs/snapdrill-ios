//
//  AnalyticsService+Environment.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  AnalyticsService 的 SwiftUI Environment 注入扩展。
//

import SwiftUI

// MARK: - EnvironmentKey

// ⚠️ Swift 6 注意事项：
// EnvironmentKey.defaultValue 不能使用 `some Protocol` 不透明类型，
// 因为 getter 和 setter 的类型必须完全一致（existential `any Protocol` 可以）。
private struct AnalyticsServiceKey: EnvironmentKey {
    static var defaultValue: any AnalyticsServiceProtocol {
        MainActor.assumeIsolated { AnalyticsServiceMock() }
    }
}

// MARK: - EnvironmentValues Extension

public extension EnvironmentValues {
    var analyticsService: any AnalyticsServiceProtocol {
        get { self[AnalyticsServiceKey.self] }
        set { self[AnalyticsServiceKey.self] = newValue }
    }
}
