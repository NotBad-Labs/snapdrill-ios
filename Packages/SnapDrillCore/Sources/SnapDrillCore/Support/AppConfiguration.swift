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
                remoteProvider?.bool(forKey: UDKey.crashReportingEnabled) ??
                UserDefaults.standard.bool(forKey: UDKey.crashReportingEnabled)
            }
            set { UserDefaults.standard.set(newValue, forKey: UDKey.crashReportingEnabled) }
        }
        
        /// 是否启用数据分析
        public static var analyticsEnabled: Bool {
            get { 
                remoteProvider?.bool(forKey: UDKey.analyticsEnabled) ??
                UserDefaults.standard.bool(forKey: UDKey.analyticsEnabled)
            }
            set { UserDefaults.standard.set(newValue, forKey: UDKey.analyticsEnabled) }
        }
        
        /// 是否启用 iCloud 同步
        public static var iCloudSyncEnabled: Bool {
            get { 
                remoteProvider?.bool(forKey: UDKey.iCloudSyncEnabled) ??
                UserDefaults.standard.bool(forKey: UDKey.iCloudSyncEnabled)
            }
            set { UserDefaults.standard.set(newValue, forKey: UDKey.iCloudSyncEnabled) }
        }
        
        /// 远程强制关闭开关 (Kill-switch)
        /// 如果返回 true，则应用应进入锁定或维护状态。
        public static var isEmergencyKillSwitchActive: Bool {
            remoteProvider?.bool(forKey: "emergencyKillSwitch") ?? false
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
    }
}
