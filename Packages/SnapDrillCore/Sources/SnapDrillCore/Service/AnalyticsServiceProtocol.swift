//
//  AnalyticsServiceProtocol.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  分析服务协议，定义事件追踪的最小契约。
//

import Foundation

/// 分析服务协议
///
/// 抽象用户行为分析和功能使用追踪的实现。支持追踪自定义事件、屏幕流量以及用户会话生命周期。
@MainActor
public protocol AnalyticsServiceProtocol: Sendable {
    /// 追踪事件
    func track(_ event: AnalyticsEvent, parameters: [String: String])
    
    /// 追踪屏幕浏览
    func trackScreen(_ screenName: String, parameters: [String: String])
    
    /// 开始会话追踪
    func startSession()
    
    /// 结束会话追踪
    func endSession()
    
    /// 设置用户属性
    func setUserProperty(_ value: String, forKey key: String)
    
    /// 追踪用户留存
    func trackRetention(daysSinceInstall: Int)
}
