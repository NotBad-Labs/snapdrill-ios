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
///
/// ## 行为保证
/// - `fetchAndActivate()` 从远程拉取最新配置并激活，网络不可用时抛出错误
/// - 查询方法（`bool`/`string`/`double`）返回已激活的本地缓存值，不触发网络请求
/// - 线程安全：`@MainActor` 隔离
///
/// ## 返回值语义
/// - `nil` = 远程未配置此 key（从未 fetch 过，或 key 不存在于远程配置中）
/// - 非 `nil` = 远程已配置的值（含默认值和已覆盖值）
///
/// ## 不保证
/// - 调用频率不受限（实现方可能有内部节流，如 Firebase 的 12 小时最小间隔）
/// - fetch 后立即可用（激活可能有短暂延迟）
public protocol RemoteConfigurable {
    /// 从远程拉取最新配置并激活
    /// - Throws: 网络错误或服务端错误
    func fetchAndActivate() async throws

    /// 查询布尔配置项
    /// - Returns: 配置值；key 不存在时返回 `nil`
    func bool(forKey key: String) -> Bool?

    /// 查询字符串配置项
    /// - Returns: 配置值；key 不存在时返回 `nil`
    func string(forKey key: String) -> String?

    /// 查询浮点配置项
    /// - Returns: 配置值；key 不存在时返回 `nil`
    func double(forKey key: String) -> Double?
}

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
    public struct FeatureFlags {
        private static var remoteProvider: (any RemoteConfigurable)?
        
        /// 注册远程配置提供者
        public static func registerRemoteProvider(_ provider: any RemoteConfigurable) {
            self.remoteProvider = provider
        }
        
        /// 是否启用崩溃报告（产品要求默认开启）
        ///
        /// 优先级：用户本地设置 > 远程配置 > 产品默认值（true）。
        /// 隐私选择是用户的绝对权利，远程配置不得覆盖用户显式选择。
        public static var crashReportingEnabled: Bool {
            get {
                // 1. 用户显式设置（最高优先级 — 隐私选择不可被远程覆盖）
                if UserDefaults.standard.object(forKey: UDKey.crashReportingEnabled) != nil {
                    return UserDefaults.standard.bool(forKey: UDKey.crashReportingEnabled)
                }
                // 2. 远程配置（用户未设置时，允许远程调整默认行为）
                if let remote = remoteProvider?.bool(forKey: UDKey.crashReportingEnabled) {
                    return remote
                }
                // 3. 产品默认值（首启且无远程配置）
                return true
            }
            set { UserDefaults.standard.set(newValue, forKey: UDKey.crashReportingEnabled) }
        }

        /// 是否启用数据分析（产品要求默认开启）
        ///
        /// 优先级同 `crashReportingEnabled`：用户本地 > 远程配置 > 默认值。
        public static var analyticsEnabled: Bool {
            get {
                if UserDefaults.standard.object(forKey: UDKey.analyticsEnabled) != nil {
                    return UserDefaults.standard.bool(forKey: UDKey.analyticsEnabled)
                }
                if let remote = remoteProvider?.bool(forKey: UDKey.analyticsEnabled) {
                    return remote
                }
                return true
            }
            set { UserDefaults.standard.set(newValue, forKey: UDKey.analyticsEnabled) }
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
    
    /// 重置所有配置到产品定义的默认值（默认开启）
    public func resetToDefaults() {
        FeatureFlags.crashReportingEnabled = true
        FeatureFlags.analyticsEnabled = true
    }
}
