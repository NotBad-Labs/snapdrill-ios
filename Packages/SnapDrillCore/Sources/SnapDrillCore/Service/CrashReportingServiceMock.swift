//
//  CrashReportingServiceMock.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  崩溃报告服务测试替身，用于单元测试环境。
//

import Foundation

/// 崩溃报告服务 Mock 实现，用于单元测试
@MainActor
public final class CrashReportingServiceMock: CrashReportingProtocol {

    // MARK: - 记录属性

    public private(set) var recordedErrors: [(error: Error, context: [String: String])] = []
    public private(set) var loggedMessages: [(message: String, level: LogLevel)] = []
    public private(set) var userIdentifier: String?
    public private(set) var customValues: [String: String] = [:]
    public private(set) var breadcrumbs: [(message: String, metadata: [String: String])] = []

    public init() {}

    // MARK: - CrashReportingProtocol

    public func recordError(_ error: Error, context: [String: String]) {
        recordedErrors.append((error, context))
    }

    public func log(_ message: String, level: LogLevel) {
        loggedMessages.append((message, level))
    }

    public func setUserIdentifier(_ identifier: String) {
        userIdentifier = identifier
    }

    public func setCustomValue(_ value: String, forKey key: String) {
        customValues[key] = value
    }

    public func leaveBreadcrumb(_ message: String, metadata: [String: String]) {
        breadcrumbs.append((message, metadata))
    }

    // MARK: - 断言辅助方法

    public func hasRecordedError() -> Bool {
        !recordedErrors.isEmpty
    }

    public func hasLoggedMessage(containing text: String) -> Bool {
        loggedMessages.contains { $0.message.contains(text) }
    }

    public func hasBreadcrumb(containing text: String) -> Bool {
        breadcrumbs.contains { $0.message.contains(text) }
    }

    public func clear() {
        recordedErrors.removeAll()
        loggedMessages.removeAll()
        userIdentifier = nil
        customValues.removeAll()
        breadcrumbs.removeAll()
    }
}
