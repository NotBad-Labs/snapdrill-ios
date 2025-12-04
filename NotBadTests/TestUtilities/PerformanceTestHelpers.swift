//
//  PerformanceTestHelpers.swift
//  NotBadTests
//
//  性能测试辅助工具
//

import XCTest
import Foundation

/// 性能测试辅助工具
///
/// 提供性能测试所需的各种辅助方法。
///
/// ## 使用示例
///
/// ```swift
/// class MyPerformanceTests: XCTestCase {
///     func testSomething() {
///         let result = measureExecutionTime {
///             // 被测试的代码
///         }
///         print("执行时间: \(result.seconds) 秒")
///     }
/// }
/// ```
public enum PerformanceTestHelpers {
    
    // MARK: - Execution Time Measurement
    
    /// 执行时间测量结果
    public struct ExecutionResult<T> {
        public let value: T
        public let nanoseconds: UInt64
        
        public var milliseconds: Double {
            Double(nanoseconds) / 1_000_000
        }
        
        public var seconds: Double {
            Double(nanoseconds) / 1_000_000_000
        }
    }
    
    /// 测量代码块执行时间
    ///
    /// - Parameter block: 要测量的代码块
    /// - Returns: 执行结果和时间
    public static func measureExecutionTime<T>(_ block: () throws -> T) rethrows -> ExecutionResult<T> {
        let start = DispatchTime.now()
        let value = try block()
        let end = DispatchTime.now()
        let nanoseconds = end.uptimeNanoseconds - start.uptimeNanoseconds
        return ExecutionResult(value: value, nanoseconds: nanoseconds)
    }
    
    /// 测量异步代码块执行时间
    ///
    /// - Parameter block: 要测量的异步代码块
    /// - Returns: 执行结果和时间
    public static func measureExecutionTimeAsync<T>(_ block: () async throws -> T) async rethrows -> ExecutionResult<T> {
        let start = DispatchTime.now()
        let value = try await block()
        let end = DispatchTime.now()
        let nanoseconds = end.uptimeNanoseconds - start.uptimeNanoseconds
        return ExecutionResult(value: value, nanoseconds: nanoseconds)
    }
    
    // MARK: - Memory Measurement
    
    /// 内存使用信息
    public struct MemoryInfo {
        public let usedBytes: UInt64
        public let peakBytes: UInt64
        
        public var usedMB: Double {
            Double(usedBytes) / (1024 * 1024)
        }
        
        public var peakMB: Double {
            Double(peakBytes) / (1024 * 1024)
        }
    }
    
    /// 获取当前内存使用量
    public static func currentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return 0
        }
        
        return info.resident_size
    }
    
    /// 测量代码块执行期间的内存增长
    ///
    /// - Parameter block: 要测量的代码块
    /// - Returns: 内存使用信息
    public static func measureMemoryGrowth<T>(_ block: () throws -> T) rethrows -> (value: T, memoryGrowth: UInt64) {
        let beforeMemory = currentMemoryUsage()
        let value = try block()
        let afterMemory = currentMemoryUsage()
        let growth = afterMemory > beforeMemory ? afterMemory - beforeMemory : 0
        return (value, growth)
    }
    
    // MARK: - Thresholds and Assertions
    
    /// 性能阈值
    public struct Threshold: Sendable {
        public let maxMilliseconds: Double
        public let maxMemoryMB: Double
        
        public init(maxMilliseconds: Double = 100, maxMemoryMB: Double = 50) {
            self.maxMilliseconds = maxMilliseconds
            self.maxMemoryMB = maxMemoryMB
        }
        
        public static let fast = Threshold(maxMilliseconds: 16, maxMemoryMB: 10)
        public static let normal = Threshold(maxMilliseconds: 100, maxMemoryMB: 50)
        public static let slow = Threshold(maxMilliseconds: 500, maxMemoryMB: 100)
        public static let heavy = Threshold(maxMilliseconds: 2000, maxMemoryMB: 200)
    }
    
    /// 断言执行时间在阈值内
    public static func assertExecutionTime<T>(
        _ block: () throws -> T,
        within threshold: Threshold,
        file: StaticString = #filePath,
        line: UInt = #line
    ) rethrows -> T {
        let result = try measureExecutionTime(block)
        XCTAssertLessThan(
            result.milliseconds,
            threshold.maxMilliseconds,
            "执行时间 \(result.milliseconds)ms 超过阈值 \(threshold.maxMilliseconds)ms",
            file: file,
            line: line
        )
        return result.value
    }
    
    /// 断言内存增长在阈值内
    public static func assertMemoryGrowth<T>(
        _ block: () throws -> T,
        within threshold: Threshold,
        file: StaticString = #filePath,
        line: UInt = #line
    ) rethrows -> T {
        let result = try measureMemoryGrowth(block)
        let growthMB = Double(result.memoryGrowth) / (1024 * 1024)
        XCTAssertLessThan(
            growthMB,
            threshold.maxMemoryMB,
            "内存增长 \(growthMB)MB 超过阈值 \(threshold.maxMemoryMB)MB",
            file: file,
            line: line
        )
        return result.value
    }
    
    // MARK: - Iteration Helpers
    
    /// 多次执行并取平均值
    ///
    /// - Parameters:
    ///   - iterations: 迭代次数
    ///   - warmup: 预热次数（不计入统计）
    ///   - block: 要执行的代码块
    /// - Returns: 平均执行时间（毫秒）
    public static func averageExecutionTime(
        iterations: Int = 10,
        warmup: Int = 2,
        _ block: () throws -> Void
    ) rethrows -> Double {
        // 预热
        for _ in 0..<warmup {
            try block()
        }
        
        // 正式测量
        var totalNanoseconds: UInt64 = 0
        for _ in 0..<iterations {
            let result = try measureExecutionTime(block)
            totalNanoseconds += result.nanoseconds
        }
        
        return Double(totalNanoseconds) / Double(iterations) / 1_000_000
    }
    
    /// 打印性能报告
    public static func printPerformanceReport(
        name: String,
        executionMs: Double,
        memoryMB: Double? = nil,
        itemCount: Int? = nil
    ) {
        var report = """
        
        ⚡️ 性能报告: \(name)
        ├─ 执行时间: \(String(format: "%.2f", executionMs)) ms
        """
        
        if let memory = memoryMB {
            report += "\n├─ 内存使用: \(String(format: "%.2f", memory)) MB"
        }
        
        if let count = itemCount {
            let perItem = executionMs / Double(count)
            report += "\n├─ 单项耗时: \(String(format: "%.3f", perItem)) ms"
        }
        
        report += "\n└─ 完成"
        print(report)
    }
}

// MARK: - XCTestCase Extension

public extension XCTestCase {
    
    /// 便捷的性能测量方法
    func measureWithResult<T>(
        _ block: () throws -> T
    ) rethrows -> PerformanceTestHelpers.ExecutionResult<T> {
        try PerformanceTestHelpers.measureExecutionTime(block)
    }
    
    /// 断言代码块在指定毫秒内完成
    func assertCompletes<T>(
        withinMilliseconds ms: Double,
        file: StaticString = #file,
        line: UInt = #line,
        _ block: () throws -> T
    ) rethrows -> T {
        let threshold = PerformanceTestHelpers.Threshold(maxMilliseconds: ms, maxMemoryMB: 1000)
        return try PerformanceTestHelpers.assertExecutionTime(block, within: threshold, file: file, line: line)
    }
    
    /// 异步版本的性能测量
    func measureAsyncPerformance(
        iterations: Int = 5,
        _ block: @escaping () async throws -> Void
    ) async throws {
        var times: [Double] = []
        
        for _ in 0..<iterations {
            let result = try await PerformanceTestHelpers.measureExecutionTimeAsync(block)
            times.append(result.milliseconds)
        }
        
        let average = times.reduce(0, +) / Double(times.count)
        let min = times.min() ?? 0
        let max = times.max() ?? 0
        
        print("""
        📊 异步性能测试结果 (\(iterations) 次迭代):
        - 平均: \(String(format: "%.2f", average)) ms
        - 最小: \(String(format: "%.2f", min)) ms
        - 最大: \(String(format: "%.2f", max)) ms
        """)
    }
}
