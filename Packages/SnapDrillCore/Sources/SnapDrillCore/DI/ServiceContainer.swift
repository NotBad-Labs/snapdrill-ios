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
/// ## 使用方式
/// ```swift
/// // 在 View 中通过 Environment 获取
/// @Environment(\.services) private var services
/// let analytics = services.analytics
/// ```
///
/// ## 行为保证
/// - 每个属性在容器生命周期内返回同一实例（缓存语义，非每次新建）
/// - 线程安全：`@MainActor` 隔离，所有属性访问均在主线程
/// - `DependencyContainer`（组合根）是唯一的生产实现；`MockServiceContainer` 用于测试和 Preview
///
/// ## 生命周期
/// - 容器随 App 启动创建，随 App 终止销毁
/// - 容器持有的服务实例与容器同生命周期
///
/// ## 不保证
/// - 属性的具体实现类型（调用方只应依赖协议或此处声明的具体类型）
@MainActor
public protocol ServiceContainer: Sendable {
    /// 分析服务（协议类型，生产环境为 Firebase 实现，测试为 Mock）
    var analytics: AnalyticsServiceProtocol { get }

    /// PDF 导出服务（具体类型，无替代测试手段时的例外）
    var pdfExport: PDFExportService { get }

    /// 应用配置（具体类型，全局唯一配置源）
    var appConfig: AppConfiguration { get }

    /// 隐私授权服务（具体类型，封装 ATT 框架）
    var privacyConsent: PrivacyConsentService { get }

    /// 通知服务（协议类型，生产环境为 UNUserNotificationCenter 实现，测试为 Mock）
    var notification: NotificationServiceProtocol { get }
}
