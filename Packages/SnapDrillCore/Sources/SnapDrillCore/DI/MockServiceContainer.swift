//
//  MockServiceContainer.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  测试和 Preview 环境的服务容器实现
//

import Foundation

// MARK: - Mock 服务容器

/// 测试 / SwiftUI Preview 用服务容器
///
/// 所有服务都使用 Mock 实现，不依赖外部系统。
/// All services use mock implementations with no external dependencies.
public final class MockServiceContainer: ServiceContainer {

    // MARK: - ServiceContainer

    public let analytics: AnalyticsServiceProtocol
    public let pdfExport: PDFExportService
    public let appConfig: AppConfiguration
    public let privacyConsent: PrivacyConsentService
    public let notification: NotificationServiceProtocol

    // MARK: - Initialization

    /// 创建全 Mock 实现的服务容器，适用于单元测试和 SwiftUI Preview
    public init() {
        self.analytics = AnalyticsServiceMock()
        self.pdfExport = PDFExportService()
        self.appConfig = AppConfiguration()
        self.privacyConsent = PrivacyConsentService()
        self.notification = NotificationServiceMock()
    }
}
