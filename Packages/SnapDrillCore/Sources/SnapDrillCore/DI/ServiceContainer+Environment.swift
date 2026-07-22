//
//  ServiceContainer+Environment.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SwiftUI Environment 集成，使 View 可通过 @Environment 获取服务
//

import SwiftUI

// MARK: - Environment Key

private struct ServiceContainerKey: EnvironmentKey {
    nonisolated static let defaultValue: any ServiceContainer = MissingServiceContainer()
}

/// Environment 读取与 SwiftUI 的 get-modify-set 注入必须保持安全；只有实际使用
/// 未注入的服务时才失败，以免默认值悄悄变成生产可用的 Mock。
private final class MissingServiceContainer: ServiceContainer {
    nonisolated init() {}

    var analytics: AnalyticsServiceProtocol { missing("analytics") }
    var pdfExport: PDFExportService { missing("pdfExport") }
    var appConfig: AppConfiguration { missing("appConfig") }
    var privacyConsent: PrivacyConsentService { missing("privacyConsent") }
    var notification: NotificationServiceProtocol { missing("notification") }
    var ocr: any OCRServiceProtocol { missing("ocr") }
    var captureDraft: any CaptureDraftServiceProtocol { missing("captureDraft") }
    var contentTagging: any ContentTaggingServiceProtocol { missing("contentTagging") }
    var questionSplitting: any QuestionSplittingServiceProtocol { missing("questionSplitting") }
    var deletionScheduler: DeletionScheduler { missing("deletionScheduler") }
    var proEntitlement: any ProEntitlementProvider { missing("proEntitlement") }
    var activityTracker: AppActivityTracker { missing("activityTracker") }
    var reviewScheduler: ReviewScheduler { missing("reviewScheduler") }
    var metricService: any MetricServiceProtocol { missing("metricService") }

    private func missing<T>(_ property: StaticString) -> T {
        preconditionFailure("SnapDrillCore: missing ServiceContainer environment injection (\(property))")
    }
}

// MARK: - EnvironmentValues 扩展

public extension EnvironmentValues {
    /// 服务容器
    ///
    /// 在 View 中使用 `@Environment(\.services)` 获取。
    /// ```swift
    /// @Environment(\.services) private var services
    /// ```
    var services: any ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}
