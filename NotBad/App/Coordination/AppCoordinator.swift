//
//  AppCoordinator.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/7/29.
//


import SwiftUI
import Foundation

// MARK: - AppCoordinator
// 位置: App/Navigation/AppCoordinator.swift

/// 应用程序的根协调器
/// 负责管理应用级别的导航：启动页 → 引导页 → 认证 → 主应用流程
@MainActor
@Observable
class AppCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    /// 当前的应用流程
    private(set) var currentFlow: AppFlow = .splash
    
    /// 主Tab协调器
    var tabCoordinator: TabCoordinator?
    
    // MARK: - Dependencies
    // TODO: 注入必要的服务
    // private let authenticationService: AuthenticationService
    // private let userPreferencesService: UserPreferencesService
    // private let appConfigurationService: AppConfigurationService
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - CoordinatorProtocol
    
    override func start() {
        // 根据应用状态决定初始流程
        determineInitialFlow()
    }
    
    override func stop() {
        tabCoordinator?.stop()
        tabCoordinator = nil
        super.stop()
    }
    
    override func getRootView() -> AnyView {
        AnyView(AppCoordinatorView(coordinator: self))
    }
    
    // MARK: - Navigation Methods
    
    /// 导航到指定流程
    func navigate(to flow: AppFlow) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentFlow = flow
        }
        
        switch flow {
        case .splash:
            // 启动页处理
            break
            
        case .onboarding:
            // 引导页处理
            break
            
        case .authentication:
            // 认证页处理
            break
            
        case .mainFlow:
            setupMainFlow()
        }
    }
    
    // MARK: - Private Methods
    
    /// 确定初始流程
    private func determineInitialFlow() {
        // 模拟启动检查
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if self.isFirstLaunch() {
                self.navigate(to: .onboarding)
            } else if self.isUserAuthenticated() {
                self.navigate(to: .mainFlow)
            } else {
                self.navigate(to: .authentication)
            }
        }
    }
    
    /// 设置主应用流程
    func setupMainFlow() {
        if tabCoordinator == nil {
            tabCoordinator = TabCoordinator()
            addChild(tabCoordinator!)
            tabCoordinator?.start()
        }
    }
    
    /// 检查是否首次启动
    private func isFirstLaunch() -> Bool {
        // TODO: 实现首次启动检查逻辑
        // return !UserDefaults.standard.bool(forKey: "HasLaunchedBefore")
        return false // 暂时返回false，直接跳过引导页
    }
    
    /// 检查用户认证状态
    private func isUserAuthenticated() -> Bool {
        // TODO: 实现认证状态检查
        // return authenticationService.isAuthenticated
        return true // 暂时返回true，直接进入主应用
    }
}

// MARK: - AppCoordinatorView

/// AppCoordinator的根视图
struct AppCoordinatorView: View {
    @State var coordinator: AppCoordinator
    
    var body: some View {
        Group {
            switch coordinator.currentFlow {
            case .splash:
                SplashView {
                    coordinator.start()
                }
                
            case .onboarding:
                OnboardingPlaceholderView {
                    coordinator.navigate(to: .authentication)
                }
                
            case .authentication:
                AuthenticationPlaceholderView {
                    coordinator.navigate(to: .mainFlow)
                }
                
            case .mainFlow:
                if let tabCoordinator = coordinator.tabCoordinator {
                    tabCoordinator.getRootView()
                } else {
                    SplashView {
                        coordinator.setupMainFlow()
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.currentFlow)
    }
}

// MARK: - 临时占位视图

/// 启动页视图
struct SplashView: View {
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.4, blue: 0.8),
                    Color(red: 0.1, green: 0.3, blue: 0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // App图标
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "book.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    )
                    .scaleEffect(0.8)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: true
                    )
                
                VStack(spacing: 8) {
                    Text("NotBad")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("错题记录助手")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onComplete()
            }
        }
    }
}

/// 引导页占位视图
struct OnboardingPlaceholderView: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("欢迎使用 NotBad")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("让错题记录变得简单高效")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button("开始使用") {
                onComplete()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 32)
    }
}

/// 认证页占位视图
struct AuthenticationPlaceholderView: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("登录 NotBad")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("登录后可同步数据到云端")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button("登录") {
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("游客模式") {
                    onComplete()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 32)
    }
}