//
//  PerformanceMonitoringExtensions.swift
//  SnapDrillCore
//
//  Created by SnapDrill Labs on 2026/01/03.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  性能监控扩展和辅助方法
//

import Foundation

/// 性能监控扩展
extension PerformanceMonitor {
    /// 监控操作并与服务集成
    public func measureWithIntegration<T>(
        operation: String,
        threshold: TimeInterval = 1.0,
        metadata: [String: String] = [:],
        _ block: () async throws -> T
    ) async rethrows -> T {
        let startTime = Date()
        let result = try await measure(operation, metadata: metadata, block)
        let duration = Date().timeIntervalSince(startTime)
        
        // 如果超过阈值，记录到其他服务
        if duration > threshold {
            Task { @MainActor in
                CrashReportingService.shared.leaveBreadcrumb(
                    "Slow operation: \(operation)",
                    metadata: [
                        "duration": "\(duration)",
                        "threshold": "\(threshold)"
                    ]
                )
                
                AnalyticsTrackingService.shared.track(.appLaunched, parameters: [
                    "performance_operation": operation,
                    "duration": "\(duration)",
                    "is_slow": "true"
                ])
            }
        }
        
        return result
    }
}

/// 性能监控辅助函数
public enum PerformanceHelper {
    /// 测量 OCR 操作性能
    public static func measureOCR<T: Sendable>(_ block: @Sendable () async throws -> T) async rethrows -> T {
        try await PerformanceMonitor.shared.measure("OCR.Recognition", block)
    }
    
    /// 测量 PDF 导出性能
    public static func measurePDFExport<T: Sendable>(_ block: @Sendable () async throws -> T) async rethrows -> T {
        try await PerformanceMonitor.shared.measure("Export.PDF", block)
    }
    
    /// 测量数据导出性能
    public static func measureDataExport<T: Sendable>(_ block: @Sendable () async throws -> T) async rethrows -> T {
        try await PerformanceMonitor.shared.measure("Export.Data", block)
    }
    
    /// 测量 iCloud 同步性能
    public static func measureCloudSync<T: Sendable>(_ block: @Sendable () async throws -> T) async rethrows -> T {
        try await PerformanceMonitor.shared.measure("CloudKit.Sync", block)
    }
}
