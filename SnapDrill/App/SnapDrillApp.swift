//
//  SnapDrillApp.swift
//  SnapDrill
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  应用入口文件，负责初始化应用和主界面配置
//

import SwiftUI
import SnapDrillData
import SnapDrillCore
import SnapDrillUI
import SnapDrillFeatureCapture
import SnapDrillFeatureLibrary
import SnapDrillFeatureReview
import SnapDrillFeatureDashboard
import SnapDrillFeatureSettings
import TipKit

// MARK: - AppDelegate（Firebase 初始化）

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 访问单例即可触发 DependencyContainer 内的 Firebase 等初始化
        _ = DependencyContainer.shared
        return true
    }
}

/// 应用的主入口
///
/// 负责配置应用的主窗口和根视图。
@main
struct SnapDrillApp: App {
    
    // MARK: - Properties
    
    /// Firebase / 系统级别生命周期桥接
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    /// 是否显示隐私预热弹窗
    @State private var showingPrivacyPrePrompt: Bool = false

    /// 引导页状态管理
    @State private var onboardingManager = OnboardingManager.shared
    
    /// 外观模式设置 (0=System, 1=Light, 2=Dark)
    @AppStorage(UDKey.appearanceMode) private var appearanceMode: Int = 0

    /// 场景生命周期，用于追踪 session 事件
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Computed Properties
    
    private var container: DependencyContainer {
        DependencyContainer.shared
    }

    private var profileManager: ProfileManager {
        container.profileManager
    }
    
    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            // 极简入口：仅负责注入环境和启动根视图
            ZStack {
                AppRootView(router: container.router)
                    .modelContainer(profileManager.activeContainer)
                    .environment(\.services, container.services)
                    .environment(\.repositories, profileManager.activeRepositories)
                    .environment(\.profileManager, profileManager)
                    .id(profileManager.activeProfileId)
                    // analyticsService 单独注入：5 个 View 直接使用 \.analyticsService，
                    // 虽然 \.services 已包含 analytics，但移除此行会让它们回退到 Mock 默认值
                    .environment(\.analyticsService, container.services.analytics)
                    .preferredColorScheme(colorScheme)
                    .blur(radius: AppConfiguration.FeatureFlags.isEmergencyKillSwitchActive ? 10 : 0)
                    .disabled(AppConfiguration.FeatureFlags.isEmergencyKillSwitchActive)
                
                if AppConfiguration.FeatureFlags.isEmergencyKillSwitchActive {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)
                        
                        Text(L10n.AppRoot.maintenanceTitle)
                            .font(.title.bold())

                        Text(L10n.AppRoot.maintenanceDescription)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 40)

                        Button(L10n.AppRoot.checkUpdate) {
                            // Redirect to TestFlight or App Store
                            if let url = URL(string: "https://beta.itunes.apple.com/v1/app/com.snapdrill.app") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                    .transition(.opacity)
                }
            }
                .fullScreenCover(isPresented: $onboardingManager.shouldShowOnboarding) {
                    OnboardingView(pages: OnboardingPage.defaultPages) {
                        onboardingManager.completeOnboarding()
                        // 引导完成后再触发 ATT 隐私预热，避免两个弹窗同时叠加
                        if container.services.privacyConsent.shouldShowPrePrompt {
                            showingPrivacyPrePrompt = true
                        }
                    }
                }
                .sheet(isPresented: $showingPrivacyPrePrompt) {
                    PrivacyPrePromptView {
                        showingPrivacyPrePrompt = false
                        Task {
                            await container.services.privacyConsent.requestTrackingAuthorization()
                        }
                    }
                }
                // Share Extension 深链接处理：从共享容器读取图片并进入采集流程
                .onOpenURL { url in
                    guard url.scheme == "snapdrill", url.host == "share" else { return }
                    container.router.handleShareExtensionURL(url)
                }
                .task {
                    // TipKit 初始化（与引导页状态无关，始终执行）
                    try? Tips.configure([
                        .displayFrequency(.immediate),
                        .datastoreLocation(.applicationDefault)
                    ])

                    // App 启动事件（每次冷启动追踪一次）
                    container.services.analytics.track(.appLaunched, parameters: [
                        "version": container.services.appConfig.fullVersion
                    ])

                    // 引导页显示期间暂缓 ATT 预热，由引导完成回调接管
                    guard !onboardingManager.shouldShowOnboarding else { return }
                    if container.services.privacyConsent.shouldShowPrePrompt {
                        showingPrivacyPrePrompt = true
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        container.services.analytics.startSession()
                    case .background:
                        container.services.analytics.endSession()
                    default:
                        break
                    }
                }
        }
    }
}
