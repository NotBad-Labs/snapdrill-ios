//
//  CrashReportingServiceMock.swift
//  SnapDrillCore
//
//  Created by SnapDrill Labs on 2026/02/24.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//

import Foundation

/// 崩溃报告服务 Mock 实现，用于单元测试
@MainActor
public final class CrashReportingServiceMock: CrashReportingProtocol, @unchecked Sendable {
    
    // MARK: - 记录属性
    
    public private(set) var recordedErrors: [(error: Error, context: [String: String])] = []
    public private(set) var loggedMessages: [(message: String, level: LogLevel)] = []
    public private(set) var userIdentifier: String?
    public private(set) var customValues: [String: String] = [:]
    public private(set) var breadcrumbs: [(message: String, metadata: [String: String])] = []
    
    // 线程安全保护
    private let lock = NSLock()
    
    public init() {}
    
    // MARK: - CrashReportingProtocol
    
    public func recordError(_ error: Error, context: [String: String]) {
        lock.lock()
        defer { lock.unlock() }
        recordedErrors.append((error, context))
    }
    
    public func log(_ message: String, level: LogLevel) {
        lock.lock()
        defer { lock.unlock() }
        loggedMessages.append((message, level))
    }
    
    public func setUserIdentifier(_ identifier: String) {
        lock.lock()
        defer { lock.unlock() }
        userIdentifier = identifier
    }
    
    public func setCustomValue(_ value: String, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        customValues[key] = value
    }
    
    public func leaveBreadcrumb(_ message: String, metadata: [String: String]) {
        lock.lock()
        defer { lock.unlock() }
        breadcrumbs.append((message, metadata))
    }
    
    // MARK: - 断言辅助方法
    
    public func hasRecordedError() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return !recordedErrors.isEmpty
    }
    
    public func hasLoggedMessage(containing text: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return loggedMessages.contains { $0.message.contains(text) }
    }
    
    public func hasBreadcrumb(containing text: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return breadcrumbs.contains { $0.message.contains(text) }
    }
    
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        recordedErrors.removeAll()
        loggedMessages.removeAll()
        userIdentifier = nil
        customValues.removeAll()
        breadcrumbs.removeAll()
    }
}
