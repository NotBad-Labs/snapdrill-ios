//
//  NotBadApp.swift
//  NotBad
//
//  应用入口（实用主义架构）
//
//  关键：使用 PersistenceController 共享数据库，让 Widget 能访问
//

import SwiftUI
import SwiftData
import ReviewKit

@main
struct NotBadApp: App {
    
    init() {
        // 初始化 ImageStorageService（确保目录存在）
        _ = ImageStorageService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // ✅ 使用共享的 ModelContainer（App Groups）
        .modelContainer(PersistenceController.shared.container)
    }
}

