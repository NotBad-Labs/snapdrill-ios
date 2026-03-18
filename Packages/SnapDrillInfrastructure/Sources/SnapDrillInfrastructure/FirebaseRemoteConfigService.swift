//
//  FirebaseRemoteConfigService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
@preconcurrency import FirebaseRemoteConfig
import SnapDrillCore

/// Firebase Remote Config 实现的远程配置服务
///
/// 将 Firebase 远程配置映射到 AppConfiguration。
@available(iOS 14.0, macOS 11.0, *)
@MainActor
public final class FirebaseRemoteConfigService: RemoteConfigurable {
    
    // MARK: - Properties
    
    private let remoteConfig = RemoteConfig.remoteConfig()
    
    // MARK: - Initialization
    
    public init() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600 // 1 hour for Beta
        remoteConfig.configSettings = settings
    }
    
    // MARK: - Public API
    
    /// 获取并激活最新的配置
    public func fetchAndActivate() async throws {
        let status = try await remoteConfig.fetchAndActivate()
        switch status {
        case .successFetchedFromRemote:
            SnapDrillLogger.generic.info("Remote Config fetched and activated from remote")
        case .successUsingPreFetchedData:
            SnapDrillLogger.generic.info("Remote Config using pre-fetched data")
        case .error:
            SnapDrillLogger.generic.error("Remote Config fetch failed")
        @unknown default:
            SnapDrillLogger.generic.warning("Remote Config unknown status")
        }
    }
    
    public func bool(forKey key: String) -> Bool? {
        let value = remoteConfig.configValue(forKey: key)
        // .static = key 未在远程配置中设置，返回 nil 让调用方使用产品默认值
        guard value.source != .static else { return nil }
        return value.boolValue
    }
    
    public func string(forKey key: String) -> String? {
        remoteConfig.configValue(forKey: key).stringValue
    }
    
    public func double(forKey key: String) -> Double? {
        remoteConfig.configValue(forKey: key).numberValue.doubleValue
    }
}
