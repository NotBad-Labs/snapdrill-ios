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
import SnapDrillFeatures
import SnapDrillCore
import SnapDrillUI
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
    @ObservedObject private var onboardingManager = OnboardingManager.shared
    
    /// 外观模式设置 (0=System, 1=Light, 2=Dark)
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    
    // MARK: - Computed Properties
    
    private var container: DependencyContainer {
        DependencyContainer.shared
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
                    .modelContainer(PersistenceController.shared.container)
                    .environment(\.services, container.services)
                    .environment(container.services.networkMonitor)
                    .environment(\.repositories, container.repositories)
                    .preferredColorScheme(colorScheme)
                    .blur(radius: AppConfiguration.FeatureFlags.isEmergencyKillSwitchActive ? 10 : 0)
                    .disabled(AppConfiguration.FeatureFlags.isEmergencyKillSwitchActive)
                
                if AppConfiguration.FeatureFlags.isEmergencyKillSwitchActive {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)
                        
                        Text("测试版维护中")
                            .font(.title.bold())
                        
                        Text("当前测试版本正在进行紧急维护或已失效，请稍后再试或前往 TestFlight 下载最新版本。")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 40)
                        
                        Button("检查更新") {
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
                .task {
                    // TipKit 初始化（与引导页状态无关，始终执行）
                    try? Tips.configure([
                        .displayFrequency(.immediate),
                        .datastoreLocation(.applicationDefault)
                    ])

                    // 引导页显示期间暂缓 ATT 预热，由引导完成回调接管
                    guard !onboardingManager.shouldShowOnboarding else { return }
                    if container.services.privacyConsent.shouldShowPrePrompt {
                        showingPrivacyPrePrompt = true
                    }
                }
        }
    }
}
