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
import SnapDrillFeatures
import SnapDrillData

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
                        Label("首页", systemImage: "house")
                    }
                    .tag(AppTab.dashboard)
                
                LibraryView(router: router.libraryRouter)
                    .tabItem {
                        Label("题库", systemImage: "books.vertical")
                    }
                    .tag(AppTab.library)
                
                CaptureView(router: router.captureRouter)
                    .tabItem {
                        Label("采集", systemImage: "camera")
                    }
                    .tag(AppTab.capture)
                
                ReviewView(router: router.reviewRouter)
                    .tabItem {
                        Label("复习", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(AppTab.review)
                
                SettingsView(router: router.settingsRouter)
                    .tabItem {
                        Label("设置", systemImage: "gear")
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
                    Text("数据保护模式")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text("数据仅保存在内存中，重启后将丢失。建议重启应用以恢复正常。")
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
