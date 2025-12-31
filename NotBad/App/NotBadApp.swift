//
//  NotBadApp.swift
//  NotBad
//
//  Created by Yiming Liao on 2025/12/29.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  应用入口文件，负责初始化应用和主界面配置
//

import SwiftUI
import SwiftData
import NotBadData
import NotBadFeatures
import TipKit

/// 应用的主入口
///
/// 负责配置应用的主窗口和根视图。
@main
struct NotBadApp: App {
    /// 顶级导航协调器 (Coordinator State)
    @State private var appRouter = AppRouter()
    
    var body: some Scene {
        WindowGroup {
            // 极简入口：仅负责注入环境和启动根视图
            AppRootView(router: appRouter)
                .modelContainer(PersistenceController.shared.container)
                .onAppear {
                    // Initialize TipKit
                    try? Tips.configure([
                        .displayFrequency(.immediate),
                        .datastoreLocation(.applicationDefault)
                    ])
                    
                    // Initialize default subjects on first launch
                    let context = PersistenceController.shared.container.mainContext
                    let repository = SubjectRepository(modelContext: context)
                    repository.initializeDefaultsIfNeeded()
                }
        }
    }
}
