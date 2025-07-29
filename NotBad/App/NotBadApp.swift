// App/NotBadApp.swift
import SwiftUI

@main
struct NotBadApp: App {
    // 初始化 AppEnvironment，这将配置所有依赖项。
    // 使用 @StateObject 确保 AppEnvironment 在应用生命周期内只创建一次。
    @StateObject private var appEnvironment = AppEnvironment.shared

    var body: some Scene {
        WindowGroup {
            // 将 AppEnvironment 注入到环境中，以便子视图可以访问依赖。
            // QuestionListView 作为应用的根视图。
            QuestionListView()
                .environmentObject(appEnvironment) // 将 AppEnvironment 注入到 SwiftUI 环境中
        }
    }
}