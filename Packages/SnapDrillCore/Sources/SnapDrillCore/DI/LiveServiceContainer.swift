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
public final class LiveServiceContainer: ServiceContainer {

    // MARK: - ServiceContainer

    public let analytics: AnalyticsServiceProtocol
    public let pdfExport: PDFExportService
    public let appConfig: AppConfiguration
    public let privacyConsent: PrivacyConsentService
    public let notification: NotificationServiceProtocol

    // MARK: - Initialization

    /// 创建生产服务容器
    ///
    /// - Parameters:
    ///   - analytics: 分析服务实例（生产环境由 DependencyContainer 注入 FirebaseAnalyticsService）
    ///   - notification: 通知服务实例（默认使用 Live 实现）
    public init(
        analytics: AnalyticsServiceProtocol? = nil,
        notification: NotificationServiceProtocol? = nil
    ) {
        self.appConfig = AppConfiguration()
        self.pdfExport = PDFExportService()
        self.privacyConsent = PrivacyConsentService()
        self.analytics = analytics ?? AnalyticsServiceMock()
        self.notification = notification ?? LiveNotificationService()
    }
}
