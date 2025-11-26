//
//  NotBadApp.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import SwiftData

// MARK: - NotBadApp

/// NotBad K12 错题本应用主入口
@main
struct NotBadApp: App {
    
    /// 模型容器（带迁移计划）
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([ReviewItem.self])
            let config = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: ReviewItemMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            // 如果迁移失败，尝试删除旧数据库重建
            #if DEBUG
            print("❌ [App] ModelContainer 初始化失败: \(error)")
            print("⚠️ [App] 尝试删除旧数据库...")
            #endif
            
            // 删除旧数据库文件
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
            
            // 重新创建容器
            do {
                let schema = Schema([ReviewItem.self])
                let config = ModelConfiguration(schema: schema)
                modelContainer = try ModelContainer(for: schema, configurations: [config])
                #if DEBUG
                print("✅ [App] 重建数据库成功")
                #endif
            } catch {
                fatalError("❌ [App] 无法创建 ModelContainer: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(modelContainer)
    }
}
