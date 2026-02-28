//
//  CrashReportingService+Environment.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  CrashReportingProtocol 的 SwiftUI Environment 注入扩展。
//

import SwiftUI

// MARK: - EnvironmentKey

private struct CrashReportingServiceKey: EnvironmentKey {
    static var defaultValue: any CrashReportingProtocol {
        MainActor.assumeIsolated { CrashReportingService.shared }
    }
}

// MARK: - EnvironmentValues Extension

public extension EnvironmentValues {
    @MainActor
    var crashReportingService: any CrashReportingProtocol {
        get { self[CrashReportingServiceKey.self] }
        set { self[CrashReportingServiceKey.self] = newValue }
    }
}
