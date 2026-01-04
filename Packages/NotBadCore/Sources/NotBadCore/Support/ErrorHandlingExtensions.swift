//
//  ErrorHandlingExtensions.swift
//  NotBadCore
//
//  Created by NotBad Architect on 2026/01/03.
//  Copyright © 2026 NotBad Team. All rights reserved.
//
//  错误处理扩展
//

import Foundation

/// 结果构建器，用于优雅地处理多个可能失败的操作
@resultBuilder
public enum ResultBuilder {
    public static func buildBlock<T>(_ components: Result<T, Error>...) -> Result<[T], Error> {
        var results: [T] = []
        for component in components {
            switch component {
            case .success(let value):
                results.append(value)
            case .failure(let error):
                return .failure(error)
            }
        }
        return .success(results)
    }
}

/// 错误处理扩展
extension Result {
    /// 异步执行操作并捕获错误
    ///
    /// - Parameter operation: 异步操作
    /// - Returns: 操作结果
    public static func catching(_ operation: () async throws -> Success) async -> Result<Success, Error> {
        do {
            let value = try await operation()
            return .success(value)
        } catch {
            return .failure(error)
        }
    }
    
    /// 同步执行操作并捕获错误
    ///
    /// - Parameter operation: 同步操作
    /// - Returns: 操作结果
    public static func catching(_ operation: () throws -> Success) -> Result<Success, Error> {
        do {
            let value = try operation()
            return .success(value)
        } catch {
            return .failure(error)
        }
    }
    
    /// 映射成功值，保留错误
    ///
    /// - Parameter transform: 转换函数
    /// - Returns: 转换后的结果
    public func mapSuccess<NewSuccess>(_ transform: (Success) -> NewSuccess) -> Result<NewSuccess, Failure> {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// 异步映射成功值
    ///
    /// - Parameter transform: 异步转换函数
    /// - Returns: 转换后的结果
    public func asyncMap<NewSuccess>(
        _ transform: (Success) async throws -> NewSuccess
    ) async -> Result<NewSuccess, Error> where Failure == Error {
        switch self {
        case .success(let value):
            do {
                let newValue = try await transform(value)
                return .success(newValue)
            } catch {
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// 获取成功值或提供默认值
    ///
    /// - Parameter defaultValue: 默认值
    /// - Returns: 成功值或默认值
    public func valueOrDefault(_ defaultValue: Success) -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return defaultValue
        }
    }
    
    /// 记录错误到崩溃报告服务
    @MainActor
    public func logError(context: [String: Any] = [:]) -> Result<Success, Failure> {
        if case .failure(let error) = self {
            CrashReportingService.shared.recordError(error, context: context)
        }
        return self
    }
}

/// 可重试的操作
public struct RetryableOperation<T> {
    let maxAttempts: Int
    let delay: TimeInterval
    let operation: () async throws -> T
    
    /// 创建可重试操作
    ///
    /// - Parameters:
    ///   - maxAttempts: 最大尝试次数
    ///   - delay: 重试延迟（秒）
    ///   - operation: 要执行的操作
    public init(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) {
        self.maxAttempts = maxAttempts
        self.delay = delay
        self.operation = operation
    }
    
    /// 执行操作，失败时自动重试
    ///
    /// - Returns: 操作结果
    /// - Throws: 最后一次尝试的错误
    public func execute() async throws -> T {
        var lastError: Error?
        let attempts = maxAttempts  // Capture for safe use in closure
        
        for attempt in 1...attempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                if attempt < attempts {
                    // 等待后重试
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    
                    // 记录重试
                    await MainActor.run {
                        CrashReportingService.shared.leaveBreadcrumb(
                            "Retrying operation (attempt \(attempt + 1)/\(attempts))",
                            metadata: ["error": error.localizedDescription]
                        )
                    }
                }
            }
        }
        
        throw lastError ?? NSError(domain: "RetryableOperation", code: -1)
    }
}

/// 错误恢复策略
public enum RecoveryStrategy {
    case retry(maxAttempts: Int, delay: TimeInterval)
    case fallback(() async throws -> Void)
    case ignore
    case rethrow
}

/// 带恢复策略的错误处理
public struct RecoverableOperation<T> {
    let operation: () async throws -> T
    let strategy: RecoveryStrategy
    
    /// 创建可恢复操作
    ///
    /// - Parameters:
    ///   - strategy: 恢复策略
    ///   - operation: 要执行的操作
    public init(
        strategy: RecoveryStrategy,
        operation: @escaping () async throws -> T
    ) {
        self.operation = operation
        self.strategy = strategy
    }
    
    /// 执行操作并应用恢复策略
    ///
    /// - Returns: 操作结果（可选）
    /// - Throws: 根据策略可能抛出错误
    public func execute() async throws -> T? {
        do {
            return try await operation()
        } catch {
            switch strategy {
            case .retry(let maxAttempts, let delay):
                let retryable = RetryableOperation(
                    maxAttempts: maxAttempts,
                    delay: delay,
                    operation: operation
                )
                return try await retryable.execute()
                
            case .fallback(let fallbackOperation):
                try await fallbackOperation()
                return nil
                
            case .ignore:
                return nil
                
            case .rethrow:
                throw error
            }
        }
    }
}
