//
//  SnapDrillLogger.swift
//  SnapDrillCore
//
//  Created by SnapDrill Labs on 2025/12/31.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  统一日志管理中心，负责应用内所有日志的记录和分级。
//

import Foundation
import OSLog

/// 统一日志管理中心
///
/// 使用 Apple 推荐的 `OSLog` (Unified Logging System) 进行高性能日志记录。
/// 自动区分 Subsystem 和 Category，便于在控制台筛选。
@available(iOS 14.0, macOS 11.0, *)
public struct SnapDrillLogger {
    /// 通用系统日志
    public static let generic = Logger(subsystem: "com.snapdrill.app", category: "Generic")
    
    /// 用户界面与交互日志
    public static let ui = Logger(subsystem: "com.snapdrill.app", category: "UI")
    
    /// 数据库与持久化日志
    public static let data = Logger(subsystem: "com.snapdrill.app", category: "Data")
    
    /// 网络请求与监控日志
    public static let network = Logger(subsystem: "com.snapdrill.app", category: "Network")
    
    /// 核心业务引擎与调度逻辑日志
    public static let engine = Logger(subsystem: "com.snapdrill.app", category: "Engine")
    
    /// 图片采集与 OCR 识别日志
    public static let capture = Logger(subsystem: "com.snapdrill.app", category: "Capture")
}
