import SwiftUI

// MARK: - NotBad App Main Entry Point
// 位置: App/NotBadApp.swift

/// NotBad错题记录App主入口
@main
struct NotBadApp: App {
    
    // MARK: - Properties
    
    /// 应用环境依赖注入容器
    @StateObject private var appEnvironment = AppEnvironment()
    
    /// 根协调器
    @StateObject private var appCoordinator = AppCoordinator()
    
    // MARK: - App Body
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appEnvironment)
                .environmentObject(appCoordinator)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    // MARK: - Private Methods
    
    /// 应用初始化设置
    private func setupApp() {
        // 配置应用环境
        configureAppEnvironment()
        
        // 启动根协调器
        appCoordinator.start()
        
        // 配置全局外观
        configureAppearance()
    }
    
    /// 配置应用环境
    private func configureAppEnvironment() {
        // TODO: 初始化各种服务
        // appEnvironment.setup()
    }
    
    /// 配置应用外观
    private func configureAppearance() {
        // 配置导航栏外观
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor.systemBackground
        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        navigationBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 32, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        
        // 配置Tab Bar外观
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // 配置色调
        UIView.appearance().tintColor = UIColor.systemBlue
    }
}

// MARK: - RootView

/// 应用根视图
struct RootView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    var body: some View {
        appCoordinator.getRootView()
            .preferredColorScheme(nil) // 跟随系统主题
    }
}

// MARK: - AppEnvironment

/// 应用环境依赖注入容器
/// 负责管理全局服务和配置
@MainActor
class AppEnvironment: ObservableObject {
    
    // MARK: - Services
    // TODO: 注入各种服务实例
    
    // Core Services
    // let authenticationService: AuthenticationService
    // let userService: UserService
    // let questionService: QuestionService
    // let studyService: StudyService
    
    // Infrastructure Services
    // let networkService: NetworkService
    // let databaseService: DatabaseService
    // let cacheService: CacheService
    // let fileService: FileService
    
    // External Services
    // let ocrService: OCRService
    // let analyticsService: AnalyticsService
    // let notificationService: NotificationService
    
    // MARK: - Configuration
    
    /// 应用配置
    @Published var appConfiguration: AppConfiguration
    
    /// 应用状态
    @Published var appState: AppState
    
    // MARK: - Initialization
    
    init() {
        // 初始化配置和状态
        self.appConfiguration = AppConfiguration()
        self.appState = AppState()
        
        // TODO: 初始化服务依赖
        setupServices()
    }
    
    // MARK: - Setup Methods
    
    /// 设置服务依赖
    private func setupServices() {
        // TODO: 实现服务初始化
        // 1. 初始化核心服务
        // 2. 配置网络服务
        // 3. 设置数据库连接
        // 4. 注册通知服务
        // 5. 启动分析服务
    }
}

// MARK: - AppConfiguration

/// 应用配置管理
struct AppConfiguration {
    
    // MARK: - Environment
    
    /// 当前环境
    let environment: Environment
    
    // MARK: - API Configuration
    
    /// API基础URL
    let apiBaseURL: String
    
    /// API超时时间
    let apiTimeout: TimeInterval
    
    // MARK: - Feature Flags
    
    /// 功能开关
    let featureFlags: FeatureFlags
    
    // MARK: - Initialization
    
    init() {
        #if DEBUG
        self.environment = .development
        self.apiBaseURL = "https://api-dev.notbad.com"
        #elseif STAGING
        self.environment = .staging
        self.apiBaseURL = "https://api-staging.notbad.com"
        #else
        self.environment = .production
        self.apiBaseURL = "https://api.notbad.com"
        #endif
        
        self.apiTimeout = 30.0
        self.featureFlags = FeatureFlags()
    }
    
    // MARK: - Environment Enum
    
    enum Environment {
        case development
        case staging
        case production
    }
}

// MARK: - AppState

/// 全局应用状态
@Observable
class AppState {
    
    // MARK: - Authentication State
    
    /// 认证状态
    var isAuthenticated: Bool = false
    
    /// 当前用户
    var currentUser: User?
    
    // MARK: - Network State
    
    /// 网络连接状态
    var isNetworkConnected: Bool = true
    
    /// 网络类型
    var networkType: NetworkType = .wifi
    
    // MARK: - App State
    
    /// 应用是否在前台
    var isAppActive: Bool = true
    
    /// 应用版本
    let appVersion: String
    
    /// 构建版本
    let buildVersion: String
    
    // MARK: - Initialization
    
    init() {
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        self.buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Network Type Enum
    
    enum NetworkType {
        case wifi
        case cellular
        case none
    }
}

// MARK: - FeatureFlags

/// 功能开关配置
struct FeatureFlags {
    
    // MARK: - Core Features
    
    /// 启用OCR功能
    let enableOCR: Bool = true
    
    /// 启用社交功能
    let enableSocialFeatures: Bool = true
    
    /// 启用AI推荐
    let enableAIRecommendations: Bool = true
    
    // MARK: - iOS 18 Features
    
    /// 启用控制中心小组件
    let enableControlCenterWidgets: Bool = true
    
    /// 启用实时活动
    let enableLiveActivities: Bool = true
    
    /// 启用App Intents
    let enableAppIntents: Bool = true
    
    // MARK: - Analytics
    
    /// 启用数据分析
    let enableAnalytics: Bool = true
    
    /// 启用崩溃报告
    let enableCrashReporting: Bool = true
    
    // MARK: - Development
    
    /// 显示调试信息
    let showDebugInfo: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
}

// MARK: - Temporary User Model

/// 临时用户模型（后续会移到Domain层）
struct User {
    let id: String
    let username: String
    let email: String?
    let profileImageURL: String?
    let createdAt: Date
}

// MARK: - Preview

#if DEBUG
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AppEnvironment())
            .environmentObject(AppCoordinator())
    }
}
#endif
