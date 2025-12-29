//
//  NotBadApp.swift
//  NotBad
//
//  应用入口
//

import SwiftUI
import NotBadFeatureCapture
import NotBadFeatureLibrary
import NotBadFeatureReview
import NotBadFeatureSettings

@main
struct NotBadApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                LibraryView()
            }
            .tabItem {
                Label("题库", systemImage: "books.vertical")
            }
            
            NavigationStack {
                ReviewView()
            }
            .tabItem {
                Label("复习", systemImage: "clock.arrow.circlepath")
            }
            
            NavigationStack {
                CaptureView()
            }
            .tabItem {
                Label("采集", systemImage: "camera")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gear")
            }
        }
    }
}
