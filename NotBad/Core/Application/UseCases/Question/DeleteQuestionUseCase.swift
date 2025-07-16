//
//  DeleteQuestionUseCase.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import Foundation
import SwiftData

actor DeleteQuestionUseCase {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func execute(_ question: Question) async throws {
        modelContext.delete(question)
        try modelContext.save()
    }
    
    func execute(_ questions: [Question]) async throws {
        for question in questions {
            modelContext.delete(question)
        }
        try modelContext.save()
    }
}