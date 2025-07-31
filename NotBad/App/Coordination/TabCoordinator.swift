import SwiftUI
import Foundation

// MARK: - TabCoordinator
// 位置: App/Navigation/TabCoordinator.swift

/// 主Tab协调器
/// 负责管理5个主要Tab的导航和状态管理
@MainActor
@Observable
class TabCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    /// 当前选中的Tab
    private(set) var selectedTab: MainTabFlow = .dashboard
    
    /// Tab协调器映射表
    private var tabCoordinators: [MainTabFlow: any CoordinatorProtocol] = [:]
    
    // MARK: - Tab Coordinators
    
    private var dashboardCoordinator: DashboardTabCoordinator?
    private var questionManagementCoordinator: QuestionManagementTabCoordinator?
    private var studyPracticeCoordinator: StudyPracticeTabCoordinator?
    private var discoveryCoordinator: DiscoveryTabCoordinator?
    private var userProfileCoordinator: UserProfileTabCoordinator?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupTabCoordinators()
    }
    
    // MARK: - CoordinatorProtocol
    
    override func start() {
        // 启动所有Tab协调器
        tabCoordinators.values.forEach { coordinator in
            coordinator.start()
        }
    }
    
    override func stop() {
        // 停止所有Tab协调器
        tabCoordinators.values.forEach { coordinator in
            coordinator.stop()
        }
        tabCoordinators.removeAll()
        super.stop()
    }
    
    override func getRootView() -> AnyView {
        AnyView(MainTabView(coordinator: self))
    }
    
    // MARK: - Public Methods
    
    /// 切换到指定Tab
    func selectTab(_ tab: MainTabFlow) {
        selectedTab = tab
    }
    
    /// 获取指定Tab的协调器
    func getCoordinator(for tab: MainTabFlow) -> (any CoordinatorProtocol)? {
        return tabCoordinators[tab]
    }
    
    /// 获取指定Tab的视图
    func getView(for tab: MainTabFlow) -> AnyView {
        guard let coordinator = tabCoordinators[tab] else {
            return AnyView(
                Text("Tab协调器未找到: \(tab)")
                    .foregroundColor(.red)
            )
        }
        return coordinator.getRootView()
    }
    
    // MARK: - Private Methods
    
    /// 设置所有Tab协调器
    private func setupTabCoordinators() {
        // Dashboard Tab
        dashboardCoordinator = DashboardTabCoordinator()
        tabCoordinators[.dashboard] = dashboardCoordinator
        addChild(dashboardCoordinator!)
        
        // Question Management Tab
        questionManagementCoordinator = QuestionManagementTabCoordinator()
        tabCoordinators[.questionManagement] = questionManagementCoordinator
        addChild(questionManagementCoordinator!)
        
        // Study Practice Tab
        studyPracticeCoordinator = StudyPracticeTabCoordinator()
        tabCoordinators[.studyPractice] = studyPracticeCoordinator
        addChild(studyPracticeCoordinator!)
        
        // Discovery Tab
        discoveryCoordinator = DiscoveryTabCoordinator()
        tabCoordinators[.discovery] = discoveryCoordinator
        addChild(discoveryCoordinator!)
        
        // User Profile Tab
        userProfileCoordinator = UserProfileTabCoordinator()
        tabCoordinators[.userProfile] = userProfileCoordinator
        addChild(userProfileCoordinator!)
    }
}

// MARK: - MainTabView

/// 主Tab视图
struct MainTabView: View {
    @State var coordinator: TabCoordinator
    
    var body: some View {
        TabView(selection: Binding(
            get: { coordinator.selectedTab },
            set: { coordinator.selectTab($0) }
        )) {
            ForEach(TabConfiguration.allTabs, id: \.flow) { tabConfig in
                coordinator.getView(for: tabConfig.flow)
                    .tabItem {
                        Label(
                            tabConfig.title,
                            systemImage: coordinator.selectedTab == tabConfig.flow 
                                ? tabConfig.selectedIcon 
                                : tabConfig.icon
                        )
                    }
                    .tag(tabConfig.flow)
            }
        }
        .tint(.blue) // 统一的Tab选中颜色
    }
}

// MARK: - 各个Tab协调器的基础实现

/// Dashboard Tab协调器
@MainActor
@Observable
class DashboardTabCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    private(set) var currentFlow: DashboardFlow = .home
    
    // MARK: - CoordinatorProtocol
    
    override func start() {
        // Dashboard启动逻辑
    }
    
    override func getRootView() -> AnyView {
        AnyView(DashboardTabCoordinatorView(coordinator: self))
    }
    
    // MARK: - Navigation
    
    func navigate(to flow: DashboardFlow) {
        currentFlow = flow
    }
}

/// Question Management Tab协调器
@MainActor
@Observable
class QuestionManagementTabCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    private(set) var currentFlow: QuestionManagementFlow = .home
    
    // MARK: - CoordinatorProtocol
    
    override func start() {
        // Question Management启动逻辑
    }
    
    override func getRootView() -> AnyView {
        AnyView(QuestionManagementTabCoordinatorView(coordinator: self))
    }
    
    // MARK: - Navigation
    
    func navigate(to flow: QuestionManagementFlow) {
        currentFlow = flow
    }
}

/// Study Practice Tab协调器
@MainActor
@Observable
class StudyPracticeTabCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    private(set) var currentFlow: StudyPracticeFlow = .home
    
    // MARK: - CoordinatorProtocol
    
    override func start() {
        // Study Practice启动逻辑
    }
    
    override func getRootView() -> AnyView {
        AnyView(StudyPracticeTabCoordinatorView(coordinator: self))
    }
    
    // MARK: - Navigation
    
    func navigate(to flow: StudyPracticeFlow) {
        currentFlow = flow
    }
}

/// Discovery Tab协调器
@MainActor
@Observable
class DiscoveryTabCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    private(set) var currentFlow: DiscoveryFlow = .home
    
    // MARK: - CoordinatorProtocol
    
    override func start() {
        // Discovery启动逻辑
    }
    
    override func getRootView() -> AnyView {
        AnyView(DiscoveryTabCoordinatorView(coordinator: self))
    }
    
    // MARK: - Navigation
    
    func navigate(to flow: DiscoveryFlow) {
        currentFlow = flow
    }
}

/// User Profile Tab协调器
@MainActor
@Observable
class UserProfileTabCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    private(set) var currentFlow: UserProfileFlow = .home
    
    // MARK: - CoordinatorProtocol
    
    override func start() {
        // User Profile启动逻辑
    }
    
    override func getRootView() -> AnyView {
        AnyView(UserProfileTabCoordinatorView(coordinator: self))
    }
    
    // MARK: - Navigation
    
    func navigate(to flow: UserProfileFlow) {
        currentFlow = flow
    }
}

// MARK: - 各个Tab的协调器视图

/// Dashboard Tab协调器视图
struct DashboardTabCoordinatorView: View {
    @State var coordinator: DashboardTabCoordinator
    
    var body: some View {
        NavigationStack {
            Group {
                switch coordinator.currentFlow {
                case .home:
                    DashboardView()
                case .weatherDetail:
                    Text("天气详情页面")
                        .navigationTitle("天气详情")
                case .studyStatsDetail:
                    Text("学习统计详情页面")
                        .navigationTitle("学习统计")
                case .recommendationDetail:
                    Text("推荐详情页面")
                        .navigationTitle("推荐详情")
                }
            }
        }
    }
}

/// Question Management Tab协调器视图
struct QuestionManagementTabCoordinatorView: View {
    @State var coordinator: QuestionManagementTabCoordinator
    
    var body: some View {
        NavigationStack {
            Group {
                switch coordinator.currentFlow {
                case .home:
                    QuestionManagementView()
                case .cameraCapture:
                    Text("相机捕获页面")
                        .navigationTitle("拍照录题")
                case .ocrReview:
                    Text("OCR识别结果")
                        .navigationTitle("识别结果")
                case .manualInput:
                    Text("手动输入页面")
                        .navigationTitle("手动输入")
                case .fileImport:
                    Text("文件导入页面")
                        .navigationTitle("文件导入")
                case .questionPreview:
                    Text("题目预览页面")
                        .navigationTitle("题目预览")
                case .questionDetail(let questionID):
                    Text("题目详情: \(questionID)")
                        .navigationTitle("题目详情")
                case .questionEdit(let questionID):
                    Text("编辑题目: \(questionID)")
                        .navigationTitle("编辑题目")
                }
            }
        }
    }
}

/// Study Practice Tab协调器视图
struct StudyPracticeTabCoordinatorView: View {
    @State var coordinator: StudyPracticeTabCoordinator
    
    var body: some View {
        NavigationStack {
            Group {
                switch coordinator.currentFlow {
                case .home:
                    StudyPracticeView()
                case .modeSelection:
                    Text("模式选择页面")
                        .navigationTitle("练习模式")
                case .studySession:
                    Text("学习会话页面")
                        .navigationTitle("学习中")
                case .questionPractice:
                    Text("题目练习页面")
                        .navigationTitle("练习")
                case .studyResult:
                    Text("学习结果页面")
                        .navigationTitle("学习结果")
                case .studyHistory:
                    Text("学习历史页面")
                        .navigationTitle("学习历史")
                case .performanceAnalysis:
                    Text("表现分析页面")
                        .navigationTitle("表现分析")
                }
            }
        }
    }
}

/// Discovery Tab协调器视图
struct DiscoveryTabCoordinatorView: View {
    @State var coordinator: DiscoveryTabCoordinator
    
    var body: some View {
        NavigationStack {
            Group {
                switch coordinator.currentFlow {
                case .home:
                    DiscoveryView()
                case .search:
                    Text("搜索页面")
                        .navigationTitle("搜索")
                case .searchResults(let query):
                    Text("搜索结果: \(query)")
                        .navigationTitle("搜索结果")
                case .trending:
                    Text("热门内容页面")
                        .navigationTitle("热门")
                case .recommendations:
                    Text("推荐页面")
                        .navigationTitle("推荐")
                case .categories:
                    Text("分类页面")
                        .navigationTitle("分类")
                case .feedItemDetail(let itemID):
                    Text("动态详情: \(itemID)")
                        .navigationTitle("动态详情")
                }
            }
        }
    }
}

/// User Profile Tab协调器视图
struct UserProfileTabCoordinatorView: View {
    @State var coordinator: UserProfileTabCoordinator
    
    var body: some View {
        NavigationStack {
            Group {
                switch coordinator.currentFlow {
                case .home:
                    UserProfilePlaceholderView()
                case .editProfile:
                    Text("编辑资料页面")
                        .navigationTitle("编辑资料")
                case .settings:
                    Text("设置页面")
                        .navigationTitle("设置")
                case .notificationSettings:
                    Text("通知设置页面")
                        .navigationTitle("通知设置")
                case .privacySettings:
                    Text("隐私设置页面")
                        .navigationTitle("隐私设置")
                case .statistics:
                    Text("统计页面")
                        .navigationTitle("统计")
                case .achievements:
                    Text("成就页面")
                        .navigationTitle("成就")
                case .dataExport:
                    Text("数据导出页面")
                        .navigationTitle("数据导出")
                case .helpCenter:
                    Text("帮助中心页面")
                        .navigationTitle("帮助中心")
                case .about:
                    Text("关于页面")
                        .navigationTitle("关于")
                }
            }
        }
    }
}

// MARK: - 临时占位视图

struct DashboardPlaceholderView: View {
    var body: some View {
        Text("Dashboard首页")
            .font(.title)
            .navigationTitle("首页")
    }
}

struct QuestionManagementPlaceholderView: View {
    var body: some View {
        Text("题目管理首页")
            .font(.title)
            .navigationTitle("录题")
    }
}

struct StudyPracticePlaceholderView: View {
    var body: some View {
        Text("学习练习首页")
            .font(.title)
            .navigationTitle("练习")
    }
}

struct DiscoveryPlaceholderView: View {
    var body: some View {
        Text("发现首页")
            .font(.title)
            .navigationTitle("发现")
    }
}

struct UserProfilePlaceholderView: View {
    var body: some View {
        Text("个人资料首页")
            .font(.title)
            .navigationTitle("我的")
    }
}