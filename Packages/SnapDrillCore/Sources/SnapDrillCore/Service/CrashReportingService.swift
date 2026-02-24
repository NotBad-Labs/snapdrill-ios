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
import FirebaseCrashlytics

/// 崩溃报告服务
///
/// 提供应用级别的错误追踪和崩溃报告功能。
@MainActor
public final class CrashReportingService: CrashReportingProtocol {
    public static let shared = CrashReportingService()
    
    private let logger = Logger(subsystem: "com.snapdrill.app", category: "CrashReporting")
    private var isEnabled: Bool
    private var isFirebaseConfigured: Bool = false
    
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
    
    /// 标记 Firebase 已配置完毕（由 SnapDrillApp 在 FirebaseApp.configure() 后调用）
    public func markConfigured() {
        isFirebaseConfigured = true
        logger.info("✅ Firebase Crashlytics tracking ready")
    }
    
    /// 启用或禁用崩溃报告
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "crashReportingEnabled")
        logger.info("Crash reporting \(enabled ? "enabled" : "disabled")")
    }
    
    /// 记录非致命错误
    public func recordError(_ error: Error, context: [String: String] = [:]) {
        guard isEnabled else { return }
        
        logger.error("Error recorded: \(error.localizedDescription)")
        
        if isFirebaseConfigured {
            Crashlytics.crashlytics().record(error: error, userInfo: context)
        }
        
        // 保存到本地日志文件作为备份
        saveToLocalLog(error: error, context: context)
    }
    
    /// 记录自定义日志
    public func log(_ message: String, level: LogLevel = .info) {
        guard isEnabled else { return }
        
        if isFirebaseConfigured {
            Crashlytics.crashlytics().log(message)
        }
        
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
    
    /// 设置用户标识符
    public func setUserIdentifier(_ identifier: String) {
        guard isEnabled else { return }
        
        if isFirebaseConfigured {
            Crashlytics.crashlytics().setUserID(identifier)
        }
        
        logger.info("User identifier set: \(identifier)")
        UserDefaults.standard.set(identifier, forKey: "crashReportingUserID")
    }
    
    /// 设置自定义键值对
    public func setCustomValue(_ value: String, forKey key: String) {
        guard isEnabled else { return }
        
        if isFirebaseConfigured {
            Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        }
        
        logger.debug("Custom value set - \(key): \(value)")
    }
    
    /// 记录面包屑
    public func leaveBreadcrumb(_ message: String, metadata: [String: String] = [:]) {
        guard isEnabled else { return }
        
        if isFirebaseConfigured {
            let breadcrumb = metadata.isEmpty ? message : "\(message) | \(metadata)"
            Crashlytics.crashlytics().log(breadcrumb)
        }
        
        logger.debug("Breadcrumb: \(message)")
    }
    
    // MARK: - Private Methods
    
    private func setupExceptionHandler() {
        // ⚠️ 重要：NSSetUncaughtExceptionHandler 在崩溃信号线程同步调用。
        // 此处绝对不能使用 async/await 或 DispatchQueue.main.async，
        // 因为崩溃时主队列极大概率已死锁，异步 Task 永远不会被执行。
        // 正确做法：在 handler 内直接进行信号安全的同步操作（os_log 是信号安全的）。
        NSSetUncaughtExceptionHandler { exception in
            // 直接使用 os_log C 接口（信号安全），不经过任何 actor/dispatch
            let reason = exception.reason ?? "Unknown reason"
            let name = exception.name.rawValue
            let symbols = exception.callStackSymbols.prefix(10).joined(separator: "\n")

            // os_log 是异步写日志缓冲区，崩溃时内核会 flush，属于信号安全操作
            os_log(
                .fault,
                dso: #dsohandle,
                log: OSLog(subsystem: "com.snapdrill.app", category: "UncaughtException"),
                "UncaughtException [%{public}@]: %{public}@\nCallStack:\n%{public}@",
                name, reason, symbols
            )
        }
    }
    
    private func saveToLocalLog(error: Error, context: [String: String]) {
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
