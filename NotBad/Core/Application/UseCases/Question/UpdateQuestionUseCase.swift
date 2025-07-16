//
//  UpdateQuestionUseCase.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import Foundation
import SwiftData

actor UpdateQuestionUseCase {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func execute(
        question: Question,
        content: String,
        answer: String,
        difficulty: Int,
        tags: [String],
        wrongReason: String?
    ) async throws {
        question.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        question.answer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        question.difficulty = difficulty
        question.tags = tags
        question.wrongReason = wrongReason
        
        try modelContext.save()
    }
}