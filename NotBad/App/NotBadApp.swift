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
///
/// 采用层次化协调器架构：
///
/// ```
/// NotBadApp (App Entry)
///     └── AppCoordinator
///         ├── RootCoordinator (启动/错误/维护)
///         ├── MainFlowCoordinator (Onboarding/权限)
///         │   └── TabCoordinator (Tab 导航)
///         │       └── FeatureCoordinators (各功能模块)
///         ├── WidgetSyncCoordinator
///         ├── DeepLinkCoordinator
///         └── SpotlightCoordinator
/// ```
///
/// App 入口只负责：
/// - 初始化核心依赖（ModelContainer、DependencyFactory）
/// - 创建协调器层次结构
/// - 组装 View 层级
/// - 转发系统事件给协调器
@main
struct NotBadApp: App {

    // MARK: - Core Dependencies
    
    /// 模型容器（带迁移计划）
    let modelContainer: ModelContainer
    
    /// 依赖工厂
    let dependencyFactory: DependencyFactory
    
    // MARK: - Coordinators
    
    /// 应用协调器（协调器层次结构的根节点）
    @State private var coordinator: AppCoordinator

    // MARK: - User Preferences
    
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

    // MARK: - Initialization
    
    init() {
        // 配置 TipKit
        TipsConfiguration.configure()
        
        // 初始化 ModelContainer
        let container = Self.createModelContainer()
        self.modelContainer = container
        
        // 创建并配置依赖工厂
        let factory = ProductionDependencyFactory(modelContainer: container)
        self.dependencyFactory = factory
        AppDependencies.configure(factory: factory)
        
        // 初始化应用协调器（会自动创建整个协调器层次结构）
        self._coordinator = State(initialValue: AppCoordinator(modelContainer: container))
        
        Logger.app.info("✅ App 初始化完成")
    }

    // MARK: - Scene
    
    var body: some Scene {
        WindowGroup {
            RootView(
                coordinator: coordinator.root,
                mainFlowCoordinator: coordinator.mainFlow
            )
            .environment(\.appCoordinator, coordinator)
            .environment(\.tabCoordinator, coordinator.tab)
            .withDependencies(dependencyFactory)
            .preferredColorScheme(preferredColorScheme)
            // Deep Link
            .onOpenURL { url in
                coordinator.handleOpenURL(url)
            }
            // Handoff Restoration
            .onContinueUserActivity(UserActivityType.viewDashboard) { _ in
                coordinator.handleHandoffTab(.dashboard)
            }
            .onContinueUserActivity(UserActivityType.viewLibrary) { _ in
                coordinator.handleHandoffTab(.library)
            }
            .onContinueUserActivity(UserActivityType.captureItem) { _ in
                coordinator.handleHandoffTab(.capture)
            }
            .onContinueUserActivity(UserActivityType.reviewSession) { _ in
                coordinator.handleHandoffTab(.review)
            }
            .onContinueUserActivity(UserActivityType.viewProfile) { _ in
                coordinator.handleHandoffTab(.profile)
            }
            // Spotlight 搜索结果
            .onContinueUserActivity(CSSearchableItemActionType) { activity in
                coordinator.handleUserActivity(activity)
            }
            // Widget 同步
            .task {
                await coordinator.startWidgetSync()
            }
            .onReceive(NotificationCenter.default.publisher(for: .reviewItemsDidChange)) { _ in
                coordinator.scheduleWidgetSync()
            }
        }
        .modelContainer(modelContainer)
    }
    
    // MARK: - Factory Methods
    
    /// 创建 ModelContainer
    private static func createModelContainer() -> ModelContainer {
        do {
            let schema = Schema([ReviewItemModel.self, ReviewItemImageModel.self])
            let config = ModelConfiguration(schema: schema)
            return try ModelContainer(
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
                let schema = Schema([ReviewItemModel.self, ReviewItemImageModel.self])
                let config = ModelConfiguration(schema: schema)
                let container = try ModelContainer(for: schema, configurations: [config])
                Logger.app.info("✅ 重建数据库成功")
                return container
            } catch {
                fatalError("❌ [App] 无法创建 ModelContainer: \(error)")
            }
        }
    }
}
