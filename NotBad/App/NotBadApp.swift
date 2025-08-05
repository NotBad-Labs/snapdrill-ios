// MARK: - NotBadApp.swift
/**
 * iOS 错题本应用入口点
 *
 * 职责：
 * - 作为应用的主入口点，负责应用生命周期的最顶层管理
 * - 创建和管理核心依赖对象的生命周期（AppState、AppEnvironment、AppCoordinator）
 * - 建立依赖注入的环境对象传递链
 * - 触发应用的初始化流程
 *
 * 设计原则：
 * - 最小职责：只负责应用启动和核心对象创建
 * - 依赖注入：通过 @StateObject 管理对象生命周期
 * - 环境传递：使用 .environmentObject() 建立依赖链
 *
 * 架构位置：
 * ```
 * NotBadApp (这里) ← 应用入口
 *     ↓ 创建核心对象
 * RootView ← 根视图容器
 *     ↓ 状态驱动显示
 * AppCoordinator ← 应用协调器管理流程
 * ```
 *
 * 使用说明：
 * - 该文件是应用的 @main 入口，SwiftUI 应用生命周期的起点
 * - 三个核心对象的创建顺序很重要，AppState 应该最先创建
 * - 所有环境对象都会传递给 RootView，供整个应用树使用
 *
 * 注意事项：
 * - 不要在这里添加复杂的业务逻辑，保持职责单一
 * - 对象创建失败会直接导致应用崩溃，因此要确保依赖的稳定性
 * - 该文件的修改会影响整个应用的启动，需要谨慎处理
 *
 * @author NotBad Team
 * @since 1.0.0
 * @updated 2025-08-01
 */

import SwiftUI

@main
struct NotBadApp: App {
    
    // MARK: - 核心状态对象
    // 注意：由于使用了 @Observable，这些对象使用 @State 而不是 @StateObject
    
    /// 全局应用状态管理器
    /// 负责管理应用流程状态、用户状态、应用设置等
    @State private var appState = AppState()
    
    /// 依赖注入环境容器
    /// 负责创建和管理所有服务、仓储、外部依赖等
    @State private var appEnvironment = AppEnvironment()
    
    /// 应用根协调器
    /// 负责应用级别的导航协调和流程管理
    @State private var appCoordinator = AppCoordinator()
    
    // MARK: - 应用场景配置
    
    /**
     * 应用的主场景配置
     *
     * 创建主窗口组并设置根视图，建立完整的依赖注入环境
     * 在视图出现时触发应用初始化流程
     */
    var body: some Scene {
        WindowGroup {
            RootView()
                // 注入全局状态管理器，供整个视图树使用
                .environment(appState)
                // 注入依赖环境容器，供服务获取使用
                .environment(appEnvironment)
                // 注入应用协调器，供导航管理使用
                .environment(appCoordinator)
                // 在根视图出现时执行应用初始化
                .onAppear {
                    initializeApplication()
                }
                // 处理应用生命周期事件
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    handleApplicationDidBecomeActive()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    handleApplicationWillResignActive()
                }
        }
    }
    
    // MARK: - 私有方法 - 应用初始化
    
    /**
     * 应用初始化流程
     *
     * 负责设置核心对象之间的依赖关系，并启动应用协调器
     * 这是应用启动后第一个被调用的业务逻辑方法
     *
     * 执行步骤：
     * 1. 配置 AppCoordinator 的依赖注入
     * 2. 启动应用协调器的初始化流程
     *
     * 注意：该方法只应该在应用启动时调用一次
     */
    private func initializeApplication() {
        configureAppCoordinator()
        startApplicationFlow()
    }
    
    /**
     * 配置应用协调器的依赖
     *
     * 将 AppEnvironment 和 AppState 注入到 AppCoordinator 中，
     * 建立三者之间的协作关系
     */
    private func configureAppCoordinator() {
        appCoordinator.configure(
            environment: appEnvironment,
            appState: appState
        )
    }
    
    /**
     * 启动应用流程
     *
     * 调用 AppCoordinator 的 start() 方法，
     * 开始执行应用的初始化任务和流程管理
     */
    private func startApplicationFlow() {
        appCoordinator.start()
    }
    
    // MARK: - 私有方法 - 应用生命周期处理
    
    /**
     * 处理应用变为活跃状态
     *
     * 当应用从后台返回前台时调用，可以在这里执行：
     * - 刷新数据
     * - 重新连接网络服务
     * - 更新 UI 状态
     */
    private func handleApplicationDidBecomeActive() {
        // 通知协调器应用已激活
        appCoordinator.handleApplicationDidBecomeActive()
        
        // 可以在这里添加其他激活时需要执行的逻辑
        // 例如：刷新用户数据、检查网络状态等
    }
    
    /**
     * 处理应用即将失去活跃状态
     *
     * 当应用即将进入后台时调用，可以在这里执行：
     * - 保存用户数据
     * - 暂停定时器
     * - 清理临时资源
     */
    private func handleApplicationWillResignActive() {
        // 通知协调器应用即将失去活跃状态
        appCoordinator.handleApplicationWillResignActive()
        
        // 确保关键状态被持久化
        appState.saveCurrentState()
    }
}

// MARK: - 扩展方法

/**
 * AppState 扩展 - 添加应用生命周期相关方法
 *
 * 为了保持 AppState 核心职责的纯净，将应用生命周期相关的方法
 * 通过扩展的方式添加
 */
private extension AppState {
    
    /**
     * 持久化当前状态
     *
     * 在应用即将进入后台时调用，确保重要状态被保存
     */
    func persistCurrentState() {
        // 调用 AppState 的公开持久化方法
        saveCurrentState()
        print("💾 当前应用状态已持久化")
    }
}

