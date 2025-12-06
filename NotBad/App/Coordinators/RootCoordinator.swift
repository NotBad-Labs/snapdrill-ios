//
//  RootView.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import Observation

// MARK: - App State

/// 应用根状态
///
/// 控制应用显示哪个顶层视图
enum AppState: Equatable {
    /// 启动中（显示启动屏）
    case launching
    
    /// 主流程（已完成启动）
    case main
    
    /// 错误状态（显示错误页面）
    case error(RootAppError)
    
    /// 维护中（服务端返回维护状态）
    case maintenance
    
    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.launching, .launching): return true
        case (.main, .main): return true
        case (.error(let e1), .error(let e2)): return e1.id == e2.id
        case (.maintenance, .maintenance): return true
        default: return false
        }
    }
}

// MARK: - Root App Error

/// 应用级错误（用于 RootCoordinator）
struct RootAppError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let retryAction: (() -> Void)?
    
    init(title: String, message: String, retryAction: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }
}

// MARK: - RootCoordinator

/// 根协调器
///
/// 管理应用的顶层状态，包括：
/// - 启动流程
/// - 全局错误处理
/// - 维护模式检查
@MainActor
@Observable
final class RootCoordinator {
    
    // MARK: - State
    
    /// 当前应用状态
    var appState: AppState = .launching
    
    /// 最小启动屏显示时间（秒）
    private let minimumLaunchDuration: TimeInterval = 0.8
    
    // MARK: - Lifecycle
    
    /// 启动应用
    func launch() async {
        // 记录启动开始时间
        let startTime = Date()
        
        // 执行启动任务
        await performLaunchTasks()
        
        // 确保最小显示时间
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < minimumLaunchDuration {
            try? await Task.sleep(for: .seconds(minimumLaunchDuration - elapsed))
        }
        
        // 切换到主流程
        appState = .main
    }
    
    /// 执行启动任务
    private func performLaunchTasks() async {
        // 可以在这里添加：
        // - 检查服务端状态
        // - 预加载必要数据
        // - 检查强制更新
        // - 初始化第三方 SDK
    }
    
    /// 显示错误
    func showError(_ error: RootAppError) {
        appState = .error(error)
    }
    
    /// 进入维护模式
    func enterMaintenance() {
        appState = .maintenance
    }
    
    /// 恢复到主流程
    func resumeToMain() {
        appState = .main
    }
}

// MARK: - RootView

/// 根视图
///
/// 应用的最顶层视图容器，根据 `AppState` 显示不同的 UI：
/// - `.launching`: 启动屏
/// - `.main`: 主流程（MainFlow）
/// - `.error`: 错误页面
/// - `.maintenance`: 维护提示页面
struct RootView: View {
    
    // MARK: - Coordinator
    
    let coordinator: RootCoordinator
    let mainFlowCoordinator: MainFlowCoordinator
    
    // MARK: - Body
    
    var body: some View {
        Group {
            switch coordinator.appState {
            case .launching:
                LaunchScreenView()
                    .transition(.opacity)
                
            case .main:
                MainFlowView(coordinator: mainFlowCoordinator)
                    .transition(.opacity)
                
            case .error(let error):
                RootErrorView(error: error)
                    .transition(.opacity)
                
            case .maintenance:
                RootMaintenanceView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.appState)
        .task {
            await coordinator.launch()
        }
    }
}

// MARK: - Error View

/// 错误视图
private struct RootErrorView: View {
    let error: RootAppError
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text(error.title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error.message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let retry = error.retryAction {
                Button("retry") {
                    retry()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Maintenance View

/// 维护中视图
private struct RootMaintenanceView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("maintenance_title")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("maintenance_message")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

// MARK: - Environment Key

private struct RootCoordinatorKey: EnvironmentKey {
    static let defaultValue: RootCoordinator? = nil
}

extension EnvironmentValues {
    var rootCoordinator: RootCoordinator? {
        get { self[RootCoordinatorKey.self] }
        set { self[RootCoordinatorKey.self] = newValue }
    }
}
