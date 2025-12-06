//
//  NotBadApp.swift
//  NotBad
//
//  应用入口（实用主义架构）
//

import SwiftUI
import SwiftData

@main
struct NotBadApp: App {
    
    /// SwiftData 模型容器
    let modelContainer: ModelContainer
    
    init() {
        // 初始化 ImageStorageService（确保目录存在）
        _ = ImageStorageService.shared
        
        // 创建 ModelContainer
        modelContainer = Self.createModelContainer()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
    
    /// 创建 ModelContainer
    private static func createModelContainer() -> ModelContainer {
        let schema = Schema([ReviewItemModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // 如果失败，尝试删除旧数据库重建
            print("❌ ModelContainer 初始化失败: \(error)")
            
            // 删除旧数据库
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
            
            // 重试
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("❌ 无法创建 ModelContainer: \(error)")
            }
        }
    }
}

