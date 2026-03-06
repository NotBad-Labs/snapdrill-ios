//
//  AppConfiguration.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/01/03.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  应用配置管理
//

import Foundation

/// 远程配置同步协议
///
/// 定义了从远程（如 Firebase Remote Config）同步功能开关和配置项的标准。
@MainActor
public protocol RemoteConfigurable {
    func fetchAndActivate() async throws
    func bool(forKey key: String) -> Bool
    func string(forKey key: String) -> String?
    func double(forKey key: String) -> Double?
}

/// 应用配置
///
/// 集中管理应用的所有配置项，提供类型安全的访问方式。
@MainActor
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
    @MainActor
    public struct FeatureFlags {
        private static var remoteProvider: (any RemoteConfigurable)?
        
        /// 注册远程配置提供者
        public static func registerRemoteProvider(_ provider: any RemoteConfigurable) {
            self.remoteProvider = provider
        }
        
        /// 是否启用崩溃报告
        public static var crashReportingEnabled: Bool {
            get { 
                remoteProvider?.bool(forKey: "crashReportingEnabled") ?? 
                UserDefaults.standard.bool(forKey: "crashReportingEnabled") 
            }
            set { UserDefaults.standard.set(newValue, forKey: "crashReportingEnabled") }
        }
        
        /// 是否启用数据分析
        public static var analyticsEnabled: Bool {
            get { 
                remoteProvider?.bool(forKey: "analyticsEnabled") ?? 
                UserDefaults.standard.bool(forKey: "analyticsEnabled") 
            }
            set { UserDefaults.standard.set(newValue, forKey: "analyticsEnabled") }
        }
        
        /// 是否启用 iCloud 同步
        public static var iCloudSyncEnabled: Bool {
            get { 
                remoteProvider?.bool(forKey: "iCloudSyncEnabled") ?? 
                UserDefaults.standard.bool(forKey: "iCloudSyncEnabled") 
            }
            set { UserDefaults.standard.set(newValue, forKey: "iCloudSyncEnabled") }
        }
        
        /// 是否启用性能监控
        public static var performanceMonitoringEnabled: Bool {
            get { 
                remoteProvider?.bool(forKey: "performanceMonitoringEnabled") ?? 
                UserDefaults.standard.bool(forKey: "performanceMonitoringEnabled") 
            }
            set { UserDefaults.standard.set(newValue, forKey: "performanceMonitoringEnabled") }
        }
        
        /// 远程强制关闭开关 (Kill-switch)
        /// 如果返回 true，则应用应进入锁定或维护状态。
        public static var isEmergencyKillSwitchActive: Bool {
            remoteProvider?.bool(forKey: "emergencyKillSwitch") ?? false
        }
    }
    
    // MARK: - Performance Thresholds
    
    /// 性能阈值配置
    public struct PerformanceThresholds {
        /// OCR 操作超时阈值（秒）
        public static let ocrTimeout: TimeInterval = 10.0
        
        /// PDF 导出超时阈值（秒）
        public static let pdfExportTimeout: TimeInterval = 30.0
        
        /// 数据导出超时阈值（秒）
        public static let dataExportTimeout: TimeInterval = 15.0
        
        /// iCloud 同步超时阈值（秒）
        public static let cloudSyncTimeout: TimeInterval = 60.0
        
        /// 慢操作警告阈值（秒）
        public static let slowOperationThreshold: TimeInterval = 1.0
        
        /// 非常慢操作阈值（秒）
        public static let verySlowOperationThreshold: TimeInterval = 3.0
    }
    
    // MARK: - Cache Configuration
    
    /// 缓存配置
    public struct CacheConfiguration {
        /// 图片缓存最大大小（字节）
        public static let maxImageCacheSize: Int = 100 * 1024 * 1024 // 100 MB
        
        /// 日志文件最大保留天数
        public static let maxLogRetentionDays: Int = 7
        
        /// 分析事件最大保留天数
        public static let maxAnalyticsRetentionDays: Int = 30
        
        /// 性能指标最大保留数量
        public static let maxPerformanceMetrics: Int = 100
    }
    
    // MARK: - Review Configuration
    
    /// 复习配置
    public struct ReviewConfiguration {
        /// 每日复习目标数量
        public static var dailyReviewGoal: Int {
            get { UserDefaults.standard.integer(forKey: "dailyReviewGoal") }
            set { UserDefaults.standard.set(newValue, forKey: "dailyReviewGoal") }
        }
        
        /// 是否启用复习提醒
        public static var reviewReminderEnabled: Bool {
            get { UserDefaults.standard.bool(forKey: "reviewReminderEnabled") }
            set { UserDefaults.standard.set(newValue, forKey: "reviewReminderEnabled") }
        }
        
        /// 复习提醒时间
        public static var reviewReminderTime: Date? {
            get { UserDefaults.standard.object(forKey: "reviewReminderTime") as? Date }
            set { UserDefaults.standard.set(newValue, forKey: "reviewReminderTime") }
        }
    }
    
    // MARK: - Debug Configuration
    
    /// 调试配置
    public struct DebugConfiguration {
        /// 是否为调试模式
        public static var isDebugMode: Bool {
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
        
        /// 是否启用详细日志
        public static var verboseLoggingEnabled: Bool {
            get { UserDefaults.standard.bool(forKey: "verboseLoggingEnabled") }
            set { UserDefaults.standard.set(newValue, forKey: "verboseLoggingEnabled") }
        }
        
        /// 是否显示性能指标
        public static var showPerformanceMetrics: Bool {
            get { UserDefaults.standard.bool(forKey: "showPerformanceMetrics") }
            set { UserDefaults.standard.set(newValue, forKey: "showPerformanceMetrics") }
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
    
    /// 重置所有配置到默认值
    public func resetToDefaults() {
        FeatureFlags.crashReportingEnabled = true
        FeatureFlags.analyticsEnabled = false
        FeatureFlags.iCloudSyncEnabled = true
        FeatureFlags.performanceMonitoringEnabled = true
        
        ReviewConfiguration.dailyReviewGoal = 20
        ReviewConfiguration.reviewReminderEnabled = false
        
        DebugConfiguration.verboseLoggingEnabled = false
        DebugConfiguration.showPerformanceMetrics = false
    }
}
