//
//  LiveServiceContainer.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
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
    public let ocr: any OCRServiceProtocol
    public let captureDraft: any CaptureDraftServiceProtocol
    public let contentTagging: any ContentTaggingServiceProtocol
    public let questionSplitting: any QuestionSplittingServiceProtocol
    public let deletionScheduler: DeletionScheduler
    public let proEntitlement: any ProEntitlementProvider
    public let activityTracker: AppActivityTracker
    public let reviewScheduler: ReviewScheduler
    public let metricService: any MetricServiceProtocol

    // MARK: - Initialization

    /// 创建生产服务容器
    public init(
        analytics: AnalyticsServiceProtocol? = nil,
        notification: NotificationServiceProtocol? = nil,
        ocr: (any OCRServiceProtocol)? = nil,
        captureDraft: (any CaptureDraftServiceProtocol)? = nil,
        contentTagging: (any ContentTaggingServiceProtocol)? = nil,
        questionSplitting: (any QuestionSplittingServiceProtocol)? = nil,
        deletionScheduler: DeletionScheduler? = nil,
        proEntitlement: (any ProEntitlementProvider)? = nil,
        activityTracker: AppActivityTracker? = nil,
        reviewScheduler: ReviewScheduler? = nil,
        metricService: (any MetricServiceProtocol)? = nil
    ) {
        self.appConfig = AppConfiguration()
        self.pdfExport = PDFExportService()
        self.privacyConsent = PrivacyConsentService()
        self.analytics = analytics ?? NoOpAnalyticsService()
        self.notification = notification ?? LiveNotificationService()
        self.ocr = ocr ?? OCRService()
        self.captureDraft = captureDraft ?? CaptureDraftService()
        self.contentTagging = contentTagging ?? ContentTaggingService()
        self.questionSplitting = questionSplitting ?? QuestionSplittingService()
        self.deletionScheduler = deletionScheduler ?? DeletionScheduler()
        self.proEntitlement = proEntitlement ?? DefaultProEntitlementProvider()
        // KI-01：默认用 .shared 作为全局唯一实例。ProfileManager.switchProfile 查
        // AppActivityTracker.shared，故生产容器默认必须与之同实例，否则导出流
        // （services.activityTracker）的 begin/end 写在不同实例上、ProfileManager
        // 看不到 → Profile 切换保护失效。完整去 .shared（S-D4-001）是独立 refactor，
        // 此处 composition 层引用 .shared 可接受（包内无 treat-warnings-as-errors）。
        self.activityTracker = activityTracker ?? AppActivityTracker.shared
        self.reviewScheduler = reviewScheduler ?? ReviewScheduler()
        self.metricService = metricService ?? LiveMetricService(
            store: MetricDiagnosticsStore.production()
        )
    }
}
