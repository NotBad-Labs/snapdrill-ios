//
//  AnalyticsServiceMock.swift
//  SnapDrillCore
//
//  Created by SnapDrill Labs on 2026/02/24.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//

import Foundation

/// 统计分析服务 Mock 实现，用于单元测试
@MainActor
public final class AnalyticsServiceMock: AnalyticsServiceProtocol, @unchecked Sendable {
    
    // MARK: - 记录属性
    
    public private(set) var trackedEvents: [(event: AnalyticsEvent, parameters: [String: String])] = []
    public private(set) var trackedScreens: [(screen: String, parameters: [String: String])] = []
    public private(set) var sessionStartCount = 0
    public private(set) var sessionEndCount = 0
    public private(set) var userProperties: [String: String] = [:]
    public private(set) var retentionTracking: [Int] = []
    
    // 线程安全保护
    private let lock = NSLock()
    
    public init() {}
    
    // MARK: - AnalyticsServiceProtocol
    
    public func track(_ event: AnalyticsEvent, parameters: [String: String]) {
        lock.lock()
        defer { lock.unlock() }
        trackedEvents.append((event, parameters))
    }
    
    public func trackScreen(_ screenName: String, parameters: [String: String]) {
        lock.lock()
        defer { lock.unlock() }
        trackedScreens.append((screenName, parameters))
    }
    
    public func startSession() {
        lock.lock()
        defer { lock.unlock() }
        sessionStartCount += 1
    }
    
    public func endSession() {
        lock.lock()
        defer { lock.unlock() }
        sessionEndCount += 1
    }
    
    public func setUserProperty(_ value: String, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        userProperties[key] = value
    }
    
    public func trackRetention(daysSinceInstall: Int) {
        lock.lock()
        defer { lock.unlock() }
        retentionTracking.append(daysSinceInstall)
    }
    
    // MARK: - 断言辅助方法
    
    public func hasTrackedEvent(_ event: AnalyticsEvent) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return trackedEvents.contains { $0.event == event }
    }
    
    public func hasTrackedScreen(_ screenName: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return trackedScreens.contains { $0.screen == screenName }
    }
    
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        trackedEvents.removeAll()
        trackedScreens.removeAll()
        sessionStartCount = 0
        sessionEndCount = 0
        userProperties.removeAll()
        retentionTracking.removeAll()
    }
}
