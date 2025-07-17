//
//  MainFlow.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//

import SwiftUI

/// 主应用流程 - 包含Tab导航
struct MainFlow: View {
    @State private var tabCoordinator = TabCoordinator()
    @Environment(AppRouter.self) private var appRouter
    
    var body: some View {
        TabView(selection: $tabCoordinator.selectedTab) {
            // 首页
            HomeNavigationStack()
                .tabItem {
                    Image(systemName: TabCoordinator.Tab.home.icon)
                    Text(TabCoordinator.Tab.home.title)
                }
                .tag(TabCoordinator.Tab.home)
            
            // 练习
            PracticeNavigationStack()
                .tabItem {
                    Image(systemName: TabCoordinator.Tab.practice.icon)
                    Text(TabCoordinator.Tab.practice.title)
                }
                .tag(TabCoordinator.Tab.practice)
            
            // 拍照
            AddQuestionNavigationStack()
                .tabItem {
                    Image(systemName: TabCoordinator.Tab.addQuestion.icon)
                    Text(TabCoordinator.Tab.addQuestion.title)
                }
                .tag(TabCoordinator.Tab.addQuestion)
            
            // 发现
            DiscoverNavigationStack()
                .tabItem {
                    Image(systemName: TabCoordinator.Tab.discover.icon)
                    Text(TabCoordinator.Tab.discover.title)
                }
                .tag(TabCoordinator.Tab.discover)
            
            // 我的
            ProfileNavigationStack()
                .tabItem {
                    Image(systemName: TabCoordinator.Tab.profile.icon)
                    Text(TabCoordinator.Tab.profile.title)
                }
                .tag(TabCoordinator.Tab.profile)
        }
        .tint(.blue)
        .environment(tabCoordinator)
        .sheet(isPresented: $tabCoordinator.showingCamera) {
            CameraView()
        }
        .sheet(isPresented: $tabCoordinator.showingOCREditor) {
            OCREditorView()
        }
        .sheet(isPresented: $tabCoordinator.showingSettings) {
            SettingsView()
        }
    }
}

// MARK: - Navigation Stacks for Each Tab

struct HomeNavigationStack: View {
    var body: some View {
        NavigationStack {
            HomeView()
        }
    }
}

struct PracticeNavigationStack: View {
    var body: some View {
        NavigationStack {
            PracticeView()
        }
    }
}

struct AddQuestionNavigationStack: View {
    var body: some View {
        NavigationStack {
            AddQuestionView()
        }
    }
}

struct DiscoverNavigationStack: View {
    var body: some View {
        NavigationStack {
            DiscoverView()
        }
    }
}

struct ProfileNavigationStack: View {
    var body: some View {
        NavigationStack {
            ProfileView()
        }
    }
}

// MARK: - Placeholder Flow Views

struct OnboardingFlow: View {
    @Environment(AppRouter.self) private var appRouter
    
    var body: some View {
        VStack {
            Text("欢迎使用 NotBad")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("智能错题管理，让学习更高效")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
            
            Button("开始使用") {
                appRouter.completeOnboarding()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct AuthenticationFlow: View {
    @Environment(AppRouter.self) private var appRouter
    
    var body: some View {
        VStack {
            Text("登录")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // 这里可以添加登录表单
            
            Button("跳过登录") {
                appRouter.completeAuthentication()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Placeholder Modal Views

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("相机界面")
                .font(.title)
            
            Button("关闭") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct OCREditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("OCR编辑界面")
                .font(.title)
            
            Button("关闭") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("设置界面")
                .font(.title)
            
            Button("关闭") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Temporary AuthenticationService

class AuthenticationService {
    static let shared = AuthenticationService()
    
    var isAuthenticated: Bool {
        return UserDefaults.standard.bool(forKey: "isAuthenticated")
    }
    
    func logout() {
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
    }
    
    private init() {}
}