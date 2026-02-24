//
//  AnalyticsTrackingService.swift
//  SnapDrillCore
//
//  Created by SnapDrill Labs on 2026/01/03.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  用户行为分析追踪服务
//

import Foundation
import OSLog

/// 分析事件类型
public enum AnalyticsEvent: String {
    // 用户操作
    case appLaunched = "app_launched"
    case reviewItemCreated = "review_item_created"
    case reviewItemCompleted = "review_item_completed"
    case reviewSessionStarted = "review_session_started"
    case reviewSessionCompleted = "review_session_completed"
    
    // 功能使用
    case cameraOpened = "camera_opened"
    case ocrPerformed = "ocr_performed"
    case pdfExported = "pdf_exported"
    case dataExported = "data_exported"
    
    // iCloud 同步
    case icloudSyncStarted = "icloud_sync_started"
    case icloudSyncCompleted = "icloud_sync_completed"
    case icloudSyncFailed = "icloud_sync_failed"
    
    // 错误
    case errorOccurred = "error_occurred"
}

/// 分析追踪服务
///
/// 提供用户行为分析和功能使用追踪。
/// 在生产环境中，可以集成 Firebase Analytics、Mixpanel 或 Amplitude。
@MainActor
public final class AnalyticsTrackingService: @unchecked Sendable {
    public static let shared = AnalyticsTrackingService()
    
    private let logger = Logger(subsystem: "com.LIAOYIMING.SnapDrill", category: "Analytics")
    private var isEnabled: Bool
    private var sessionStartTime: Date?
    
    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "analyticsEnabled")
        
        // 默认禁用（隐私优先）
        if !UserDefaults.standard.bool(forKey: "analyticsConfigured") {
            self.isEnabled = false
            UserDefaults.standard.set(false, forKey: "analyticsEnabled")
            UserDefaults.standard.set(true, forKey: "analyticsConfigured")
        }
    }
    
    /// 启用或禁用分析
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "analyticsEnabled")
        logger.info("Analytics \(enabled ? "enabled" : "disabled")")
    }
    
    /// 追踪事件
    public func track(_ event: AnalyticsEvent, parameters: [String: Any] = [:]) {
        guard isEnabled else { return }
        
        logger.info("Event tracked: \(event.rawValue)")
        
        var enrichedParameters = parameters
        enrichedParameters["timestamp"] = Date().ISO8601Format()
        enrichedParameters["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        for (key, value) in enrichedParameters {
            logger.debug("  \(key): \(String(describing: value))")
        }
        
        // 在生产环境中，发送到分析服务
        // 例如: Analytics.logEvent(event.rawValue, parameters: enrichedParameters)
        
        // 保存到本地以供调试
        saveEventLocally(event: event, parameters: enrichedParameters)
    }
    
    /// 追踪屏幕浏览
    public func trackScreen(_ screenName: String, parameters: [String: Any] = [:]) {
        guard isEnabled else { return }
        
        logger.info("Screen viewed: \(screenName)")
        
        var params = parameters
        params["screen_name"] = screenName
        
        track(.appLaunched, parameters: params)
    }
    
    /// 开始会话追踪
    public func startSession() {
        guard isEnabled else { return }
        
        sessionStartTime = Date()
        logger.info("Session started")
        
        track(.appLaunched, parameters: [
            "session_start": Date().ISO8601Format()
        ])
    }
    
    /// 结束会话追踪
    public func endSession() {
        guard isEnabled, let startTime = sessionStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        logger.info("Session ended - Duration: \(duration)s")
        
        track(.appLaunched, parameters: [
            "session_end": Date().ISO8601Format(),
            "session_duration": duration
        ])
        
        sessionStartTime = nil
    }
    
    /// 设置用户属性
    public func setUserProperty(_ value: String, forKey key: String) {
        guard isEnabled else { return }
        
        logger.debug("User property set - \(key): \(value)")
        
        // 在生产环境中，设置用户属性
        // 例如: Analytics.setUserProperty(value, forName: key)
    }
    
    /// 追踪用户留存
    public func trackRetention(daysSinceInstall: Int) {
        guard isEnabled else { return }
        
        track(.appLaunched, parameters: [
            "retention_day": daysSinceInstall
        ])
    }
    
    // MARK: - Private Methods
    
    private func saveEventLocally(event: AnalyticsEvent, parameters: [String: Any]) {
        let eventData: [String: Any] = [
            "event": event.rawValue,
            "parameters": parameters
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: eventData, options: .prettyPrinted) {
            let analyticsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Analytics", isDirectory: true)
            
            try? FileManager.default.createDirectory(at: analyticsDirectory, withIntermediateDirectories: true)
            
            let eventFile = analyticsDirectory.appendingPathComponent("event_\(Date().timeIntervalSince1970).json")
            try? data.write(to: eventFile)
        }
    }
}
