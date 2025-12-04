//
//  AnalyticsServiceProtocol.swift
//  NotBad
//
//  用户行为埋点服务协议
//  支持未来接入 Firebase Analytics / Mixpanel / 自建后端
//

import Foundation

// MARK: - Analytics Event

/// 埋点事件
public struct AnalyticsEvent: Sendable {
    /// 事件名称
    public let name: String
    /// 事件参数
    public let parameters: [String: String]
    /// 事件时间
    public let timestamp: Date
    
    public init(name: String, parameters: [String: String] = [:]) {
        self.name = name
        self.parameters = parameters
        self.timestamp = Date()
    }
}

// MARK: - Predefined Events

/// 预定义事件名称
public enum AnalyticsEventName {
    // MARK: - 采集相关
    static let captureStarted = "capture_started"
    static let captureCompleted = "capture_completed"
    static let captureOCRUsed = "capture_ocr_used"
    static let captureLiveScanUsed = "capture_live_scan_used"
    
    // MARK: - 题库相关
    static let libraryViewed = "library_viewed"
    static let librarySearched = "library_searched"
    static let libraryFiltered = "library_filtered"
    static let itemViewed = "item_viewed"
    static let itemEdited = "item_edited"
    static let itemDeleted = "item_deleted"
    
    // MARK: - 复习相关
    static let reviewStarted = "review_started"
    static let reviewCompleted = "review_completed"
    static let reviewItemMarked = "review_item_marked"
    static let reviewSkipped = "review_skipped"
    
    // MARK: - 导出相关
    static let exportPDF = "export_pdf"
    static let exportJSON = "export_json"
    static let importData = "import_data"
    
    // MARK: - 应用生命周期
    static let appLaunched = "app_launched"
    static let appBackgrounded = "app_backgrounded"
    static let onboardingCompleted = "onboarding_completed"
}

// MARK: - Analytics Service Protocol

/// 埋点服务协议
/// 遵循协议的服务可以是本地日志、Firebase、Mixpanel 等
@MainActor
public protocol AnalyticsServiceProtocol: Sendable {
    /// 记录事件
    func track(_ event: AnalyticsEvent)
    
    /// 记录事件（便捷方法）
    func track(_ name: String, parameters: [String: String])
    
    /// 设置用户属性
    func setUserProperty(_ value: String, forName name: String)
    
    /// 设置用户 ID（可选，隐私优先可不设置）
    func setUserId(_ userId: String?)
}

// MARK: - Default Implementation

public extension AnalyticsServiceProtocol {
    func track(_ name: String, parameters: [String: String] = [:]) {
        track(AnalyticsEvent(name: name, parameters: parameters))
    }
}
