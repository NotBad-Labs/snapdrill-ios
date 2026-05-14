//
//  AppConfiguration.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  应用配置管理
//

import Foundation

/// 应用配置
///
/// 集中管理应用的所有配置项，提供类型安全的访问方式。
public final class AppConfiguration {
    
    // MARK: - Properties
    
    /// 共享实例 - 建议使用 ServiceContainer 注入
    public static let shared = AppConfiguration()
    
    // MARK: - Initialization

    /// 创建应用配置实例；通常通过 `ServiceContainer` 注入
    public init() {}
    
    // MARK: - Public API
    
    // MARK: - App Info
    
    /// 应用版本号
    public var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// 构建版本号
    public var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// 应用标识符
    public var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.snapdrill.app"
    }
    
    /// 完整版本字符串
    public var fullVersion: String {
        "\(appVersion) (\(buildNumber))"
    }
    
    // MARK: - Feature Flags
    
    /// 功能开关
    ///
    /// Remote Config 已移除。Telemetry 相关兼容入口统一委托给 `TelemetryGate`，
    /// 产品默认值为拒绝采集。
    public struct FeatureFlags {

        /// 是否启用崩溃报告
        ///
        /// Compatibility shim. The single source of truth is `TelemetryGate`.
        public static var crashReportingEnabled: Bool {
            get { TelemetryGate.isGranted }
            set { TelemetryGate.setGranted(newValue) }
        }

        /// 是否启用数据分析
        ///
        /// Compatibility shim. The single source of truth is `TelemetryGate`.
        public static var analyticsEnabled: Bool {
            get { TelemetryGate.isGranted }
            set { TelemetryGate.setGranted(newValue) }
        }
    }
    
    // MARK: - Environment
    
    /// 环境类型
    public enum Environment {
        case development
        case staging
        case production
        
        /// 当前运行环境（DEBUG 下为 `.development`，否则为 `.production`）
        public static var current: Environment {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }
    }
    
    /// 当前环境
    public var environment: Environment {
        return Environment.current
    }
    
    /// 是否为生产环境
    public var isProduction: Bool {
        return environment == .production
    }
    
    // MARK: - Reset
    
    /// 重置所有配置到产品定义的默认值（默认拒绝遥测）
    public func resetToDefaults() {
        TelemetryGate.reset()
    }
}
