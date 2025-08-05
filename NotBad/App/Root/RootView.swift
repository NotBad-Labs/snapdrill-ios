// MARK: - RootView.swift
/**
 * 应用根视图容器
 * 
 * 职责：
 * - 作为应用的根视图容器，负责根据应用状态渲染对应的界面
 * - 管理应用级别的视图转场和动画效果
 * - 处理全局的 UI 状态（如加载遮罩、错误提示等）
 * - 响应应用状态变化，动态切换不同的视图流程
 * 
 * 设计原则：
 * - 状态驱动：完全基于 AppState 的状态来决定显示内容
 * - 视图纯净：不包含业务逻辑，只负责视图的渲染和转场
 * - 响应式：使用 @EnvironmentObject 响应状态变化
 * - 用户体验：提供流畅的转场动画和加载反馈
 * 
 * 架构位置：
 * ```
 * NotBadApp
 *     ↓ 创建根视图
 * RootView (这里) ← 根视图容器
 *     ↓ 根据状态选择视图
 * SplashView / OnboardingView / MainTabView ← 具体视图
 * ```
 * 
 * 状态流转：
 * ```
 * SplashView (初始化) 
 *     ↓ 完成初始化
 * OnboardingView (首次使用) / MainTabView (非首次)
 *     ↓ 完成引导
 * MainTabView (主应用界面)
 * ```
 * 
 * 使用方式：
 * - 该视图作为应用的根视图，在 NotBadApp.swift 中使用
 * - 通过环境对象获取状态和依赖
 * - 自动响应状态变化并更新 UI
 * 
 * 注意事项：
 * - 该视图不应包含任何业务逻辑
 * - 所有状态变更都应通过 AppState 进行
 * - 转场动画应该保持简洁和一致
 * - 错误状态的处理应该用户友好
 * 
 * @author NotBad Team
 * @since 1.0.0
 * @updated 2025-08-01
 */

import SwiftUI

struct RootView: View {
    
    // MARK: - 环境依赖
    
    /// 全局应用状态，用于决定显示哪个视图
    @EnvironmentObject private var appState: AppState
    
    /// 应用协调器，用于处理导航相关的业务逻辑
    @EnvironmentObject private var appCoordinator: AppCoordinator
    
    /// 依赖注入环境，提供各种服务的访问
    @EnvironmentObject private var appEnvironment: AppEnvironment
    
    // MARK: - 本地状态
    
    /// 是否显示全局加载遮罩
    @State private var showGlobalLoading = false
    
    /// 全局错误提示信息
    @State private var globalError: GlobalError?
    
    /// 是否显示网络连接错误提示
    @State private var showNetworkError = false
    
    // MARK: - 主视图
    
    var body: some View {
        ZStack {
            // 主内容区域
            mainContentView
                .transition(currentTransition)
                .animation(.easeInOut(duration: 0.4), value: appState.currentFlow)
            
            // 全局覆盖层
            globalOverlayView
        }
        .onAppear {
            handleViewAppear()
        }
        .onReceive(NotificationCenter.default.publisher(for: .networkStatusChanged)) { notification in
            handleNetworkStatusChange(notification)
        }
        .alert("网络连接错误", isPresented: $showNetworkError) {
            Button("重试") {
                handleNetworkRetry()
            }
            Button("离线继续") {
                showNetworkError = false
            }
        } message: {
            Text("网络连接不稳定，部分功能可能无法正常使用。")
        }
        .alert(item: $globalError) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                primaryButton: .default(Text("重试")) {
                    error.retryAction?()
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
    }
    
    // MARK: - 主内容视图
    
    /**
     * 主内容视图
     * 
     * 根据当前应用状态显示对应的视图内容
     */
    @ViewBuilder
    private var mainContentView: some View {
        switch appState.currentFlow {
        case .splash:
            SplashView()
                .id("splash") // 提供稳定的标识符用于动画
            
        case .onboarding:
            OnboardingContainerView()
                .id("onboarding")
            
        case .main:
            MainTabContainerView()
                .id("main")
                .onAppear {
                    handleMainViewAppear()
                }
        }
    }
    
    /**
     * 全局覆盖层视图
     * 
     * 显示全局的加载、错误、提示等覆盖内容
     */
    @ViewBuilder
    private var globalOverlayView: some View {
        // 全局加载遮罩
        if showGlobalLoading {
            GlobalLoadingView()
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: showGlobalLoading)
        }
    }
    
    // MARK: - 计算属性
    
    /**
     * 当前转场动画
     * 
     * 根据不同的状态转换提供合适的转场动画
     */
    private var currentTransition: AnyTransition {
        switch appState.currentFlow {
        case .splash:
            return .opacity
            
        case .onboarding:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
            
        case .main:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
    }
    
    // MARK: - 事件处理方法
    
    /**
     * 处理视图出现事件
     * 
     * 执行一些初始化操作，如网络状态检查等
     */
    private func handleViewAppear() {
        print("🎨 RootView 已出现")
        
        // 检查网络状态
        checkNetworkStatus()
        
        // 设置全局 UI 配置
        setupGlobalUIConfiguration()
    }
    
    /**
     * 处理主视图出现事件
     * 
     * 当切换到主界面时执行的操作
     */
    private func handleMainViewAppear() {
        print("🏠 主界面已显示")
        
        // 通知协调器显示主流程
        appCoordinator.showMainFlow()
        
        // 隐藏全局加载
        showGlobalLoading = false
    }
    
    /**
     * 处理网络状态变化
     */
    private func handleNetworkStatusChange(_ notification: Notification) {
        guard let isConnected = notification.userInfo?["isConnected"] as? Bool else {
            return
        }
        
        if !isConnected && appState.currentFlow == .main {
            showNetworkError = true
        } else if isConnected && showNetworkError {
            showNetworkError = false
        }
    }
    
    /**
     * 处理网络重试
     */
    private func handleNetworkRetry() {
        showNetworkError = false
        showGlobalLoading = true
        
        Task {
            // 延迟隐藏加载，给用户反馈感
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
            await MainActor.run {
                showGlobalLoading = false
            }
        }
    }
    
    // MARK: - 私有辅助方法
    
    /**
     * 检查网络状态
     */
    private func checkNetworkStatus() {
        // 这里可以集成网络状态监控
        // 例如使用 Network framework 或第三方库
        print("🌐 检查网络状态...")
    }
    
    /**
     * 设置全局 UI 配置
     */
    private func setupGlobalUIConfiguration() {
        // 根据配置设置全局 UI 样式
        if let configuration = appEnvironment.configuration {
            setupAnimationConfiguration(configuration)
            setupThemeConfiguration(configuration)
        }
    }
    
    /**
     * 设置动画配置
     */
    private func setupAnimationConfiguration(_ config: AppConfiguration) {
        // 根据配置决定是否启用动画
        if !config.enableAnimations {
            // 禁用动画的逻辑
            print("🎭 动画已禁用")
        }
    }
    
    /**
     * 设置主题配置
     */
    private func setupThemeConfiguration(_ config: AppConfiguration) {
        // 根据配置设置主题
        print("🎨 设置主题: \(config.defaultTheme.displayName)")
    }
}

// MARK: - 子视图组件

/**
 * 启动页视图
 * 
 * 显示应用启动时的加载界面
 */
struct SplashView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 应用图标和名称
                appLogoSection
                
                // 加载状态指示器
                loadingSection
                
                // 错误信息显示
                errorSection
            }
            .padding(.horizontal, 40)
        }
    }
    
    /**
     * 应用 Logo 区域
     */
    @ViewBuilder
    private var appLogoSection: some View {
        VStack(spacing: 16) {
            // 应用图标
            Image(systemName: "book.fill")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(.white)
                .scaleEffect(appState.isInitializing ? 1.0 : 1.1)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: appState.isInitializing
                )
            
            // 应用名称
            Text("NotBad")
                .font(.largeTitle)
                .fontWeight(.light)
                .foregroundColor(.white)
                .opacity(0.9)
        }
    }
    
    /**
     * 加载状态区域
     */
    @ViewBuilder
    private var loadingSection: some View {
        if appState.isInitializing {
            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text("初始化中...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    /**
     * 错误信息区域
     */
    @ViewBuilder
    private var errorSection: some View {
        if let error = appState.initializationError {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("初始化失败")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

/**
 * 引导页容器视图
 * 
 * 包装引导页流程的容器
 */
struct OnboardingContainerView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        OnboardingView()
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))
    }
}

/**
 * 主界面容器视图
 * 
 * 包装主应用界面的容器
 */
struct MainTabContainerView: View {
    var body: some View {
        // 这里会被 MainFlowCoordinator 管理的 MainTabView 替换
        // 目前先显示占位内容
        VStack {
            Text("主界面加载中...")
                .font(.title2)
                .foregroundColor(.secondary)
            
            ProgressView()
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

/**
 * 引导页视图
 * 
 * 简化的引导页实现
 */
struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 欢迎内容
            VStack(spacing: 20) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("欢迎使用 NotBad")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("让错题本帮助你更好地学习")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // 引导步骤指示器
            OnboardingStepIndicator()
            
            // 操作按钮
            VStack(spacing: 16) {
                Button("开始使用") {
                    appState.completeOnboarding()
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("跳过引导") {
                    appState.completeOnboarding()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 30)
        .background(Color(.systemBackground))
    }
}

/**
 * 引导步骤指示器
 */
struct OnboardingStepIndicator: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(AppState.OnboardingStep.allCases.indices, id: \.self) { index in
                Circle()
                    .fill(index <= currentStepIndex ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentStepIndex)
            }
        }
    }
    
    private var currentStepIndex: Int {
        AppState.OnboardingStep.allCases.firstIndex(of: appState.onboardingStep) ?? 0
    }
}

/**
 * 全局加载视图
 * 
 * 全屏的加载遮罩
 */
struct GlobalLoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("加载中...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

// MARK: - 按钮样式

/**
 * 主要按钮样式
 */
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/**
 * 次要按钮样式
 */
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(.blue)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 支持类型

/**
 * 全局错误类型
 * 
 * 用于显示全局错误弹窗
 */
struct GlobalError: Identifiable {
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

// MARK: - 通知扩展

extension Notification.Name {
    /// 网络状态变化通知
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}