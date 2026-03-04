//
//  LiveServiceContainer.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  生产环境的服务容器实现
//

import Foundation

// MARK: - 生产服务容器

/// 生产环境服务容器
///
/// 持有所有服务的真实实例，在 App 启动时由 `SnapDrillApp` 创建并注入。
/// Production service container holding real service instances.
@MainActor
public final class LiveServiceContainer: ServiceContainer {

    // MARK: - ServiceContainer

    public let analytics: AnalyticsServiceProtocol
    public let crashReporting: CrashReportingProtocol
    public let performanceMonitor: PerformanceMonitor
    public let networkMonitor: NetworkMonitor
    public let pdfExport: PDFExportService
    public let appConfig: AppConfiguration
    public let privacyConsent: PrivacyConsentService
    public let subscription: SubscriptionServiceProtocol
    public let notification: NotificationServiceProtocol

    // MARK: - Initialization

    /// 创建生产服务容器
    ///
    /// - Parameters:
    ///   - analytics: 分析服务实例（生产环境由 DependencyContainer 注入 FirebaseAnalyticsService）
    ///   - crashReporting: 崩溃报告实例（生产环境由 DependencyContainer 注入 CrashReportingService）
    ///   - subscription: 订阅服务实例（默认使用 Mock，待 StoreKit 接入后替换）
    ///   - notification: 通知服务实例（默认使用 Live 实现）
    public init(
        analytics: AnalyticsServiceProtocol? = nil,
        crashReporting: CrashReportingProtocol? = nil,
        subscription: SubscriptionServiceProtocol? = nil,
        notification: NotificationServiceProtocol? = nil
    ) {
        self.appConfig = AppConfiguration()
        self.performanceMonitor = PerformanceMonitor()
        self.networkMonitor = NetworkMonitor()
        self.pdfExport = PDFExportService()
        self.privacyConsent = PrivacyConsentService()
        self.analytics = analytics ?? AnalyticsServiceMock()
        self.crashReporting = crashReporting ?? CrashReportingServiceMock()
        self.subscription = subscription ?? SubscriptionServiceMock()
        self.notification = notification ?? LiveNotificationService()
    }
}
