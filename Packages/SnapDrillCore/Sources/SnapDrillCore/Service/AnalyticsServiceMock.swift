//
//  AnalyticsServiceMock.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  统计分析服务 Mock 实现，用于单元测试和 SwiftUI Preview。
//

import Foundation

/// 统计分析服务 Mock 实现，用于单元测试
///
/// 由于类标注了 `@MainActor`，所有方法均在主线程执行，无需额外的锁保护。
public final class AnalyticsServiceMock: AnalyticsServiceProtocol {

    // MARK: - 记录属性

    public private(set) var trackedEvents: [(event: AnalyticsEvent, parameters: [String: String])] = []
    public private(set) var trackedScreens: [(screen: String, parameters: [String: String])] = []
    public private(set) var sessionStartCount = 0
    public private(set) var sessionEndCount = 0
    public private(set) var userProperties: [String: String] = [:]
    public private(set) var retentionTracking: [Int] = []

    /// 创建空的分析服务 Mock 实例
    public init() {}

    // MARK: - AnalyticsServiceProtocol

    public func track(_ event: AnalyticsEvent, parameters: [String: String]) {
        trackedEvents.append((event, parameters))
    }

    public func trackScreen(_ screenName: String, parameters: [String: String]) {
        trackedScreens.append((screenName, parameters))
    }

    public func startSession() {
        sessionStartCount += 1
    }

    public func endSession() {
        sessionEndCount += 1
    }

    public func setUserProperty(_ value: String, forKey key: String) {
        userProperties[key] = value
    }

    public func trackRetention(daysSinceInstall: Int) {
        retentionTracking.append(daysSinceInstall)
    }

    // MARK: - 断言辅助方法

    public func hasTrackedEvent(_ event: AnalyticsEvent) -> Bool {
        trackedEvents.contains { $0.event == event }
    }

    public func hasTrackedScreen(_ screenName: String) -> Bool {
        trackedScreens.contains { $0.screen == screenName }
    }

    public func clear() {
        trackedEvents.removeAll()
        trackedScreens.removeAll()
        sessionStartCount = 0
        sessionEndCount = 0
        userProperties.removeAll()
        retentionTracking.removeAll()
    }
}
