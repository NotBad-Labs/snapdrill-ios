//
//  NoOpAnalyticsService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  生产级空实现分析服务，用于国内版 Firebase-Free 构建（ADR-004）。
//

import Foundation

/// 生产级无操作分析服务
///
/// 符合 `AnalyticsServiceProtocol`，所有方法为空实现：不采集、不上报、不发起任何网络请求。
/// 国内版（ADR-004）在 App 层注入本类替代 `FirebaseAnalyticsService`，从而不调用
/// `FirebaseApp.configure()`，根除 opt-in 前 Crashlytics settings 拉取造成的跨境出境。
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
