//
//  NotBadApp.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//  使用协调器模式的简洁应用入口点
//

import SwiftUI

@main
struct NotBadApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    
    var body: some Scene {
        WindowGroup {
            AppCoordinatorView(coordinator: appCoordinator)
                .preferredColorScheme(.light) // 强制使用浅色模式
        }
    }
}
// CI/CD trigger - Sat Sep 13 21:59:24 CST 2025
