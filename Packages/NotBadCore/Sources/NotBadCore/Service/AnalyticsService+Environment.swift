//
//  AnalyticsService+Environment.swift
//  NotBadCore
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
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
