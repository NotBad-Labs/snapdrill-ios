//
//  AppEnvironment.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import Foundation
import SwiftUI

/// 应用环境管理器
/// 统一管理所有环境对象的注入和配置，简化主入口的依赖管理
@MainActor
final class AppEnvironment: ObservableObject {
    
    // MARK: - Singleton
    static let shared: AppEnvironment = {
        AppEnvironment()
    }()
    
    // MARK: - Core Dependencies
    
    /// 服务容器
    let serviceContainer: ServiceContainer
    
    /// 主协调器
    let mainCoordinator: MainCoordinator
    
    /// 错误处理器
    @Published var errorHandler: AppErrorHandler
    
    /// 初始化服务
    let initializationService: AppInitializationService
    
    /// 启动管理器
    let startupManager: AppStartupManager
    
    // MARK: - Configuration
    let configuration: AppConfiguration
    
    // MARK: - Initialization
    
    private init() {
        // 1. 基础配置
        self.configuration = AppConfiguration.current
        
        // 2. 验证配置
        let validationResult = AppConfiguration.validateConfiguration()
        if !validationResult.isValid {
            print("⚠️ App Configuration Issues:")
            print(validationResult.description)
        }
        
        // 3. 核心服务初始化
        self.serviceContainer = ServiceContainer.shared
        
        // 4. 先创建临时变量避免 self 引用问题
        let tempErrorHandler = AppErrorHandler()
        let tempCoordinator = MainCoordinator()
        let tempInitService = AppInitializationService(
            serviceContainer: serviceContainer
        )
        
        // 5. 赋值给存储属性
        self.errorHandler = tempErrorHandler
        self.mainCoordinator = tempCoordinator
        self.initializationService = tempInitService
        
        // 6. 最后初始化依赖其他属性的组件
        self.startupManager = AppStartupManager(
            initializationService: tempInitService,
            errorHandler: tempErrorHandler,
            configuration: configuration
        )
        
        #if DEBUG
        logInitializationInfo()
        #endif
    }

    // MARK: - Factory
    /// 创建一个新的 AppEnvironment 实例（不暴露构造器）
    @MainActor
    static func make() -> AppEnvironment {
        AppEnvironment()
    }
    
    // MARK: - Public Methods
    
    /// 配置环境到 SwiftUI 视图
    /// - Parameter content: 要包装的内容视图
    /// - Returns: 配置好环境的视图
    func configure<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .environment(\.appEnvironment, self)
            .environment(\.serviceContainer, serviceContainer)
            .environmentObject(errorHandler)
            .environmentObject(mainCoordinator)
            .environmentObject(self)
    }
    
    /// 重置环境（主要用于测试）
    func reset() {
        // 清理错误状态
        errorHandler.clearError()
        
        #if DEBUG
        print("🔄 App Environment state has been reset")
        #endif
    }
}

// MARK: - Debug Support
#if DEBUG
private extension AppEnvironment {
    func logInitializationInfo() {
        print("🚀 App Environment Initialized")
        print(AppConfiguration.debugDescription())
        print("✅ Environment ready for use")
    }
}
#endif

// MARK: - Environment Key for SwiftUI
private struct AppEnvironmentKey: EnvironmentKey {
    @MainActor static var defaultValue: AppEnvironment {
        // 注意：SwiftUI 可能会在视图树尚未完全注入环境前就解析 @Environment，
        // 此处返回一个安全的回退值，避免因默认值触发 fatalError。
        // 实际运行时会在上层通过 .withAppEnvironment(...) 覆盖为正确实例。
        return AppEnvironment.shared
    }
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}

// MARK: - Convenience Extensions
extension View {
    /// 应用环境配置的便捷方法
    @MainActor
    func withAppEnvironment(_ environment: AppEnvironment? = nil) -> some View {
        let env = environment ?? AppEnvironment.shared
        return env.configure {
            self
        }
    }
}

// MARK: - Testing Support
#if DEBUG
extension AppEnvironment {
    /// 创建测试环境
    @MainActor
    static func createTestEnvironment() -> AppEnvironment {
        let environment = AppEnvironment()
        environment.reset()
        return environment
    }
    
    /// 验证环境配置
    func validateEnvironment() -> EnvironmentValidationResult {
        let issues: [String] = []
        
        // 验证基础服务
        // 注意：ServiceContainer 的服务总是存在的，不需要 nil 检查
        
        // 验证启动管理器的依赖
        // 注意：initializationService 在初始化时已经设置，不会为 nil
        
        return EnvironmentValidationResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }
}

/// 环境验证结果
struct EnvironmentValidationResult {
    let isValid: Bool
    let issues: [String]
    
    var description: String {
        if isValid {
            return "✅ 环境验证通过"
        } else {
            return "❌ 环境验证失败:\n" + issues.map { "  • \($0)" }.joined(separator: "\n")
        }
    }
}
#endif
