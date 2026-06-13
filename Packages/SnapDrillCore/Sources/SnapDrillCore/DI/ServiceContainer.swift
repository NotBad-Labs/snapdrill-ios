//
//  ServiceContainer.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
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
/// ## 使用方式
/// ```swift
/// @Environment(\.services) private var services
/// let ocr = services.ocr
/// ```
///
/// ## 行为保证
/// - 每个属性在容器生命周期内返回同一实例（缓存语义，非每次新建）
/// - 线程安全：`@MainActor` 隔离，所有属性访问均在主线程
/// - `LiveServiceContainer` 是生产实现；`MockServiceContainer` 用于测试和 Preview
///
/// ## 新增 Core service 规则（S-D4-001 共识）
/// 1. 若服务跨 Feature 使用、持有状态、依赖系统 API/AI/外部 SDK、或测试需要替换，必须进入 `ServiceContainer`
/// 2. Profile-scoped 服务走 `ProfileManager` / `RepositoryContainer`，不得放入全局 `ServiceContainer`
/// 3. 静态 facade（如 `TelemetryGate`）必须有架构豁免决策；不得直接从 Feature 层调用
public protocol ServiceContainer: Sendable {

    // MARK: - Analytics / 配置（既有 5）

    /// 分析服务（协议类型，生产环境为 NoOp 实现，测试为 Mock）
    var analytics: AnalyticsServiceProtocol { get }

    /// PDF 导出服务（具体类型，无替代测试手段时的例外）
    var pdfExport: PDFExportService { get }

    /// 应用配置（具体类型，全局唯一配置源）
    var appConfig: AppConfiguration { get }

    /// 隐私授权服务（ATT 已移除，ADR-002）
    var privacyConsent: PrivacyConsentService { get }

    /// 通知服务（协议类型，生产环境为 UNUserNotificationCenter 实现，测试为 Mock）
    var notification: NotificationServiceProtocol { get }

    // MARK: - Capture / AI（S-D4-001 新挂）

    /// OCR 识别服务（actor，端上 Vision 实现，测试可替换为 Mock）
    var ocr: any OCRServiceProtocol { get }

    /// 草稿持久化服务（采集页意外退出恢复，跨 Dashboard/Capture 共享状态）
    var captureDraft: any CaptureDraftServiceProtocol { get }

    /// 端上 AI 自动标注服务（Apple Foundation Models）
    var contentTagging: any ContentTaggingServiceProtocol { get }

    /// 一图多题智能拆题服务（Apple Foundation Models，阻塞 #626 真机验证）
    var questionSplitting: any QuestionSplittingServiceProtocol { get }

    // MARK: - 业务调度 / 权益（S-D4-001 新挂）

    /// 软删除 5 秒撤销窗口调度器（App 生命周期状态）
    var deletionScheduler: DeletionScheduler { get }

    /// Pro 订阅 entitlement 判定（阻塞 #479 StoreKit）
    var proEntitlement: any ProEntitlementProvider { get }

    /// Profile 切换保护 + 全局操作活动追踪（导出/备份/恢复期间禁止切 Profile）
    var activityTracker: AppActivityTracker { get }

    /// SM-2 复习调度策略（可替换以支持复习策略实验）
    var reviewScheduler: ReviewScheduler { get }

    // MARK: - 遥测诊断（S-D4-001，ADR-005 D6=A）

    /// 设备级遥测诊断服务（MetricKit，本地消费关 RC-4 崩溃监控；数据不出境、无需用户同意、不过 TelemetryGate）
    var metricService: any MetricServiceProtocol { get }
}
