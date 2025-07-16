//
//  AddQuestionViewModel.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import Foundation
import SwiftData

@MainActor
@Observable
class AddQuestionViewModel {
    // MARK: - Published Properties
    var content: String = ""
    var answer: String = ""
    var difficulty: Int = 3
    var tagsInput: String = ""  // 用户输入的标签文本
    
    // MARK: - Computed Properties
    var isValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var tags: [String] {
        tagsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    var difficultyText: String {
        switch difficulty {
        case 1: return "基础题"
        case 2: return "简单题"
        case 3: return "中等题"
        case 4: return "困难题"
        case 5: return "极难题"
        default: return "中等题"
        }
    }
    
    // MARK: - Dependencies
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Actions
    func saveQuestion() throws {
        guard isValid else {
            throw ValidationError.invalidInput
        }
        
        let question = Question(
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            answer: answer.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: tags,
            difficulty: difficulty
        )
        
        modelContext.insert(question)
        try modelContext.save()
        
        // 重置表单
        resetForm()
    }
    
    func resetForm() {
        content = ""
        answer = ""
        difficulty = 3
        tagsInput = ""
    }
}

// MARK: - Validation Error
enum ValidationError: LocalizedError {
    case invalidInput
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "题目内容和答案不能为空"
        }
    }
}