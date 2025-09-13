//
//  NotBadApp.swift
//  NotBad
//
//  Created by YIMING LIAO on 8/20/25.
//

import SwiftUI
import SwiftData

@main
struct NotBadApp: App {
    // SwiftData模型容器
    let modelContainer: ModelContainer
    
    init() {
        do {
            // 配置SwiftData模型容器
            let schema = Schema([ReviewItemModel.self, StudyRecordModel.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("无法初始化ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
