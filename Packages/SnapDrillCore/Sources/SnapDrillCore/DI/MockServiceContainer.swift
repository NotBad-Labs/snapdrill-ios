//
//  MockServiceContainer.swift
//  SnapDrillCore
//
//  Created by SnapDrill Labs on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  测试和 Preview 环境的服务容器实现
//

import Foundation

// MARK: - Mock 服务容器

/// 测试 / SwiftUI Preview 用服务容器
///
/// 所有服务都使用 Mock 实现，不依赖外部系统。
/// All services use mock implementations with no external dependencies.
@MainActor
public final class MockServiceContainer: ServiceContainer {

    // MARK: - ServiceContainer

    public let analytics: AnalyticsServiceProtocol
    public let crashReporting: CrashReportingProtocol
    public let performanceMonitor: PerformanceMonitor
    public let networkMonitor: NetworkMonitor
    public let pdfExport: PDFExportService
    public let appConfig: AppConfiguration
    public let privacyConsent: PrivacyConsentService
    public let subscription: SubscriptionServiceProtocol

    // MARK: - Initialization

    public init() {
        self.analytics = AnalyticsServiceMock()
        self.crashReporting = CrashReportingServiceMock()
        self.performanceMonitor = PerformanceMonitor()
        self.networkMonitor = NetworkMonitor()
        self.pdfExport = PDFExportService()
        self.appConfig = AppConfiguration()
        self.privacyConsent = PrivacyConsentService()
        self.subscription = SubscriptionServiceMock()
    }
}
