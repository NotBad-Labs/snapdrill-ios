//
//  AnalyticsService+Environment.swift
//  NotBadCore
//
//  Created by Yiming Liao on 2025/12/31.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  AnalyticsService 的 SwiftUI Environment 注入扩展。
//

import SwiftUI

private struct AnalyticsServiceKey: EnvironmentKey {
    static let defaultValue: any AnalyticsService = LoggingAnalyticsService()
}

public extension EnvironmentValues {
    var analyticsService: any AnalyticsService {
        get { self[AnalyticsServiceKey.self] }
        set { self[AnalyticsServiceKey.self] = newValue }
    }
}
