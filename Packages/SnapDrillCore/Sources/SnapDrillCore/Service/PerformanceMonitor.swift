//
//  PerformanceMonitor.swift
//  SnapDrillCore
//
//  Created by SnapDrill Labs on 2026/01/02.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  性能监控服务，用于追踪关键操作的性能指标
//

import Foundation
import OSLog

/// 性能监控服务
///
/// 用于监控和记录应用关键操作的性能指标。
/// 使用 `os_signpost` 进行高性能追踪。
public actor PerformanceMonitor {
    /// 共享实例 - 建议使用 ServiceContainer 注入
    public static let shared = PerformanceMonitor()
    
    private let logger = Logger(subsystem: "com.snapdrill.app", category: "Performance")
    
    /// 性能指标
    public struct Metric: Sendable {
        public let operation: String
        public let duration: TimeInterval
        public let timestamp: Date
        public let metadata: [String: String]
        
        public init(operation: String, duration: TimeInterval, timestamp: Date = Date(), metadata: [String: String] = [:]) {
            self.operation = operation
            self.duration = duration
            self.timestamp = timestamp
            self.metadata = metadata
        }
    }
    
    /// 存储的性能指标（最多保留 100 条）
    private var metrics: [Metric] = []
    private let maxMetrics = 100
    
    public init() {}
    
    /// 测量操作性能
    ///
    /// - Parameters:
    ///   - operation: 操作名称
    ///   - metadata: 额外元数据
    ///   - block: 要测量的操作
    /// - Returns: 操作的返回值
    public func measure<T>(
        _ operation: String,
        metadata: [String: String] = [:],
        _ block: () async throws -> T
    ) async rethrows -> T {
        let startTime = Date()
        // 先执行目标操作
        let result = try await block()
        // 操作完成后，在 actor 上下文内直接记录（无需额外 Task，已在 actor 内部）
        let duration = Date().timeIntervalSince(startTime)
        recordMetric(Metric(operation: operation, duration: duration, metadata: metadata))
        return result
    }
    
    /// 记录性能指标
    private func recordMetric(_ metric: Metric) {
        metrics.append(metric)
        
        // 保持最多 maxMetrics 条记录
        if metrics.count > maxMetrics {
            metrics.removeFirst(metrics.count - maxMetrics)
        }
        
        // 记录到日志
        if metric.duration > 1.0 {
            logger.warning("⚠️ Slow operation: \(metric.operation) took \(String(format: "%.2f", metric.duration))s")
        } else if metric.duration > 0.5 {
            logger.info("Operation: \(metric.operation) took \(String(format: "%.2f", metric.duration))s")
        }
    }
    
    /// 获取所有性能指标
    public func getMetrics() -> [Metric] {
        return metrics
    }
    
    /// 获取特定操作的平均耗时
    public func getAverageDuration(for operation: String) -> TimeInterval? {
        let operationMetrics = metrics.filter { $0.operation == operation }
        guard !operationMetrics.isEmpty else { return nil }
        
        let total = operationMetrics.reduce(0.0) { $0 + $1.duration }
        return total / Double(operationMetrics.count)
    }
    
    /// 获取性能报告
    public func getPerformanceReport() -> String {
        guard !metrics.isEmpty else {
            return "No performance data available"
        }
        
        var report = "Performance Report\n"
        report += "==================\n\n"
        
        // 按操作分组
        let grouped = Dictionary(grouping: metrics) { $0.operation }
        
        for (operation, operationMetrics) in grouped.sorted(by: { $0.key < $1.key }) {
            let avg = operationMetrics.reduce(0.0) { $0 + $1.duration } / Double(operationMetrics.count)
            let max = operationMetrics.map { $0.duration }.max() ?? 0
            let min = operationMetrics.map { $0.duration }.min() ?? 0
            
            report += "\(operation):\n"
            report += "  Count: \(operationMetrics.count)\n"
            report += "  Avg: \(String(format: "%.3f", avg))s\n"
            report += "  Min: \(String(format: "%.3f", min))s\n"
            report += "  Max: \(String(format: "%.3f", max))s\n\n"
        }
        
        return report
    }
    
    /// 清除所有性能指标
    public func clearMetrics() {
        metrics.removeAll()
        logger.info("Performance metrics cleared")
    }
}

// MARK: - Convenience Extensions

extension PerformanceMonitor {
    /// 测量数据库操作性能
    public func measureDatabase<T>(
        _ operation: String,
        _ block: () async throws -> T
    ) async rethrows -> T {
        try await measure("Database.\(operation)", block)
    }
    
    /// 测量网络操作性能
    public func measureNetwork<T>(
        _ operation: String,
        _ block: () async throws -> T
    ) async rethrows -> T {
        try await measure("Network.\(operation)", block)
    }
    
    /// 测量 UI 操作性能
    public func measureUI<T>(
        _ operation: String,
        _ block: () async throws -> T
    ) async rethrows -> T {
        try await measure("UI.\(operation)", block)
    }
}
