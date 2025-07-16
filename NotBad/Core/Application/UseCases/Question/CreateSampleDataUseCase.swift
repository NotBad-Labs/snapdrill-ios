//
//  CreateSampleDataUseCase.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import Foundation
import SwiftData

actor CreateSampleDataUseCase {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func execute() async throws {
        // 检查是否已有数据
        let descriptor = FetchDescriptor<Question>()
        let existingQuestions = try modelContext.fetch(descriptor)
        
        guard existingQuestions.isEmpty else { return }
        
        let sampleQuestions = createSampleQuestions()
        
        for question in sampleQuestions {
            modelContext.insert(question)
        }
        
        try modelContext.save()
    }
    
    private func createSampleQuestions() -> [Question] {
        // ... 你的测试数据代码
    }
}