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
    
    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $router.selectedTab) {
                DashboardView(router: router.dashboardRouter)
                    .tabItem {
                        Label(L10n.Dashboard.title, systemImage: "house")
                    }
                    .tag(AppTab.dashboard)

                LibraryView(router: router.libraryRouter)
                    .tabItem {
                        Label(L10n.Library.title, systemImage: "books.vertical")
                    }
                    .tag(AppTab.library)

                CaptureView(router: router.captureRouter)
                    .tabItem {
                        Label(L10n.Capture.title, systemImage: "camera")
                    }
                    .tag(AppTab.capture)

                ReviewView(router: router.reviewRouter)
                    .tabItem {
                        Label(L10n.Review.title, systemImage: "clock.arrow.circlepath")
                    }
                    .tag(AppTab.review)

                SettingsView(router: router.settingsRouter)
                    .tabItem {
                        Label(L10n.Settings.title, systemImage: "gear")
                    }
                    .tag(AppTab.settings)
            }
            .onReceive(NotificationCenter.default.publisher(for: .switchToCaptureTab)) { _ in
                withAnimation(.spring(duration: 0.4)) {
                    router.selectedTab = .capture
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .switchToLibraryTab)) { _ in
                withAnimation(.spring(duration: 0.4)) {
                    router.selectedTab = .library
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .switchToSettingsTab)) { _ in
                withAnimation(.spring(duration: 0.4)) {
                    router.selectedTab = .settings
                }
            }
            
            // 降级模式警告横幅
            if PersistenceController.shared.isUsingInMemoryFallback {
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
