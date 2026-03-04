//
//  FirebaseAnalyticsService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Firebase Analytics 实现的 AnalyticsServiceProtocol 适配器。
//

import Foundation
import OSLog

import FirebaseAnalytics

/// Firebase Analytics 实现的分析服务适配器
///
/// 符合 `AnalyticsServiceProtocol`，将事件路由到 Firebase Analytics。
@MainActor
public final class FirebaseAnalyticsService: AnalyticsServiceProtocol {
    
    // MARK: - Properties
    
    /// 共享实例 - 建议使用 ServiceContainer 注入
    public static let shared = FirebaseAnalyticsService()
    
    private let logger = Logger(subsystem: "com.snapdrill.app", category: "FirebaseAnalytics")
    private var isFirebaseConfigured: Bool = false
    
    // MARK: - Initialization
    
    public init() {}
    
    /// 标记 Firebase 已配置完毕（由 SnapDrillApp 在 FirebaseApp.configure() 后调用）
    public func markConfigured() {
        isFirebaseConfigured = true
        logger.info("✅ Firebase Analytics configured")
    }
    
    // MARK: - AnalyticsServiceProtocol
    
    public func track(_ event: AnalyticsEvent, parameters: [String: String]) {
        let name = event.rawValue
        
        // 只有在配置完成后才调用真实 SDK
        if isFirebaseConfigured {
            Analytics.logEvent(name, parameters: parameters)
        }
        
        logger.debug("📈 [FirebaseAnalytics] event: \(name), params: \(parameters)")
    }
    
    public func trackScreen(_ screenName: String, parameters: [String: String]) {
        if isFirebaseConfigured {
            var params = parameters
            params[AnalyticsParameterScreenName] = screenName
            Analytics.logEvent(AnalyticsEventScreenView, parameters: params)
        }
        
        logger.debug("📱 [FirebaseAnalytics] screen: \(screenName)")
    }
    
    public func startSession() {
        logger.debug("▶️ [FirebaseAnalytics] session started")
    }
    
    public func endSession() {
        logger.debug("⏹️ [FirebaseAnalytics] session ended")
    }
    
    public func setUserProperty(_ value: String, forKey key: String) {
        if isFirebaseConfigured {
            Analytics.setUserProperty(value, forName: key)
        }
        
        logger.debug("👤 [FirebaseAnalytics] setUserProperty \(key): \(value)")
    }
    
    public func trackRetention(daysSinceInstall: Int) {
        let params: [String: String] = ["days_since_install": String(daysSinceInstall)]
        track(.appLaunched, parameters: params)
    }
}
