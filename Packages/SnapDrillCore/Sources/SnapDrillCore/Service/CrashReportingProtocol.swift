//
//  CrashReportingProtocol.swift
//  SnapDrillCore
//
//  Created by SnapDrill Labs on 2026/02/24.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//

import Foundation

/// 崩溃报告服务协议
///
/// 抽象崩溃报告和错误追踪的实现
@MainActor
public protocol CrashReportingProtocol: Sendable {
    /// 记录非致命错误
    func recordError(_ error: Error, context: [String: String])
    
    /// 记录自定义日志
    func log(_ message: String, level: LogLevel)
    
    /// 设置用户标识符（用于追踪特定用户的问题）
    func setUserIdentifier(_ identifier: String)
    
    /// 设置自定义键值对
    func setCustomValue(_ value: String, forKey key: String)
    
    /// 记录面包屑（用户操作轨迹）
    func leaveBreadcrumb(_ message: String, metadata: [String: String])
}
