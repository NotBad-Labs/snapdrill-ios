//
//  MockServiceContainer.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
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
    public let ocr: any OCRServiceProtocol
    public let captureDraft: any CaptureDraftServiceProtocol
    public let contentTagging: any ContentTaggingServiceProtocol
    public let questionSplitting: any QuestionSplittingServiceProtocol
    public let deletionScheduler: DeletionScheduler
    public let proEntitlement: any ProEntitlementProvider
    public let activityTracker: AppActivityTracker
    public let reviewScheduler: ReviewScheduler

    // MARK: - Initialization

    /// 创建全 Mock 实现的服务容器，适用于单元测试和 SwiftUI Preview
    public init(
        analytics: AnalyticsServiceProtocol = AnalyticsServiceMock(),
        notification: NotificationServiceProtocol = NotificationServiceMock(),
        ocr: (any OCRServiceProtocol)? = nil,
        captureDraft: (any CaptureDraftServiceProtocol)? = nil,
        contentTagging: (any ContentTaggingServiceProtocol)? = nil,
        questionSplitting: (any QuestionSplittingServiceProtocol)? = nil,
        deletionScheduler: DeletionScheduler? = nil,
        proEntitlement: (any ProEntitlementProvider)? = nil,
        activityTracker: AppActivityTracker? = nil,
        reviewScheduler: ReviewScheduler = ReviewScheduler()
    ) {
        self.analytics = analytics
        self.pdfExport = PDFExportService()
        self.appConfig = AppConfiguration()
        self.privacyConsent = PrivacyConsentService()
        self.notification = notification
        self.ocr = ocr ?? OCRServiceMock()
        self.captureDraft = captureDraft ?? CaptureDraftServiceMock()
        self.contentTagging = contentTagging ?? ContentTaggingServiceMock()
        self.questionSplitting = questionSplitting ?? QuestionSplittingServiceMock()
        self.deletionScheduler = deletionScheduler ?? DeletionScheduler()
        self.proEntitlement = proEntitlement ?? MockProEntitlementProvider(isProUser: false)
        self.activityTracker = activityTracker ?? AppActivityTracker()
        self.reviewScheduler = reviewScheduler
    }
}
