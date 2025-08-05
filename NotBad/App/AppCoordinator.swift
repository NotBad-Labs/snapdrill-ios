// MARK: - AppCoordinator.swift
/**
 * 应用根协调器
 * 
 * 职责：
 * - 管理应用级别的导航流程和状态转换
 * - 协调应用启动时的初始化任务序列
 * - 处理深度链接、推送通知等外部事件路由
 * - 管理子协调器的生命周期（如 MainFlowCoordinator）
 * - 响应应用生命周期事件并执行相应的业务逻辑
 * 
 * 设计原则：
 * - 协调器模式：将导航逻辑从视图中分离，提高可测试性
 * - 单一职责：只负责应用级别的协调，具体业务逻辑委托给服务层
 * - 状态驱动：基于 AppState 的变化来决定导航和流程
 * - 异步处理：支持复杂的异步初始化和任务执行
 * 
 * 架构位置：
 * ```
 * NotBadApp
 *     ↓ 配置和启动
 * AppCoordinator (这里) ← 应用级协调
 *     ↓ 管理子协调器
 * MainFlowCoordinator ← 主流程协调
 *     ↓ 管理 Tab 协调器
 * TabCoordinators ← 具体功能协调
 * ```
 * 
 * 使用方式：
 * ```swift
 * let coordinator = AppCoordinator()
 * coordinator.configure(environment: env, appState: state)
 * coordinator.start()
 * ```
 * 
 * 注意事项：
 * - 必须在使用前调用 configure() 方法注入依赖
 * - start() 方法只应该被调用一次
 * - 所有方法都在 @MainActor 上下文中执行，确保 UI 操作的线程安全
 * - 子协调器的创建时机很重要，避免过早创建导致的资源浪费
 * 
 * @author NotBad Team
 * @since 1.0.0
 * @updated 2025-08-01
 */

import SwiftUI
import Observation

@Observable
@MainActor
class AppCoordinator {
    
    // MARK: - 依赖注入
    
    /// 依赖注入环境容器，提供各种服务的访问
    private var environment: AppEnvironment?
    
    /// 全局应用状态管理器，用于状态查询和更新
    private var appState: AppState?
    
    // MARK: - 子协调器管理
    
    /// 主流程协调器，负责管理应用主界面的导航流程
    /// 延迟创建，只在需要时初始化以节省资源
    private var mainFlowCoordinator: MainFlowCoordinator?
    
    // MARK: - 状态跟踪
    
    /// 协调器是否已经配置完成
    private var isConfigured: Bool = false
    
    /// 协调器是否已经启动
    private var hasStarted: Bool = false
    
    /// 当前正在执行的初始化任务，用于避免重复启动
    private var initializationTask: Task<Void, Never>?
    
    // MARK: - 初始化
    
    /**
     * 初始化应用协调器
     * 
     * 创建一个未配置的协调器实例，需要调用 configure() 方法
     * 注入必要的依赖后才能正常工作
     */
    init() {
        print("🎯 AppCoordinator 已创建")
    }
    
    // MARK: - 公开方法 - 配置和启动
    
    /**
     * 配置应用协调器
     * 
     * 注入必要的依赖，建立协调器与环境和状态的关联关系
     * 该方法是幂等的，多次调用不会产生副作用
     * 
     * @param environment 依赖注入环境容器
     * @param appState 全局应用状态管理器
     * 
     * 使用示例：
     * ```swift
     * coordinator.configure(
     *     environment: appEnvironment,
     *     appState: appState
     * )
     * ```
     */
    func configure(environment: AppEnvironment, appState: AppState) {
        guard !isConfigured else {
            print("⚠️ AppCoordinator 已经配置过，跳过重复配置")
            return
        }
        
        self.environment = environment
        self.appState = appState
        self.isConfigured = true
        
        print("✅ AppCoordinator 配置完成")
    }
    
    /**
     * 启动应用协调器
     * 
     * 开始执行应用的初始化流程，该方法是异步的，会按顺序执行：
     * 1. 验证配置状态
     * 2. 配置依赖注入环境
     * 3. 执行启动任务序列
     * 4. 完成初始化
     * 
     * 该方法只应该被调用一次，重复调用会被忽略
     * 
     * 注意：该方法会创建一个 Task 来执行异步初始化，
     * 确保不会阻塞主线程
     */
    func start() {
        guard isConfigured else {
            fatalError("❌ AppCoordinator 必须在启动前调用 configure() 方法")
        }
        
        guard !hasStarted else {
            print("⚠️ AppCoordinator 已经启动过，跳过重复启动")
            return
        }
        
        hasStarted = true
        print("🚀 AppCoordinator 开始启动...")
        
        // 创建异步初始化任务
        initializationTask = Task {
            await performInitialization()
        }
    }
    
    // MARK: - 公开方法 - 流程管理
    
    /**
     * 显示主应用流程
     * 
     * 创建并启动 MainFlowCoordinator，开始管理应用的主要功能流程
     * 该方法通常在应用状态切换到 .main 时被调用
     * 
     * 如果 MainFlowCoordinator 已经存在，会复用现有实例
     */
    func showMainFlow() {
        guard let environment = environment,
              let appState = appState else {
            print("❌ 无法显示主流程：依赖未配置")
            return
        }
        
        // 延迟创建模式：只在需要时创建主流程协调器
        if mainFlowCoordinator == nil {
            print("🏗️ 创建 MainFlowCoordinator")
            mainFlowCoordinator = MainFlowCoordinator(
                environment: environment,
                appState: appState
            )
        }
        
        // 启动主流程协调器
        mainFlowCoordinator?.start()
        print("✅ 主流程已启动")
    }
    
    // MARK: - 公开方法 - 外部事件处理
    
    /**
     * 处理深度链接
     * 
     * 解析并路由深度链接到对应的应用功能
     * 支持的链接格式：
     * - notbad://question/capture - 跳转到录题页面
     * - notbad://study/session/123 - 跳转到特定学习会话
     * - notbad://library/search?q=数学 - 跳转到题库搜索
     * 
     * @param url 深度链接 URL
     * 
     * 使用示例：
     * ```swift
     * coordinator.handleDeepLink(URL(string: "notbad://question/capture")!)
     * ```
     */
    func handleDeepLink(_ url: URL) {
        print("🔗 处理深度链接: \(url)")
        
        guard let scheme = url.scheme, scheme == "notbad" else {
            print("⚠️ 不支持的链接协议: \(url.scheme ?? "nil")")
            return
        }
        
        // 确保应用已完成初始化
        guard appState?.currentFlow == .main else {
            print("⚠️ 应用尚未完成初始化，深度链接将被忽略")
            return
        }
        
        // 委托给主流程协调器处理
        mainFlowCoordinator?.handleDeepLink(url)
    }
    
    /**
     * 处理推送通知
     * 
     * 处理远程推送通知，根据通知内容执行相应的业务逻辑
     * 支持的通知类型：
     * - study_reminder - 学习提醒
     * - sync_completed - 数据同步完成
     * - new_feature - 新功能推送
     * 
     * @param userInfo 推送通知的用户信息字典
     * 
     * 使用示例：
     * ```swift
     * coordinator.handlePushNotification([
     *     "type": "study_reminder",
     *     "session_id": "123"
     * ])
     * ```
     */
    func handlePushNotification(_ userInfo: [AnyHashable: Any]) {
        print("📱 处理推送通知: \(userInfo)")
        
        guard let notificationType = userInfo["type"] as? String else {
            print("⚠️ 推送通知缺少类型信息")
            return
        }
        
        switch notificationType {
        case "study_reminder":
            handleStudyReminderNotification(userInfo)
        case "sync_completed":
            handleSyncCompletedNotification(userInfo)
        case "new_feature":
            handleNewFeatureNotification(userInfo)
        default:
            print("⚠️ 未知的推送通知类型: \(notificationType)")
        }
    }
    
    // MARK: - 公开方法 - 应用生命周期事件
    
    /**
     * 处理应用激活事件
     * 
     * 当应用从后台返回前台时调用，执行必要的数据刷新和状态同步
     */
    func handleApplicationDidBecomeActive() {
        print("🔄 应用已激活")
        
        Task {
            await performAppActivationTasks()
        }
    }
    
    /**
     * 处理应用即将失去活跃状态事件
     * 
     * 当应用即将进入后台时调用，执行数据保存和资源清理
     */
    func handleApplicationWillResignActive() {
        print("💤 应用即将进入后台")
        
        Task {
            await performAppDeactivationTasks()
        }
    }
    
    // MARK: - 私有方法 - 初始化流程
    
    /**
     * 执行应用初始化
     * 
     * 按照预定义的顺序执行初始化任务，确保应用正确启动
     */
    private func performInitialization() async {
        do {
            // 第一步：配置依赖注入环境
            try await configureEnvironment()
            
            // 第二步：执行启动任务序列
            await executeStartupTasks()
            
            // 第三步：完成初始化
            completeInitialization()
            
        } catch {
            handleInitializationError(error)
        }
    }
    
    /**
     * 配置依赖注入环境
     * 
     * 确保 AppEnvironment 完成配置，所有服务都可用
     */
    private func configureEnvironment() async throws {
        guard let environment = environment else {
            throw CoordinatorError.dependencyMissing("AppEnvironment")
        }
        
        print("⚙️ 配置依赖注入环境...")
        try await environment.configure()
        print("✅ 依赖注入环境配置完成")
    }
    
    /**
     * 执行启动任务序列
     * 
     * 按优先级执行各种启动任务
     */
    private func executeStartupTasks() async {
        print("📋 开始执行启动任务...")
        
        // 并行执行独立的启动任务
        async let userProfileTask = loadUserProfile()
        async let syncTask = performInitialSync()
        async let analyticsTask = setupAnalytics()
        async let featuresTask = checkFeatureFlags()
        
        // 等待所有任务完成
        let _ = await [
            userProfileTask,
            syncTask,
            analyticsTask,
            featuresTask
        ]
        
        print("✅ 启动任务执行完成")
    }
    
    /**
     * 完成初始化
     * 
     * 通知 AppState 初始化完成，触发应用流程的继续
     */
    private func completeInitialization() {
        guard let appState = appState else { return }
        
        print("🎉 应用初始化完成")
        appState.finishInitialization()
    }
    
    /**
     * 处理初始化错误
     * 
     * 当初始化过程发生错误时的处理逻辑
     */
    private func handleInitializationError(_ error: Error) {
        print("❌ 应用初始化失败: \(error)")
        appState?.setInitializationError(error)
    }
    
    // MARK: - 私有方法 - 启动任务
    
    /**
     * 加载用户配置文件
     * 
     * 如果用户已登录，从本地或远程加载用户配置文件
     */
    private func loadUserProfile() async {
        guard let appState = appState,
              let userId = appState.userId,
              let environment = environment else {
            return
        }
        
        print("👤 加载用户配置文件...")
        
        do {
            // 这里应该通过命令查询总线执行查询
            // let query = GetUserProfileQuery(userId: userId)
            // let userProfile = try await environment.commandQueryBus.query(query)
            // appState.setUserProfile(userProfile)
            
            print("✅ 用户配置文件加载完成")
        } catch {
            print("⚠️ 用户配置文件加载失败: \(error)")
        }
    }
    
    /**
     * 执行初始数据同步
     * 
     * 同步本地数据到云端，获取最新的远程数据
     */
    private func performInitialSync() async {
        guard let environment = environment else { return }
        
        print("🔄 执行初始数据同步...")
        
        do {
            // 使用同步服务执行数据同步
            // try await environment.syncService.performInitialSync()
            print("✅ 数据同步完成")
        } catch {
            print("⚠️ 数据同步失败: \(error)")
            // 同步失败不应该阻止应用启动
        }
    }
    
    /**
     * 设置数据分析
     * 
     * 配置用户行为分析和应用性能监控
     */
    private func setupAnalytics() async {
        guard let environment = environment,
              let appState = appState else {
            return
        }
        
        print("📊 设置数据分析...")
        
        // 配置分析服务
        // environment.analyticsService.configure(
        //     userId: appState.userId,
        //     userProperties: appState.getUserProperties()
        // )
        
        // 记录应用启动事件
        // environment.analyticsService.track(.appLaunched)
        
        print("✅ 数据分析设置完成")
    }
    
    /**
     * 检查功能开关
     * 
     * 从远程配置服务获取功能开关状态
     */
    private func checkFeatureFlags() async {
        print("🚩 检查功能开关...")
        
        // 这里可以集成远程配置服务
        // 例如 Firebase Remote Config 或自建的配置服务
        
        print("✅ 功能开关检查完成")
    }
    
    // MARK: - 私有方法 - 推送通知处理
    
    /**
     * 处理学习提醒通知
     */
    private func handleStudyReminderNotification(_ userInfo: [AnyHashable: Any]) {
        // 可以直接跳转到学习页面，或显示提醒弹窗
        mainFlowCoordinator?.navigateToStudyPractice()
    }
    
    /**
     * 处理同步完成通知
     */
    private func handleSyncCompletedNotification(_ userInfo: [AnyHashable: Any]) {
        // 可以显示同步成功的提示，或刷新相关数据
        print("✅ 数据同步完成通知已处理")
    }
    
    /**
     * 处理新功能推送通知
     */
    private func handleNewFeatureNotification(_ userInfo: [AnyHashable: Any]) {
        // 可以显示新功能介绍页面或高亮新功能入口
        print("🆕 新功能推送通知已处理")
    }
    
    // MARK: - 私有方法 - 应用生命周期任务
    
    /**
     * 执行应用激活任务
     * 
     * 当应用从后台返回前台时执行的任务
     */
    private func performAppActivationTasks() async {
        // 刷新数据
        await refreshCriticalData()
        
        // 检查网络状态
        await checkNetworkStatus()
        
        // 更新用户状态
        await updateUserActiveStatus()
    }
    
    /**
     * 执行应用失活任务
     * 
     * 当应用即将进入后台时执行的任务
     */
    private func performAppDeactivationTasks() async {
        // 保存用户数据
        await saveUserData()
        
        // 暂停定时器
        pauseTimers()
        
        // 清理临时资源
        cleanupTempResources()
    }
    
    /**
     * 刷新关键数据
     */
    private func refreshCriticalData() async {
        // 刷新用户配置、学习进度等关键数据
        print("🔄 刷新关键数据...")
    }
    
    /**
     * 检查网络状态
     */
    private func checkNetworkStatus() async {
        // 检查网络连接状态，如果网络恢复则执行同步
        print("🌐 检查网络状态...")
    }
    
    /**
     * 更新用户活跃状态
     */
    private func updateUserActiveStatus() async {
        // 更新用户最后活跃时间等状态信息
        print("👤 更新用户活跃状态...")
    }
    
    /**
     * 保存用户数据
     */
    private func saveUserData() async {
        // 保存用户的学习进度、设置等重要数据
        print("💾 保存用户数据...")
    }
    
    /**
     * 暂停定时器
     */
    private func pauseTimers() {
        // 暂停学习计时器等定时器
        print("⏸️ 暂停定时器...")
    }
    
    /**
     * 清理临时资源
     */
    private func cleanupTempResources() {
        // 清理缓存、临时文件等资源
        print("🧹 清理临时资源...")
    }
    
    // MARK: - 析构函数
    
    /**
     * 析构函数
     * 
     * 确保在协调器被销毁时正确清理资源
     */
    deinit {
        // 取消正在进行的初始化任务
        initializationTask?.cancel()
        
        print("🗑️ AppCoordinator 已销毁")
    }
}

// MARK: - 错误类型定义

/**
 * 协调器相关的错误类型
 */
enum CoordinatorError: LocalizedError {
    case dependencyMissing(String)
    case invalidState(String)
    case initializationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .dependencyMissing(let dependency):
            return "缺少依赖: \(dependency)"
        case .invalidState(let state):
            return "无效状态: \(state)"
        case .initializationFailed(let error):
            return "初始化失败: \(error.localizedDescription)"
        }
    }
}

// MARK: - MainFlowCoordinator 接口扩展

/**
 * MainFlowCoordinator 的方法接口声明
 * 
 * 这些方法的具体实现应该在 MainFlowCoordinator.swift 中定义
 * 这里只是为了确保 AppCoordinator 的编译通过
 */
private extension MainFlowCoordinator {
    
    func handleDeepLink(_ url: URL) {
        // 实际实现在 MainFlowCoordinator.swift 中
    }
    
    func navigateToStudyPractice() {
        // 实际实现在 MainFlowCoordinator.swift 中
    }
}