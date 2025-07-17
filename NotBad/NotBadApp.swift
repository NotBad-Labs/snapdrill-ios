//
//  NotBadApp.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/15/25.
//

import SwiftUI
import SwiftData

@main
struct NotBadApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: Question.self)
        } catch {
            fatalError("❌ SwiftData 容器初始化失败: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .onAppear {
                    #if DEBUG
                    createSampleDataIfNeeded()
                    #endif
                }
        }
    }
    
    #if DEBUG
    private func createSampleDataIfNeeded() {
        let context = container.mainContext
        
        // 检查是否已有数据
        let descriptor = FetchDescriptor<Question>()
        let existingQuestions = try? context.fetch(descriptor)
        
        if existingQuestions?.isEmpty ?? true {
            Task {
                let useCase = CreateSampleDataUseCase(modelContext: context)
                try await useCase.execute()
            }
        }
    }
    #endif
}
