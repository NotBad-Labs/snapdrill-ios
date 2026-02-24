//
//  NBLogger.swift
//  NotBadSupport
//
//  Created by NotBad Labs on 2025/12/30.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  [Legacy] 旧版日志记录器，请迁移至 NotBadLogger。
//

import Foundation
import OSLog

/// 统一日志记录器
///
/// 封装 OSLog，提供分级的日志记录功能。
public struct NBLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.notbad.app"
    
    /// 记录信息日志
    public static func info(_ message: String, category: String = "General") {
        let logger = Logger(subsystem: subsystem, category: category)
        logger.info("\(message)")
    }
    
    /// 记录错误日志
    public static func error(_ message: String, category: String = "General") {
        let logger = Logger(subsystem: subsystem, category: category)
        logger.error("\(message)")
    }
    
    /// 记录调试日志
    public static func debug(_ message: String, category: String = "General") {
        #if DEBUG
        let logger = Logger(subsystem: subsystem, category: category)
        logger.debug("\(message)")
        #endif
    }
}
