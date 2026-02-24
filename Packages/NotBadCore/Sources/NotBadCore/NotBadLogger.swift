//
//  NotBadLogger.swift
//  NotBadCore
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  统一日志管理中心，负责应用内所有日志的记录和分级。
//

import Foundation
import OSLog

/// 统一日志管理中心
///
/// 使用 Apple 推荐的 `OSLog` (Unified Logging System) 进行高性能日志记录。
/// 自动区分 Subsystem 和 Category，便于在控制台筛选。
public struct NotBadLogger {
    /// 通用日志
    public static let generic = Logger(subsystem: "com.notbad.app", category: "Generic")
    
    /// UI 层日志
    public static let ui = Logger(subsystem: "com.notbad.app", category: "UI")
    
    /// 数据层日志
    public static let data = Logger(subsystem: "com.notbad.app", category: "Data")
    
    /// 网络层日志
    public static let network = Logger(subsystem: "com.notbad.app", category: "Network")
    
    /// 业务逻辑日志 (Engine)
    public static let engine = Logger(subsystem: "com.notbad.app", category: "Engine")
    
    /// 采集功能日志
    public static let capture = Logger(subsystem: "com.notbad.app", category: "Capture")
}
