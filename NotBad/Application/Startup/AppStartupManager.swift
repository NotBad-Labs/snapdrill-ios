//
//  AppStartupManager.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import Foundation
import SwiftUI

/// 应用启动管理器
/// 管理复杂的启动流程，支持条件启动、启动步骤监控等高级功能
final class AppStartupManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var startupState: StartupState = .notStarted
    @Published var currentStep: StartupStep?
    @Published var progress: Double = 0.0
    
    // MARK: - Dependencies
    let initializationService: AppInitializationService
    private let errorHandler: AppErrorHandler
    private let configuration: AppConfiguration
    
    // MARK: - Internal State
    private var startupSteps: [StartupStep] = []
    private var startTime: Date?
    
    // MARK: - Initialization
    init(
        initializationService: AppInitializationService,
        errorHandler: AppErrorHandler,
        configuration: AppConfiguration
    ) {
        self.initializationService = initializationService
        self.errorHandler = errorHandler
        self.configuration = configuration
        
        setupStartupSteps()
    }
    
    // MARK: - Public Methods
    
    /// 执行启动流程
    /// - Returns: 启动结果
    func performStartup() async -> StartupResult {
        await MainActor.run {
            startupState = .starting
            startTime = Date()
            progress = 0.0
        }
        
        do {
            // 执行所有启动步骤
            for (index, step) in startupSteps.enumerated() {
                try Task.checkCancellation()
                await updateCurrentStep(step)
                
                try await executeStep(step)
                
                await updateProgress(Double(index + 1) / Double(startupSteps.count))
            }
            
            // 确保最小显示时间
            try await ensureMinimumDisplayTime()
            
            await MainActor.run {
                startupState = .completed
                progress = 1.0
            }
            
            let duration = Date().timeIntervalSince(startTime ?? Date())
            return StartupResult(
                success: true,
                duration: duration,
                completedSteps: startupSteps.count,
                error: nil
            )
            
        } catch is CancellationError {
            await MainActor.run {
                startupState = .notStarted
            }
            let duration = Date().timeIntervalSince(startTime ?? Date())
            return StartupResult(
                success: false,
                duration: duration,
                completedSteps: startupSteps.firstIndex(where: { $0 == currentStep }) ?? 0,
                error: StartupError.timeout
            )
        } catch {
            await MainActor.run {
                startupState = .failed(error)
                errorHandler.handle(error)
            }
            
            let duration = Date().timeIntervalSince(startTime ?? Date())
            return StartupResult(
                success: false,
                duration: duration,
                completedSteps: startupSteps.firstIndex(where: { $0 == currentStep }) ?? 0,
                error: error
            )
        }
    }
    
    /// 重置启动状态
    func reset() {
        startupState = .notStarted
        currentStep = nil
        progress = 0.0
        startTime = nil
    }
}

// MARK: - Private Methods
private extension AppStartupManager {
    
    func setupStartupSteps() {
        startupSteps = [
            StartupStep(
                id: "config_validation",
                name: "配置验证",
                description: "验证应用配置参数",
                estimatedDuration: 0.1
            ),
            StartupStep(
                id: "service_initialization",
                name: "服务初始化",
                description: "初始化核心服务",
                estimatedDuration: 0.2
            ),
            StartupStep(
                id: "database_setup",
                name: "数据库准备",
                description: "初始化数据库连接",
                estimatedDuration: 0.3
            ),
            StartupStep(
                id: "user_state_restore",
                name: "状态恢复",
                description: "恢复用户状态",
                estimatedDuration: 0.2
            ),
            StartupStep(
                id: "network_check",
                name: "网络检查",
                description: "检查网络连接状态",
                estimatedDuration: 0.1
            ),
            StartupStep(
                id: "cache_warmup",
                name: "缓存预热",
                description: "预加载常用数据",
                estimatedDuration: 0.2
            ),
            StartupStep(
                id: "ui_preparation",
                name: "界面准备",
                description: "准备用户界面",
                estimatedDuration: 0.1
            )
        ]
    }
    
    func executeStep(_ step: StartupStep) async throws {
        switch step.id {
        case "config_validation":
            try await validateConfiguration()
        case "service_initialization":
            try await initializeServices()
        case "database_setup":
            try await setupDatabase()
        case "user_state_restore":
            try await restoreUserState()
        case "network_check":
            try await checkNetworkStatus()
        case "cache_warmup":
            try await warmupCache()
        case "ui_preparation":
            try await prepareUI()
        default:
            throw StartupError.unknownStep(step.id)
        }
        
    // 模拟步骤执行时间（仅 DEBUG 下保留可视化进度）
    #if DEBUG
    try Task.checkCancellation()
    try await Task.sleep(for: .milliseconds(Int(step.estimatedDuration * 1000)))
    try Task.checkCancellation()
    #endif
    }
    
    func updateCurrentStep(_ step: StartupStep) async {
        await MainActor.run {
            currentStep = step
        }
    }
    
    func updateProgress(_ newProgress: Double) async {
        await MainActor.run {
            progress = newProgress
        }
    }
    
    func ensureMinimumDisplayTime() async throws {
        guard let startTime = startTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let minimumTime = AppConfiguration.Lifecycle.Launch.minimumDisplayTime
        
        #if DEBUG
        if elapsed < minimumTime {
            let remainingTime = minimumTime - elapsed
            try Task.checkCancellation()
            try await Task.sleep(for: .milliseconds(Int(remainingTime * 1000)))
            try Task.checkCancellation()
        }
        #endif
    }
}

// MARK: - Step Implementations
private extension AppStartupManager {
    
    func validateConfiguration() async throws {
        let result = AppConfiguration.validateConfiguration()
        if !result.isValid {
            throw StartupError.configurationInvalid(result.issues)
        }
    }
    
    func initializeServices() async throws {
        try await initializationService.initialize()
    }
    
    func setupDatabase() async throws {
        // 数据库初始化逻辑
    }
    
    func restoreUserState() async throws {
        // 用户状态恢复逻辑
    }
    
    func checkNetworkStatus() async throws {
        // 网络状态检查逻辑
    }
    
    func warmupCache() async throws {
        // 缓存预热逻辑
    }
    
    func prepareUI() async throws {
        // UI 准备逻辑
    }
}

// MARK: - Supporting Types

/// 启动状态
enum StartupState: Equatable {
    case notStarted
    case starting
    case completed
    case failed(Error)
    
    static func == (lhs: StartupState, rhs: StartupState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
             (.starting, .starting),
             (.completed, .completed):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
    
    var isCompleted: Bool {
        if case .completed = self { return true }
        return false
    }
    
    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }
}

/// 启动步骤
struct StartupStep: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let description: String
    let estimatedDuration: TimeInterval
    
    static func == (lhs: StartupStep, rhs: StartupStep) -> Bool {
        lhs.id == rhs.id
    }
}

/// 启动结果
struct StartupResult: @unchecked Sendable {
    let success: Bool
    let duration: TimeInterval
    let completedSteps: Int
    let error: Error?
    
    var description: String {
        if success {
            return "✅ 启动成功 - 耗时: \(String(format: "%.2f", duration))s, 完成步骤: \(completedSteps)"
        } else {
            return "❌ 启动失败 - 耗时: \(String(format: "%.2f", duration))s, 完成步骤: \(completedSteps), 错误: \(error?.localizedDescription ?? "未知错误")"
        }
    }
}

/// 启动错误
enum StartupError: Error, LocalizedError, Sendable {
    case configurationInvalid([String])
    case unknownStep(String)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .configurationInvalid(let issues):
            return "配置验证失败: \(issues.joined(separator: ", "))"
        case .unknownStep(let stepId):
            return "未知的启动步骤: \(stepId)"
        case .timeout:
            return "启动超时"
        }
    }
}