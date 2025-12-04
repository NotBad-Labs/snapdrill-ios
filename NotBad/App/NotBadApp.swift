//
//  NotBadApp.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import SwiftData
import TipKit
import OSLog

// MARK: - NotBadApp

/// NotBad K12 错题本应用主入口
@main
struct NotBadApp: App {

    /// 模型容器（带迁移计划）
    let modelContainer: ModelContainer

    /// Deep Link 导航状态
    @State private var selectedTab: Int = 0

    /// 是否显示 Onboarding
    @State private var showOnboarding: Bool = false

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
        
        do {
            let schema = Schema([ReviewItem.self])
            let config = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(
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
                let schema = Schema([ReviewItem.self])
                let config = ModelConfiguration(schema: schema)
                modelContainer = try ModelContainer(for: schema, configurations: [config])
                Logger.app.info("✅ 重建数据库成功")
            } catch {
                fatalError("❌ [App] 无法创建 ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            AdaptiveNavigationView(selectedTab: $selectedTab)
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
                .onContinueUserActivity(UserActivityType.viewDashboard) { _ in selectedTab = 0 }
                .onContinueUserActivity(UserActivityType.viewLibrary) { _ in selectedTab = 1 }
                .onContinueUserActivity(UserActivityType.captureItem) { _ in selectedTab = 2 }
                .onContinueUserActivity(UserActivityType.reviewSession) { _ in selectedTab = 3 }
                .onContinueUserActivity(UserActivityType.viewProfile) { _ in selectedTab = 4 }
                .task {
                    await syncWidgetData()
                }
                .onReceive(NotificationCenter.default.publisher(for: .reviewItemsDidChange)) { _ in
                    Task {
                        await syncWidgetData()
                    }
                }
        }
        .modelContainer(modelContainer)
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
            selectedTab = 1
        case "library":
            // 导航到错题库
            selectedTab = 2
        case "capture":
            // 导航到拍照
            selectedTab = 0
        default:
            break
        }

        Logger.app.debug("Deep link handled: \(url.absoluteString)")
    }

    // MARK: - Widget Data Sync

    /// 同步数据到 Widget
    @MainActor
    private func syncWidgetData() async {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<ReviewItem>()

        do {
            let items = try context.fetch(descriptor)
            items.syncToWidget()
        } catch {
            Logger.widget.error("Failed to sync widget data: \(error.localizedDescription)")
        }
    }
}
