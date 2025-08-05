import SwiftUI
import SwiftData

/// NotBad错题本应用主入口点
/// 
/// 职责：
/// - 作为SwiftUI应用的主入口点
/// - 初始化全局依赖容器
/// - 配置SwiftData模型容器
/// - 设置应用级别的配置
///
/// 架构说明：
/// - 遵循Clean Architecture原则，仅负责应用启动
/// - 依赖注入通过AppEnvironment进行管理
/// - 状态管理通过AppState集中处理
@main
struct NotBadApp: App {
    
    // MARK: - Properties
    
    /// 全局应用环境和依赖注入容器
    /// 使用@StateObject确保整个应用生命周期内单例存在
    @StateObject private var appEnvironment = AppEnvironment()
    
    /// 全局应用状态管理
    /// 使用@StateObject确保状态的持久性和响应性
    @StateObject private var appState = AppState()
    
    // MARK: - SwiftData Configuration
    
    /// SwiftData模型容器配置
    /// 配置应用的数据持久化模型
    private var modelContainer: ModelContainer {
        do {
            let container = try ModelContainer(
                for: QuestionDataModel.self,
                     StudySessionDataModel.self,
                     UserProfileDataModel.self
            )
            return container
        } catch {
            // 在生产环境中，这里应该使用专业的崩溃报告服务
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }
    
    // MARK: - App Body
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appEnvironment)
                .environmentObject(appState)
                .modelContainer(modelContainer)
                .onAppear {
                    configureApp()
                }
        }
    }
    
    // MARK: - Private Methods
    
    /// 配置应用启动时的全局设置
    /// 
    /// 包括：
    /// - 日志系统初始化
    /// - 分析服务配置
    /// - 崩溃报告设置
    /// - 网络监控启动
    private func configureApp() {
        #if DEBUG
        print("🚀 NotBad App 启动 - Debug 模式")
        #else
        print("🚀 NotBad App 启动 - Release 模式")
        #endif
        
        // 配置全局应用设置
        setupGlobalConfiguration()
        
        // 初始化分析服务
        initializeAnalytics()
        
        // 启动网络监控
        startNetworkMonitoring()
    }
    
    /// 设置全局应用配置
    private func setupGlobalConfiguration() {
        // 配置应用外观
        configureAppAppearance()
        
        // 配置网络请求
        configureNetworking()
    }
    
    /// 配置应用外观主题
    private func configureAppAppearance() {
        // 配置导航栏外观
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.systemBackground
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // 配置TabBar外观
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    /// 配置网络请求默认设置
    private func configureNetworking() {
        // 配置URLSession默认设置
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        configuration.waitsForConnectivity = true
        
        // 这里可以添加更多网络配置
        // 例如：SSL证书绑定、请求头设置等
    }
    
    /// 初始化分析服务
    private func initializeAnalytics() {
        #if !DEBUG
        // 在生产环境中初始化分析服务
        // 例如：Firebase Analytics, Mixpanel等
        appEnvironment.analyticsService.initialize()
        #endif
    }
    
    /// 启动网络监控
    private func startNetworkMonitoring() {
        appEnvironment.networkMonitor.startMonitoring()
    }
}

// MARK: - Preview Support

#if DEBUG
/// SwiftUI预览支持
/// 仅在Debug模式下编译，用于Xcode预览功能
struct NotBadApp_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AppEnvironment())
            .environmentObject(AppState())
    }
}
#endif