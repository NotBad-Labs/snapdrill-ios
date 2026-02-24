//
//  FirebaseAnalyticsService.swift
//  SnapDrillCore
//
//  Created by SnapDrill Labs on 2026/02/24.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  Firebase Analytics 实现的 AnalyticsServiceProtocol 适配器。
//  当 Firebase SDK 接入后，将此类替换 AnalyticsTrackingService。
//

import Foundation
import OSLog

// NOTE: 取消注释下面的 import，并在 Xcode 中添加 FirebaseAnalytics SPM 依赖后才能使用
// import FirebaseAnalytics

/// Firebase Analytics 实现的分析服务适配器
///
/// 符合 `AnalyticsServiceProtocol`，将事件路由到 Firebase Analytics。
/// 在 Firebase SPM 依赖接入前，会降级到 OSLog 记录。
@MainActor
public final class FirebaseAnalyticsService: AnalyticsServiceProtocol {
    
    // MARK: - Properties
    
    public static let shared = FirebaseAnalyticsService()
    
    private let logger = Logger(subsystem: "com.snapdrill.app", category: "FirebaseAnalytics")
    private var isFirebaseConfigured: Bool = false
    
    // MARK: - Initialization
    
    private init() {}
    
    /// 标记 Firebase 已配置完毕（由 SnapDrillApp 在 FirebaseApp.configure() 后调用）
    public func markConfigured() {
        isFirebaseConfigured = true
        logger.info("✅ Firebase Analytics configured")
    }
    
    // MARK: - AnalyticsServiceProtocol
    
    public func track(_ event: AnalyticsEvent, parameters: [String: String]) {
        let name = event.rawValue
        
        // TODO: 启用 Firebase 后取消注释
        // Analytics.logEvent(name, parameters: parameters)
        
        logger.debug("📈 [FirebaseAnalytics] event: \(name), params: \(parameters)")
    }
    
    public func trackScreen(_ screenName: String, parameters: [String: String]) {
        // TODO: 启用 Firebase 后取消注释
        // Analytics.logEvent(AnalyticsEventScreenView, parameters: [
        //     AnalyticsParameterScreenName: screenName
        // ])
        
        logger.debug("📱 [FirebaseAnalytics] screen: \(screenName)")
    }
    
    public func startSession() {
        logger.debug("▶️ [FirebaseAnalytics] session started")
    }
    
    public func endSession() {
        logger.debug("⏹️ [FirebaseAnalytics] session ended")
    }
    
    public func setUserProperty(_ value: String, forKey key: String) {
        // TODO: 启用 Firebase 后取消注释
        // Analytics.setUserProperty(value, forName: key)
        
        logger.debug("👤 [FirebaseAnalytics] setUserProperty \(key): \(value)")
    }
    
    public func trackRetention(daysSinceInstall: Int) {
        let params: [String: String] = ["days_since_install": String(daysSinceInstall)]
        track(.appLaunched, parameters: params)
    }
}
