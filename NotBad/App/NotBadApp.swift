//
//  NotBadApp.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import SwiftData
import TipKit
import CoreSpotlight
import OSLog

// MARK: - NotBadApp

/// NotBad K12 错题本应用主入口
@main
struct NotBadApp: App {

    /// 模型容器（带迁移计划）
    let modelContainer: ModelContainer
    
    /// 依赖工厂
    let dependencyFactory: DependencyFactory

    /// 导航路由器
    @State private var router = NavigationRouter.shared

    /// 是否显示 Onboarding
    @State private var showOnboarding: Bool = false
    
    /// Widget 同步防抖任务
    @State private var widgetSyncTask: Task<Void, Never>?
    
    /// Spotlight 搜索结果点击的错题 ID
    @State private var spotlightItemId: UUID?

    /// 用户选择的颜色模式
    @AppStorage("colorScheme") private var colorSchemeOption = "system"

    /// 计算实际的 ColorScheme
    private var preferredColorScheme: ColorScheme? {
        switch colorSchemeOption {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    init() {
        // 配置 TipKit
        TipsConfiguration.configure()
        
        var container: ModelContainer
        
        do {
            let schema = Schema([ReviewItemModel.self])
            let config = ModelConfiguration(schema: schema)
            container = try ModelContainer(
                for: schema,
                migrationPlan: ReviewItemMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            // 如果迁移失败，尝试删除旧数据库重建
            Logger.app.error("❌ ModelContainer 初始化失败: \(error.localizedDescription)")
            Logger.app.warning("⚠️ 尝试删除旧数据库...")

            // 删除旧数据库文件
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))

            // 重新创建容器
            do {
                let schema = Schema([ReviewItemModel.self])
                let config = ModelConfiguration(schema: schema)
                container = try ModelContainer(for: schema, configurations: [config])
                Logger.app.info("✅ 重建数据库成功")
            } catch {
                fatalError("❌ [App] 无法创建 ModelContainer: \(error)")
            }
        }
        
        // 设置 ModelContainer
        self.modelContainer = container
        
        // 创建并配置依赖工厂
        let factory = ProductionDependencyFactory(modelContainer: container)
        self.dependencyFactory = factory
        AppDependencies.configure(factory: factory)
        
        // 向后兼容：配置旧的 Dependencies 单例
        Dependencies.shared.configure(modelContainer: container)
        
        Logger.app.info("✅ 依赖工厂初始化完成")
    }

    var body: some Scene {
        WindowGroup {
            AdaptiveNavigationView()
                .environment(\.router, router)
                .withDependencies(dependencyFactory)
                .preferredColorScheme(preferredColorScheme)
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView {
                        showOnboarding = false
                    }
                }
                .onAppear {
                    checkOnboardingStatus()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                // Handoff Restoration
                .onContinueUserActivity(UserActivityType.viewDashboard) { _ in router.selectedTab = .dashboard }
                .onContinueUserActivity(UserActivityType.viewLibrary) { _ in router.selectedTab = .library }
                .onContinueUserActivity(UserActivityType.captureItem) { _ in router.selectedTab = .capture }
                .onContinueUserActivity(UserActivityType.reviewSession) { _ in router.selectedTab = .review }
                .onContinueUserActivity(UserActivityType.viewProfile) { _ in router.selectedTab = .profile }
                // Spotlight 搜索结果点击
                .onContinueUserActivity(CSSearchableItemActionType) { activity in
                    handleSpotlightSearch(activity)
                }
                .task {
                    await syncWidgetData()
                }
                .onReceive(NotificationCenter.default.publisher(for: .reviewItemsDidChange)) { _ in
                    // 防抖：批量删除/修改时避免高频同步
                    scheduleWidgetSync()
                }
                .onChange(of: spotlightItemId) { _, newId in
                    // Spotlight 搜索结果导航
                    if let id = newId {
                        navigateToItem(id: id)
                        spotlightItemId = nil
                    }
                }
        }
        .modelContainer(modelContainer)
    }
    
    // MARK: - Widget Sync (Debounced)
    
    /// 调度 Widget 同步（带 1.5 秒防抖）
    ///
    /// 当用户批量删除或修改错题时，会触发多次 `.reviewItemsDidChange` 通知。
    /// 使用防抖机制避免 Widget 数据疯狂同步，减少 CPU 和 I/O 压力。
    private func scheduleWidgetSync() {
        // 取消之前的防抖任务
        widgetSyncTask?.cancel()
        
        // 延迟 1.5 秒后执行同步
        widgetSyncTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            
            guard !Task.isCancelled else { return }
            
            await syncWidgetData()
        }
    }

    // MARK: - Onboarding

    /// 检查是否需要显示 Onboarding
    private func checkOnboardingStatus() {
        let hasCompleted = UserDefaults.standard.bool(forKey: "has_completed_onboarding")
        if !hasCompleted {
            showOnboarding = true
        }
    }

    // MARK: - Deep Link Handling

    /// 处理来自 Widget 的 Deep Link
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "notbad" else { return }

        switch url.host {
        case "review":
            // 导航到复习页面
            router.selectedTab = .review
        case "library":
            // 导航到错题库
            router.selectedTab = .library
        case "capture":
            // 导航到拍照
            router.selectedTab = .capture
        default:
            break
        }

        Logger.app.debug("Deep link handled: \(url.absoluteString)")
    }
    
    // MARK: - Spotlight Search Handling
    
    /// 处理 Spotlight 搜索结果点击
    private func handleSpotlightSearch(_ activity: NSUserActivity) {
        if let itemId = SpotlightIndexService.handleSpotlightActivity(activity) {
            spotlightItemId = itemId
            Logger.app.debug("Spotlight search: navigating to item \(itemId)")
        }
    }
    
    /// 导航到指定错题
    @MainActor
    private func navigateToItem(id: UUID) {
        // 切换到题库 Tab
        router.selectedTab = .library
        
        // 通过 NavigationRouter 推送详情页
        router.navigateToItemDetail(itemId: id)
    }

    // MARK: - Widget Data Sync

    /// 同步数据到 Widget
    @MainActor
    private func syncWidgetData() async {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<ReviewItemModel>()

        do {
            let models = try context.fetch(descriptor)
            let items = models.map { ReviewItemMapper.toEntity(from: $0) }
            items.syncToWidget()
        } catch {
            Logger.widget.error("Failed to sync widget data: \(error.localizedDescription)")
        }
    }
}
