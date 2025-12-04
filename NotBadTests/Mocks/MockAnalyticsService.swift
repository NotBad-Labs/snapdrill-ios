//
//  MockAnalyticsService.swift
//  NotBad
//
//  Mock 埋点服务，用于测试
//

import Foundation

// MARK: - Mock Analytics Service

/// Mock 埋点服务
/// 用于单元测试，记录所有事件供验证
@MainActor
public final class MockAnalyticsService: AnalyticsServiceProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    
    /// 已记录的事件
    public private(set) var trackedEvents: [AnalyticsEvent] = []
    
    /// 用户属性
    public private(set) var userProperties: [String: String] = [:]
    
    /// 用户 ID
    public private(set) var userId: String?
    
    // MARK: - Init
    
    public init() {}
    
    // MARK: - AnalyticsServiceProtocol
    
    public func track(_ event: AnalyticsEvent) {
        trackedEvents.append(event)
    }
    
    public func setUserProperty(_ value: String, forName name: String) {
        userProperties[name] = value
    }
    
    public func setUserId(_ userId: String?) {
        self.userId = userId
    }
    
    // MARK: - Test Helpers
    
    /// 重置所有记录
    public func reset() {
        trackedEvents.removeAll()
        userProperties.removeAll()
        userId = nil
    }
    
    /// 检查是否记录了指定事件
    public func hasTracked(_ eventName: String) -> Bool {
        trackedEvents.contains { $0.name == eventName }
    }
    
    /// 获取指定事件的所有记录
    public func events(named: String) -> [AnalyticsEvent] {
        trackedEvents.filter { $0.name == named }
    }
    
    /// 最后一个事件
    public var lastEvent: AnalyticsEvent? {
        trackedEvents.last
    }
}
