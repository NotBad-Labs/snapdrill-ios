//
//  LocalAnalyticsService.swift
//  NotBad
//
//  本地埋点服务实现
//  将事件记录到 OSLog，用于调试和本地分析
//  未来可替换为 Firebase/Mixpanel 实现
//

import Foundation
import OSLog

// MARK: - Local Analytics Service

/// 本地埋点服务
/// 使用 OSLog 记录事件，便于调试和 Console.app 查看
@MainActor
public final class LocalAnalyticsService: AnalyticsServiceProtocol, @unchecked Sendable {
    
    // MARK: - Singleton
    
    public static let shared = LocalAnalyticsService()
    
    // MARK: - Properties
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.notbad.app",
        category: "Analytics"
    )
    
    /// 事件缓存（用于调试查看最近事件）
    private var recentEvents: [AnalyticsEvent] = []
    private let maxRecentEvents = 100
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - AnalyticsServiceProtocol
    
    public func track(_ event: AnalyticsEvent) {
        // 记录到 OSLog
        let paramsString = event.parameters.isEmpty 
            ? "" 
            : " | \(event.parameters.map { "\($0.key)=\($0.value)" }.joined(separator: ", "))"
        
        logger.info("📈 [\(event.name, privacy: .public)]\(paramsString, privacy: .public)")
        
        // 缓存最近事件
        recentEvents.append(event)
        if recentEvents.count > maxRecentEvents {
            recentEvents.removeFirst()
        }
        
        #if DEBUG
        // Debug 模式下打印到控制台
        print("📈 Analytics: \(event.name)\(paramsString)")
        #endif
    }
    
    public func setUserProperty(_ value: String, forName name: String) {
        logger.info("👤 UserProperty: \(name, privacy: .public) = \(value, privacy: .private)")
    }
    
    public func setUserId(_ userId: String?) {
        if let userId = userId {
            logger.info("👤 UserId set: \(userId, privacy: .private(mask: .hash))")
        } else {
            logger.info("👤 UserId cleared")
        }
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    /// 获取最近事件（仅调试用）
    public var debugRecentEvents: [AnalyticsEvent] {
        recentEvents
    }
    
    /// 清除事件缓存
    public func clearEvents() {
        recentEvents.removeAll()
    }
    #endif
}

// MARK: - Convenience Extensions

public extension LocalAnalyticsService {
    
    // MARK: - 采集事件
    
    func trackCaptureStarted(source: String) {
        track(AnalyticsEventName.captureStarted, parameters: ["source": source])
    }
    
    func trackCaptureCompleted(hasImage: Bool, hasOCR: Bool, subject: String) {
        track(AnalyticsEventName.captureCompleted, parameters: [
            "has_image": String(hasImage),
            "has_ocr": String(hasOCR),
            "subject": subject
        ])
    }
    
    // MARK: - 复习事件
    
    func trackReviewStarted(itemCount: Int) {
        track(AnalyticsEventName.reviewStarted, parameters: ["item_count": String(itemCount)])
    }
    
    func trackReviewCompleted(reviewedCount: Int, duration: TimeInterval) {
        track(AnalyticsEventName.reviewCompleted, parameters: [
            "reviewed_count": String(reviewedCount),
            "duration_seconds": String(Int(duration))
        ])
    }
    
    func trackReviewItemMarked(mastery: String) {
        track(AnalyticsEventName.reviewItemMarked, parameters: ["mastery": mastery])
    }
    
    // MARK: - 题库事件
    
    func trackLibrarySearched(query: String, resultCount: Int) {
        track(AnalyticsEventName.librarySearched, parameters: [
            "query_length": String(query.count),
            "result_count": String(resultCount)
        ])
    }
    
    func trackLibraryFiltered(subject: String?, mastery: String?) {
        var params: [String: String] = [:]
        if let subject = subject { params["subject"] = subject }
        if let mastery = mastery { params["mastery"] = mastery }
        track(AnalyticsEventName.libraryFiltered, parameters: params)
    }
    
    // MARK: - 导出事件
    
    func trackExportPDF(itemCount: Int) {
        track(AnalyticsEventName.exportPDF, parameters: ["item_count": String(itemCount)])
    }
}
