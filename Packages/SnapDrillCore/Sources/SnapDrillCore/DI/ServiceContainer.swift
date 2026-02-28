//
//  ServiceContainer.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  依赖注入容器协议，定义所有服务的获取接口
//

import Foundation

// MARK: - 服务容器协议

/// 服务容器协议
///
/// 集中管理应用中所有服务实例的创建和生命周期。
/// 所有功能模块通过此协议获取服务，而非直接引用单例。
///
/// Centralized service container protocol.
/// All feature modules obtain services through this protocol instead of referencing singletons.
///
/// ## 使用方式
/// ```swift
/// // 在 View 中通过 Environment 获取
/// @Environment(\.services) private var services
/// let analytics = services.analytics
/// ```
@MainActor
public protocol ServiceContainer: Sendable {
    /// 分析服务
    var analytics: AnalyticsServiceProtocol { get }

    /// 崩溃报告服务
    var crashReporting: CrashReportingProtocol { get }

    /// 性能监控服务
    var performanceMonitor: PerformanceMonitor { get }

    /// 网络状态监控
    var networkMonitor: NetworkMonitor { get }

    /// PDF 导出服务
    var pdfExport: PDFExportService { get }

    /// 应用配置
    var appConfig: AppConfiguration { get }

    /// 隐私授权服务
    var privacyConsent: PrivacyConsentService { get }

    /// 订阅服务
    var subscription: SubscriptionServiceProtocol { get }

    /// 通知服务
    var notification: NotificationServiceProtocol { get }
}
