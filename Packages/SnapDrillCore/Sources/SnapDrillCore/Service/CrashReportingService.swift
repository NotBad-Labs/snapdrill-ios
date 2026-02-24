//
//  CrashReportingService.swift
//  SnapDrillCore
//
//  Created by SnapDrill Labs on 2026/01/03.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  崩溃报告和错误追踪服务
//

import Foundation
import OSLog

/// 崩溃报告服务
///
/// 提供应用级别的错误追踪和崩溃报告功能。
/// 在生产环境中，可以集成 Firebase Crashlytics 或 Sentry。
@MainActor
public final class CrashReportingService: @unchecked Sendable {
    public static let shared = CrashReportingService()
    
    private let logger = Logger(subsystem: "com.LIAOYIMING.SnapDrill", category: "CrashReporting")
    private var isEnabled: Bool
    
    private init() {
        // 从 UserDefaults 读取设置
        self.isEnabled = UserDefaults.standard.bool(forKey: "crashReportingEnabled")
        
        // 默认启用
        if !UserDefaults.standard.bool(forKey: "crashReportingConfigured") {
            self.isEnabled = true
            UserDefaults.standard.set(true, forKey: "crashReportingEnabled")
            UserDefaults.standard.set(true, forKey: "crashReportingConfigured")
        }
        
        setupExceptionHandler()
    }
    
    /// 启用或禁用崩溃报告
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "crashReportingEnabled")
        logger.info("Crash reporting \(enabled ? "enabled" : "disabled")")
    }
    
    /// 记录非致命错误
    public func recordError(_ error: Error, context: [String: Any] = [:]) {
        guard isEnabled else { return }
        
        logger.error("Error recorded: \(error.localizedDescription)")
        
        // 记录上下文信息
        for (key, value) in context {
            logger.debug("Context - \(key): \(String(describing: value))")
        }
        
        // 在生产环境中，这里应该发送到远程服务器
        // 例如: Crashlytics.crashlytics().record(error: error)
        
        // 保存到本地日志文件
        saveToLocalLog(error: error, context: context)
    }
    
    /// 记录自定义日志
    public func log(_ message: String, level: LogLevel = .info) {
        guard isEnabled else { return }
        
        switch level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        case .critical:
            logger.critical("\(message)")
        }
    }
    
    /// 设置用户标识符（用于追踪特定用户的问题）
    public func setUserIdentifier(_ identifier: String) {
        guard isEnabled else { return }
        logger.info("User identifier set: \(identifier)")
        UserDefaults.standard.set(identifier, forKey: "crashReportingUserID")
    }
    
    /// 设置自定义键值对
    public func setCustomValue(_ value: String, forKey key: String) {
        guard isEnabled else { return }
        logger.debug("Custom value set - \(key): \(value)")
    }
    
    /// 记录面包屑（用户操作轨迹）
    public func leaveBreadcrumb(_ message: String, metadata: [String: Any] = [:]) {
        guard isEnabled else { return }
        logger.debug("Breadcrumb: \(message)")
        
        for (key, value) in metadata {
            logger.debug("  \(key): \(String(describing: value))")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupExceptionHandler() {
        NSSetUncaughtExceptionHandler { exception in
            Task { @MainActor in
                let error = NSError(
                    domain: "UncaughtException",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: exception.reason ?? "Unknown exception",
                        "callStackSymbols": exception.callStackSymbols
                    ]
                )
                CrashReportingService.shared.recordError(error, context: [
                    "exception": exception.name.rawValue,
                    "reason": exception.reason ?? "Unknown"
                ])
            }
        }
    }
    
    private func saveToLocalLog(error: Error, context: [String: Any]) {
        let logEntry: [String: Any] = [
            "timestamp": Date().ISO8601Format(),
            "error": error.localizedDescription,
            "context": context,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "osVersion": ProcessInfo.processInfo.operatingSystemVersionString
        ]
        
        // 保存到文件
        if let logData = try? JSONSerialization.data(withJSONObject: logEntry, options: .prettyPrinted) {
            let logsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Logs", isDirectory: true)
            
            try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
            
            let logFile = logsDirectory.appendingPathComponent("crash_log_\(Date().timeIntervalSince1970).json")
            try? logData.write(to: logFile)
        }
    }
}

/// 日志级别
public enum LogLevel {
    case debug
    case info
    case warning
    case error
    case critical
}
