//
//  MainTabView.swift
//  NotBad
//
//  主界面 - iOS 26 现代化设计
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("首页", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
            
            LibraryView()
                .tabItem {
                    Label("题库", systemImage: selectedTab == 1 ? "books.vertical.fill" : "books.vertical")
                }
                .tag(1)
            
            CaptureView()
                .tabItem {
                    Label {
                        Text("录入")
                            .fontWeight(.semibold)
                    } icon: {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .blue)
                    }
                }
                .tag(2)
            
            ReviewView()
                .tabItem {
                    Label("复习", systemImage: "sparkles")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: selectedTab == 4 ? "person.crop.circle.fill" : "person.crop.circle")
                }
                .tag(4)
        }
        .tint(.blue)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: ReviewItem.self, inMemory: true)
}
