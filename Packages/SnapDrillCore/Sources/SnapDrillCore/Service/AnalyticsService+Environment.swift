//
//  AnalyticsService+Environment.swift
//  SnapDrillCore
//
//  Created by SnapDrill Labs on 2025/12/31.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  AnalyticsService 的 SwiftUI Environment 注入扩展。
//

import SwiftUI

private struct AnalyticsServiceKey: EnvironmentKey {
    static let defaultValue: some AnalyticsService = LoggingAnalyticsService()
}

public extension EnvironmentValues {
    var analyticsService: some AnalyticsService {
        get { self[AnalyticsServiceKey.self] }
        set { self[AnalyticsServiceKey.self] = newValue }
    }
}
