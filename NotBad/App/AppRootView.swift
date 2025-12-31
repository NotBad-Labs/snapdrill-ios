//
//  AppRootView.swift
//  NotBad
//
//  Created by NotBad Architect.
//

import SwiftUI
import NotBadFeatures

/// 应用根视图 (Composition Root UI)
///
/// 这里是所有 Feature 模块的物理聚合点。
/// 它负责将 Router 状态绑定到具体的视图结构上。
struct AppRootView: View {
    @Bindable var router: AppRouter
    
    var body: some View {
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToCaptureTab"))) { _ in
            router.selectedTab = .capture
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToLibraryTab"))) { _ in
            router.selectedTab = .library
        }
    }
}
