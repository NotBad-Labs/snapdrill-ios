//
//  NoOpAnalyticsService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  全球生产基线使用的无操作分析服务（ADR-005）。
//

import Foundation

/// 生产级无操作分析服务
///
/// 符合 `AnalyticsServiceProtocol`，所有方法为空实现：不采集、不上报、不发起任何网络请求。
/// 全球生产构建在 App 组合根注入本类；Firebase SDK 与对应基础设施已经删除。
///
/// 与测试用的 `AnalyticsServiceMock` 区别：本类不记录任何状态，是生产环境的真实空实现。
public final class NoOpAnalyticsService: AnalyticsServiceProtocol {

    public init() {}

    public func track(_ event: AnalyticsEvent, parameters: [String: String]) {}

    public func trackScreen(_ screenName: String, parameters: [String: String]) {}

    public func startSession() {}

    public func endSession() {}

    public func setUserProperty(_ value: String, forKey key: String) {}

    public func trackRetention(daysSinceInstall: Int) {}
}
