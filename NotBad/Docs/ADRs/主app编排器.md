#NotBadApp - Main Application (极简模块化架构)
// 主应用仅作为模块编排器，不包含业务逻辑

import SwiftUI
import SwiftData

// MARK: - 主应用入口（极其简洁）
@main
struct NotBadApp: App {
    // 依赖注入容器 - 所有模块的中枢
    @StateObject private var container = DependencyContainer()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(container)
                .task {
                    // 启动时初始化所有模块
                    await container.bootstrap()
                }
        }
    }
}

// MARK: - 依赖注入容器（核心中枢）
@MainActor
final class DependencyContainer: ObservableObject {
    
    // 模块协调器 - 管理所有模块
    private let coordinator = ModuleCoordinator()
    
    // 模块懒加载属性
    private(set) lazy var dataModule = DataModule()
    private(set) lazy var authModule = AuthModule()
    private(set) lazy var syncModule = SyncModule()
    private(set) lazy var ocrModule = OCRModule()
    private(set) lazy var uiModule = UIModule()
    private(set) lazy var reviewModule = ReviewModule()
    
    // 应用状态（仅路由相关）
    @Published var currentRoute: AppRoute = .splash
    @Published var isAuthenticated = false
    
    // 初始化所有模块
    func bootstrap() async {
        // 1. 注册模块
        await registerModules()
        
        // 2. 配置模块间通信
        await setupModuleCommunication()
        
        // 3. 初始化核心服务
        await initializeCoreServices()
        
        // 4. 恢复应用状态
        await restoreAppState()
    }
    
    private func registerModules() async {
        // 注册所有23个模块到协调器
        await coordinator.register(module: dataModule.container, as: SwiftDataContainerProtocol.self, identifier: "data.container")
        await coordinator.register(module: dataModule.syncEngine, as: SyncEngineProtocol.self, identifier: "data.sync")
        await coordinator.register(module: ocrModule.engine, as: UnifiedOCRProtocol.self, identifier: "ai.ocr")
        await coordinator.register(module: reviewModule.scheduler, as: ReviewSchedulerProtocol.self, identifier: "review.scheduler")
        // ... 其他模块注册
    }
    
    private func setupModuleCommunication() async {
        // 设置模块间事件订阅
        coordinator.subscribe(to: "auth", eventType: "LoginSuccess") { [weak self] _ in
            await MainActor.run {
                self?.isAuthenticated = true
                self?.currentRoute = .home
            }
        }
        
        coordinator.subscribe(to: "sync", eventType: "SyncCompleted") { event in
            // 处理同步完成事件
            print("Sync completed: \(event)")
        }
    }
    
    private func initializeCoreServices() async {
        // 初始化数据容器
        _ = try? await dataModule.container.initialize(
            models: [StudyItem.self, Subject.self, Tag.self],
            configuration: .default
        )
        
        // 检查认证状态
        if await authModule.bioAuth.checkAvailability().isAvailable {
            // 配置生物识别
        }
    }
    
    private func restoreAppState() async {
        // 恢复上次的应用状态
        if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            currentRoute = isAuthenticated ? .home : .login
        } else {
            currentRoute = .onboarding
        }
    }
}

// MARK: - 根视图（纯路由）
struct RootView: View {
    @EnvironmentObject var container: DependencyContainer
    
    var body: some View {
        // 仅负责路由，不包含业务逻辑
        RouterView(route: container.currentRoute) {
            switch container.currentRoute {
            case .splash:
                SplashScreen()
                
            case .onboarding:
                OnboardingFlow()
                    .environmentObject(container.authModule)
                
            case .login:
                LoginScreen()
                    .environmentObject(container.authModule)
                
            case .home:
                HomeTabView()
                    .injectModules(from: container)
                
            case .settings:
                SettingsScreen()
                    .environmentObject(container.uiModule)
            }
        }
        .animation(.smooth, value: container.currentRoute)
    }
}

// MARK: - 应用路由定义
enum AppRoute: Hashable {
    case splash
    case onboarding
    case login
    case home
    case settings
}

// MARK: - 路由视图包装器
struct RouterView<Content: View>: View {
    let route: AppRoute
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
            .transition(routeTransition(for: route))
    }
    
    private func routeTransition(for route: AppRoute) -> AnyTransition {
        switch route {
        case .splash:
            return .opacity
        case .onboarding, .login:
            return .asymmetric(insertion: .push(from: .trailing), removal: .push(from: .leading))
        case .home, .settings:
            return .asymmetric(insertion: .scale.combined(with: .opacity), removal: .scale.combined(with: .opacity))
        }
    }
}

// MARK: - 模块化视图扩展
extension View {
    /// 便捷方法：注入所需模块
    func injectModules(from container: DependencyContainer) -> some View {
        self
            .environmentObject(container.dataModule)
            .environmentObject(container.syncModule)
            .environmentObject(container.ocrModule)
            .environmentObject(container.reviewModule)
            .environmentObject(container.uiModule)
    }
}

// MARK: - 主Tab视图（组合模块提供的视图）
struct HomeTabView: View {
    @EnvironmentObject var container: DependencyContainer
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 每个Tab都是独立模块提供的
            container.reviewModule.reviewView
                .tabItem {
                    Label("学习", systemImage: "book.fill")
                }
                .tag(0)
            
            container.reviewModule.scheduleView
                .tabItem {
                    Label("复习", systemImage: "clock.fill")
                }
                .tag(1)
            
            container.dataModule.statisticsView
                .tabItem {
                    Label("统计", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
            
            container.uiModule.settingsView
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
    }
}

// MARK: - 模块定义示例

// ==========================================
// 数据模块 - 封装所有数据相关功能
// ==========================================
@MainActor
final class DataModule: ObservableObject {
    // 子模块
    let container = SwiftDataContainerImpl()
    let syncEngine = SyncEngineImpl()
    let tagManager = TagManagerImpl()
    let statisticsManager = StatisticsManagerImpl()
    let exporter = DataExporterImpl()
    let imageCompressor = ImageCompressorImpl()
    
    // 模块提供的视图
    var statisticsView: some View {
        StatisticsScreen()
            .environmentObject(self)
    }
    
    // 模块公开的简化API
    func saveItem(_ item: StudyItem) async throws {
        // 内部协调多个子模块
        let compressed = try await imageCompressor.compress(image: item.images)
        item.compressedImages = compressed
        try await container.save(item)
        await syncEngine.scheduleSync()
    }
}

// ==========================================
// OCR模块 - 封装所有OCR相关功能
// ==========================================
@MainActor
final class OCRModule: ObservableObject {
    let engine = UnifiedOCRImpl()
    let capture = SmartCaptureImpl()
    let mistakeTagger = MistakeTaggerImpl()
    
    // 模块提供的高级API
    func processImage(_ image: UIImage) async throws -> ProcessedResult {
        // 1. 智能捕获处理
        let processed = try await capture.detectAndCorrect(image)
        
        // 2. OCR识别
        let ocrResult = try await engine.recognize(from: processed, options: .default)
        
        // 3. 智能标记
        let tags = await mistakeTagger.suggestTags(for: ocrResult)
        
        return ProcessedResult(text: ocrResult.text, tags: tags)
    }
    
    struct ProcessedResult {
        let text: String
        let tags: [Tag]
    }
}

// ==========================================
// 复习模块 - 封装所有复习相关功能
// ==========================================
@MainActor
final class ReviewModule: ObservableObject {
    let scheduler = ReviewSchedulerImpl()
    let sessionManager = ReviewSessionManagerImpl()
    let flashcardGenerator = FlashcardGeneratorImpl()
    let knowledgeNavigator = KnowledgeNavigatorImpl()
    
    // 模块提供的视图
    var reviewView: some View {
        ReviewScreen()
            .environmentObject(self)
    }
    
    var scheduleView: some View {
        ScheduleScreen()
            .environmentObject(self)
    }
    
    // 高级复习API
    func startSmartReview() async throws -> ReviewSession {
        // 1. 获取待复习项目
        let items = await scheduler.getTodayReviewTasks()
        
        // 2. 生成闪卡
        let flashcards = try await flashcardGenerator.generateDeck(from: items.map(\.item), theme: .default)
        
        // 3. 开始会话
        return try await sessionManager.startSession(
            with: items.map(\.item),
            configuration: .smartReview
        )
    }
}

// ==========================================
// 认证模块 - 封装所有认证相关功能
// ==========================================
@MainActor
final class AuthModule: ObservableObject {
    let bioAuth = BioAuthKitImpl()
    let privacyGuard = PrivacyGuardImpl()
    let complianceManager = ComplianceManagerImpl()
    
    @Published var authState: AuthState = .unauthenticated
    
    // 统一认证接口
    func authenticate() async throws {
        // 1. 检查生物识别
        let availability = await bioAuth.checkAvailability()
        
        if availability.isAvailable {
            // 2. 执行生物识别
            let result = try await bioAuth.authenticate(
                reason: "访问您的学习数据",
                fallback: .passcode
            )
            
            if result.success {
                // 3. 解密用户数据
                await privacyGuard.unlockUserData()
                authState = .authenticated(userId: getCurrentUserId())
            }
        }
    }
    
    private func getCurrentUserId() -> UUID {
        // 获取当前用户ID
        UUID()
    }
}

enum AuthState {
    case unauthenticated
    case authenticating
    case authenticated(userId: UUID)
}

// ==========================================
// UI模块 - 封装所有UI相关功能
// ==========================================
@MainActor
final class UIModule: ObservableObject {
    let uiFactory = UIKitFactoryImpl()
    let syncStatusView = SyncStatusViewImpl()
    let performanceMonitor = PerformanceMonitorImpl()
    let errorHandler = ErrorHandlerImpl()
    
    @Published var theme: AppTheme = .system
    @Published var deviceConfig: DeviceConfiguration = .automatic
    
    // 模块提供的视图
    var settingsView: some View {
        SettingsScreen()
            .environmentObject(self)
    }
    
    // UI配置API
    func configureForDevice() async {
        let device = await UIDevice.current.userInterfaceIdiom
        deviceConfig = DeviceConfiguration(for: device)
        
        // 通知所有模块更新UI配置
        await uiFactory.updateConfiguration(deviceConfig)
    }
}

// MARK: - 设备配置
struct DeviceConfiguration {
    let columns: Int
    let spacing: CGFloat
    let useSplitView: Bool
    
    init(for device: UIUserInterfaceIdiom) {
        switch device {
        case .phone:
            self.columns = 1
            self.spacing = 16
            self.useSplitView = false
        case .pad:
            self.columns = 2
            self.spacing = 24
            self.useSplitView = true
        default:
            self.columns = 1
            self.spacing = 16
            self.useSplitView = false
        }
    }
    
    static let automatic = DeviceConfiguration(for: .phone)
}

// MARK: - 应用主题
enum AppTheme {
    case system
    case light
    case dark
    case custom(ColorScheme)
}

// MARK: - 模块协调器实现
actor ModuleCoordinator {
    private var modules: [String: any Actor] = [:]
    private var subscriptions: [SubscriptionToken: EventHandler] = [:]
    
    typealias EventHandler = @Sendable (ModuleEvent) async -> Void
    
    func register<T>(module: T, as type: T.Type, identifier: String) where T: Actor {
        modules[identifier] = module
    }
    
    func getModule<T>(_ type: T.Type, identifier: String?) async -> T? where T: Actor {
        guard let id = identifier else { return nil }
        return modules[id] as? T
    }
    
    @discardableResult
    func subscribe(to moduleId: String, eventType: String, handler: @escaping EventHandler) -> SubscriptionToken {
        let token = SubscriptionToken(id: UUID(), moduleId: moduleId, eventType: eventType)
        subscriptions[token] = handler
        return token
    }
    
    func publish(event: ModuleEvent, from moduleId: String) async {
        for (token, handler) in subscriptions {
            if token.moduleId == moduleId && token.eventType == event.eventType {
                await handler(event)
            }
        }
    }
}

struct SubscriptionToken: Hashable {
    let id: UUID
    let moduleId: String
    let eventType: String
}

struct ModuleEvent: Sendable {
    let timestamp: Date
    let eventType: String
    let metadata: [String: Any]?
}

// MARK: - 启动画面（示例）
struct SplashScreen: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                
                Text("NotBad")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
    }
}

// MARK: - 简化的设置画面
struct SettingsScreen: View {
    @EnvironmentObject var uiModule: UIModule
    
    var body: some View {
        NavigationStack {
            List {
                Section("外观") {
                    Picker("主题", selection: $uiModule.theme) {
                        Text("跟随系统").tag(AppTheme.system)
                        Text("浅色").tag(AppTheme.light)
                        Text("深色").tag(AppTheme.dark)
                    }
                }
                
                Section("关于") {
                    LabeledContent("版本", value: "1.0.0")
                    LabeledContent("模块数", value: "23")
                }
            }
            .navigationTitle("设置")
        }
    }
}

// MARK: - 其他占位视图
struct OnboardingFlow: View {
    var body: some View {
        Text("Onboarding")
    }
}

struct LoginScreen: View {
    var body: some View {
        Text("Login")
    }
}

struct ReviewScreen: View {
    var body: some View {
        Text("Review")
    }
}

struct ScheduleScreen: View {
    var body: some View {
        Text("Schedule")
    }
}

struct StatisticsScreen: View {
    var body: some View {
        Text("Statistics")
    }
}

