//
//  AppErrorHandler.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import Foundation
import SwiftUI

/// 应用级错误处理器
/// 专门负责全局错误的处理和展示
@MainActor
final class AppErrorHandler: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentError: AppError?
    
    // MARK: - Public Methods
    
    /// 处理错误
    /// - Parameter error: 需要处理的错误
    func handle(_ error: Error) {
        let appError = AppError(underlyingError: error)
        
        // 记录错误日志
        logError(appError)
        
        // 根据错误类型决定处理方式
        switch appError.severity {
        case .critical:
            handleCriticalError(appError)
        case .warning:
            handleWarningError(appError)
        case .info:
            handleInfoError(appError)
        }
    }
    
    /// 直接展示一条消息作为警告/信息，无需构造 Error
    func present(message: String, severity: AppError.Severity = .warning) {
        let wrapped = InlineError(message: message)
        let appError = AppError(underlyingError: wrapped).withSeverityOverride(severity)
        route(appError)
    }
    
    /// 统一路由到对应处理策略
    private func route(_ appError: AppError) {
        // 记录错误日志
        logError(appError)
        // 根据错误类型决定处理方式
        switch appError.severity {
        case .critical: handleCriticalError(appError)
        case .warning:  handleWarningError(appError)
        case .info:     handleInfoError(appError)
        }
    }
    
    /// 清除当前错误
    func clearError() {
        currentError = nil
    }
}

// MARK: - Private Methods
private extension AppErrorHandler {
    
    func logError(_ error: AppError) {
        // 记录错误到日志系统
        print("🚨 App Error: \(error.message)")
        print("📍 Details: \(error.underlyingError)")
        
        // 这里可以集成第三方日志服务
        // 例如：Firebase Crashlytics, Sentry 等
    }
    
    func handleCriticalError(_ error: AppError) {
        // 关键错误需要立即显示给用户
        self.currentError = error
    }
    
    func handleWarningError(_ error: AppError) {
        // 警告错误可以短暂显示
        self.currentError = error
        
        // 3秒后自动清除（可取消）
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            if self.currentError?.id == error.id {
                self.clearError()
            }
        }
    }
    
    func handleInfoError(_ error: AppError) {
        // 信息性错误只记录，不显示
        // 可以通过调试面板查看
    }
}

// MARK: - AppError
struct AppError: Identifiable, Equatable {
    let id: UUID
    let message: String
    let underlyingError: Error
    let severity: Severity
    let timestamp: Date
    
    init(underlyingError: Error) {
    self.id = UUID()
    self.underlyingError = underlyingError
        self.timestamp = Date()
        
        // 根据错误类型确定严重程度和消息
        if let appInitError = underlyingError as? AppInitializationError {
            self.severity = .critical
            self.message = appInitError.localizedDescription
        } else if let localizedError = underlyingError as? LocalizedError {
            self.severity = .warning
            self.message = localizedError.errorDescription ?? "未知错误"
        } else {
            self.severity = .warning
            self.message = underlyingError.localizedDescription
        }
    }

    /// 设计化初始化器（用于克隆并覆写严重级别等字段）
    init(id: UUID, message: String, underlyingError: Error, severity: Severity, timestamp: Date) {
        self.id = id
        self.message = message
        self.underlyingError = underlyingError
        self.severity = severity
        self.timestamp = timestamp
    }
    
    /// 覆写严重级别（用于 present(message:)）
    func withSeverityOverride(_ severity: Severity) -> AppError {
        AppError(
            id: id,
            message: message,
            underlyingError: underlyingError,
            severity: severity,
            timestamp: timestamp
        )
    }
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        lhs.id == rhs.id
    }
    
    enum Severity {
        case critical   // 关键错误，必须显示
        case warning    // 警告错误，短暂显示
        case info      // 信息错误，仅记录
    }
}

// 支持 present(message:) 的轻量错误类型
private struct InlineError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}