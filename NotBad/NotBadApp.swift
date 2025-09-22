//
//  NotBadApp.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI

@main
struct NotBadApp: App {
    
    // MARK: - Environment
    
    /// 应用环境管理器（统一管理所有依赖）
    @StateObject private var appEnvironment = AppEnvironment.make()
    
    // MARK: - App Scene
    
    var body: some Scene {
        WindowGroup {
            AppShellView(appEnvironment: appEnvironment)
        }
    }
}
