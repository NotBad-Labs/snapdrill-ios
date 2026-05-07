//
//  AppRootView.swift
//  SnapDrill
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  应用根视图，组合导航和各个 Feature 模块。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData
import SnapDrillFeatureCapture
import SnapDrillFeatureLibrary
import SnapDrillFeatureReview
import SnapDrillFeatureDashboard
import SnapDrillFeatureSettings

/// 应用根视图 (Composition Root UI)
///
/// 这里是所有 Feature 模块的物理聚合点。
/// 它负责将 Router 状态绑定到具体的视图结构上。
struct AppRootView: View {
    
    // MARK: - Properties
    
    @Bindable var router: AppRouter
    @Environment(\.profileManager) private var profileManager

    var body: some View {
        ZStack(alignment: .top) {
            // Tab struct（iOS 18+）：自动获得 Liquid Glass 效果
            // iPad 上自动切换为侧边栏导航
            TabView(selection: $router.selectedTab) {
                Tab(L10n.Dashboard.title, systemImage: "house", value: AppTab.dashboard) {
                    DashboardView(router: router.dashboardRouter)
                }

                Tab(L10n.Library.title, systemImage: "books.vertical", value: AppTab.library) {
                    LibraryView(router: router.libraryRouter)
                }

                Tab(L10n.Capture.title, systemImage: "camera", value: AppTab.capture) {
                    CaptureView(router: router.captureRouter)
                }

                Tab(L10n.Review.title, systemImage: "clock.arrow.circlepath", value: AppTab.review) {
                    ReviewView(router: router.reviewRouter)
                }

                Tab(L10n.Settings.title, systemImage: "gear", value: AppTab.settings) {
                    SettingsView(router: router.settingsRouter)
                }
            }
            .tabViewStyle(.sidebarAdaptable)
            // conventions.md: Combine .onReceive → async notification stream
            .task {
                for await _ in NotificationCenter.default.notifications(named: .switchToCaptureTab) {
                    withAnimation(.spring(duration: 0.4)) { router.selectedTab = .capture }
                }
            }
            .task {
                for await _ in NotificationCenter.default.notifications(named: .switchToLibraryTab) {
                    withAnimation(.spring(duration: 0.4)) { router.selectedTab = .library }
                }
            }
            .task {
                for await _ in NotificationCenter.default.notifications(named: .switchToSettingsTab) {
                    withAnimation(.spring(duration: 0.4)) { router.selectedTab = .settings }
                }
            }
            
            // 降级模式警告横幅
            if profileManager.isUsingInMemoryFallback {
                degradedModeWarningBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Private Helpers
    
    /// 降级模式警告横幅
    @ViewBuilder
    private var degradedModeWarningBanner: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.AppRoot.degradedModeTitle)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(L10n.AppRoot.degradedModeDescription)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}
