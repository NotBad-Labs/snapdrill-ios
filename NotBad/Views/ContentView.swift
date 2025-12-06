//
//  ContentView.swift
//  NotBad
//
//  主容器视图 - TabView 导航
//

import SwiftUI
import ReviewKit

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("首页", systemImage: "house")
                }
            
            LibraryView()
                .tabItem {
                    Label("题库", systemImage: "books.vertical")
                }
            
            CaptureView()
                .tabItem {
                    Label("录入", systemImage: "camera")
                }
            
            ReviewView()
                .tabItem {
                    Label("复习", systemImage: "brain")
                }
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
