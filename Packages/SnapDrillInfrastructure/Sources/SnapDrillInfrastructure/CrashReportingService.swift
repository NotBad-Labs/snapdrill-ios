//
//  CrashReportingService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/01/03.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  崩溃报告和错误追踪服务
//

import Foundation
import OSLog
import FirebaseCrashlytics
import SnapDrillCore

// MARK: - 本地崩溃日志数据结构

/// 本地崩溃日志条目（强类型 Codable，替代 [String: Any]）
private struct LocalCrashLogEntry: Codable {
    let timestamp: String
    let error: String
    let context: [String: String]
    let appVersion: String
    let osVersion: String
}

/// 崩溃报告服务
///
/// 提供应用级别的错误追踪和崩溃报告功能。
@MainActor
public final class CrashReportingService: CrashReportingProtocol {
    
    // MARK: - Properties
    
    /// 共享实例 - 建议使用 ServiceContainer 注入
    public static let shared = CrashReportingService()
    
    // 崩溃信号安全专用：OSLog 静态实例避免崩溃时动态分配内存
    private static let crashLog = OSLog(subsystem: "com.snapdrill.app", category: "UncaughtException")
    private var isEnabled: Bool
    private var isFirebaseConfigured: Bool = false
    
    // MARK: - Initialization
    
    public init() {
        // 从 UserDefaults 读取设置
        self.isEnabled = UserDefaults.standard.bool(forKey: UDKey.crashReportingEnabled)

        // 默认启用
        if !UserDefaults.standard.bool(forKey: UDKey.crashReportingConfigured) {
            self.isEnabled = true
            UserDefaults.standard.set(true, forKey: UDKey.crashReportingEnabled)
            UserDefaults.standard.set(true, forKey: UDKey.crashReportingConfigured)
        }
        
        setupExceptionHandler()
    }
    
    // MARK: - Public API
    
    /// 标记 Firebase 已配置完毕（由 SnapDrillApp 在 FirebaseApp.configure() 后调用）
    public func markConfigured() {
        isFirebaseConfigured = true
        SnapDrillLogger.generic.info("Firebase Crashlytics tracking ready")
    }
    
    /// 启用或禁用崩溃报告
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: UDKey.crashReportingEnabled)
        SnapDrillLogger.generic.info("Crash reporting \(enabled ? "enabled" : "disabled")")
    }
    
    /// 记录非致命错误
    public func recordError(_ error: Error, context: [String: String] = [:]) {
        guard isEnabled else { return }
        
        SnapDrillLogger.generic.error("Error recorded: \(error.localizedDescription)")
        
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
            SnapDrillLogger.generic.debug("\(message)")
        case .info:
            SnapDrillLogger.generic.info("\(message)")
        case .warning:
            SnapDrillLogger.generic.warning("\(message)")
        case .error:
            SnapDrillLogger.generic.error("\(message)")
        case .critical:
            SnapDrillLogger.generic.critical("\(message)")
        }
    }
    
    /// 设置用户标识符
    public func setUserIdentifier(_ identifier: String) {
        guard isEnabled else { return }
        
        if isFirebaseConfigured {
            Crashlytics.crashlytics().setUserID(identifier)
        }
        
        SnapDrillLogger.generic.info("User identifier set and secured in Keychain")
        Task {
            await KeychainService.shared.save(identifier, forKey: UDKey.crashReportingUserID)
        }
        
        // 清理旧的明文存储（如果存在）
        UserDefaults.standard.removeObject(forKey: UDKey.crashReportingUserID)
    }
    
    /// 设置自定义键值对
    public func setCustomValue(_ value: String, forKey key: String) {
        guard isEnabled else { return }
        
        if isFirebaseConfigured {
            Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        }
        
        SnapDrillLogger.generic.debug("Custom value set - \(key): \(value)")
    }
    
    /// 记录面包屑
    public func leaveBreadcrumb(_ message: String, metadata: [String: String] = [:]) {
        guard isEnabled else { return }
        
        if isFirebaseConfigured {
            let breadcrumb = metadata.isEmpty ? message : "\(message) | \(metadata)"
            Crashlytics.crashlytics().log(breadcrumb)
        }
        
        SnapDrillLogger.generic.debug("Breadcrumb: \(message)")
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
            // 使用预分配的静态 OSLog 实例，避免崩溃时动态内存分配
            os_log(
                .fault,
                dso: #dsohandle,
                log: CrashReportingService.crashLog,
                "UncaughtException [%{public}@]: %{public}@\nCallStack:\n%{public}@",
                name, reason, symbols
            )
        }
    }
    
    private func saveToLocalLog(error: Error, context: [String: String]) {
        // 使用强类型 Codable 结构体替代 [String: Any]，消除 Any existential 违规
        let entry = LocalCrashLogEntry(
            timestamp: Date().ISO8601Format(),
            error: error.localizedDescription,
            context: context,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let logData = try encoder.encode(entry)
            // 使用 Library/Application Support 而非 Documents：
            // 日志属于内部数据，不应暴露给用户或被 iCloud 备份
            let logsDirectory = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("SnapDrill/Logs", isDirectory: true)

            try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)

            // 清理 7 天前的旧日志，防止无限累积
            pruneOldLogs(in: logsDirectory, olderThan: 7)

            let logFile = logsDirectory.appendingPathComponent("crash_log_\(Date().timeIntervalSince1970).json")
            try logData.write(to: logFile)
        } catch {
            SnapDrillLogger.generic.error("本地崩溃日志写入失败: \(error.localizedDescription)")
        }
    }

    /// 删除目录中超过指定天数的 JSON 日志文件
    private func pruneOldLogs(in directory: URL, olderThan days: Int) {
        let cutoff = Date().addingTimeInterval(-Double(days) * 86_400)
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        for file in files where file.pathExtension == "json" {
            let created = (try? file.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
            if created < cutoff {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}

// LogLevel 已移至 SnapDrillCore/CrashReportingProtocol.swift
