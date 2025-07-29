// Infrastructure/Logger/Logger.swift
import Foundation
import OSLog

/// 简化的日志系统。
/// 实际项目中应包含更完善的日志级别和分类。
final class Logger {
    static let shared = Logger() // 单例访问
    private var currentLevel: LogLevel = .debug // 默认日志级别

    /// 设置日志级别。
    /// - Parameter level: 要设置的日志级别。
    func setLevel(_ level: LogLevel) {
        self.currentLevel = level
    }

    /// 记录调试信息。
    func debug(_ message: String, category: LogCategory) {
        if currentLevel.rawValue <= LogLevel.debug.rawValue {
            os_log(.debug, log: category.osLog, "%{public}@", message)
        }
    }

    /// 记录信息。
    func info(_ message: String, category: LogCategory) {
        if currentLevel.rawValue <= LogLevel.info.rawValue {
            os_log(.info, log: category.osLog, "%{public}@", message)
        }
    }

    /// 记录警告信息。
    func warning(_ message: String, category: LogCategory) {
        if currentLevel.rawValue <= LogLevel.warning.rawValue {
            os_log(.error, log: category.osLog, "%{public}@", message) // 警告级别也用 error 类型，便于在控制台区分
        }
    }

    /// 记录错误信息。
    func error(_ message: String, category: LogCategory, error: Error? = nil) {
        if currentLevel.rawValue <= LogLevel.error.rawValue {
            os_log(.error, log: category.osLog, "%{public}@", "\(message) - \(error?.localizedDescription ?? "未知错误")")
        }
    }
}

/// 日志级别枚举。
enum LogLevel: Int, Sendable {
    case debug, info, warning, error
}

/// 日志分类枚举。
enum LogCategory: Sendable {
    case app, ui, business, data, network, security, general

    /// 对应的 OSLog 对象。
    var osLog: OSLog {
        switch self {
        case .app: return OSLog(subsystem: "com.notbad.app", category: "App")
        case .ui: return OSLog(subsystem: "com.notbad.app", category: "UI")
        case .business: return OSLog(subsystem: "com.notbad.app", category: "BusinessLogic")
        case .data: return OSLog(subsystem: "com.notbad.app", category: "DataAccess")
        case .network: return OSLog(subsystem: "com.notbad.app", category: "Network")
        case .security: return OSLog(subsystem: "com.notbad.app", category: "Security")
        case .general: return OSLog(subsystem: "com.notbad.app", category: "General")
        }
    }
}