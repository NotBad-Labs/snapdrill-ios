//
//  QuestionDetailViewModel.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import Foundation
import SwiftData

@MainActor
@Observable
class QuestionDetailViewModel {
    // MARK: - State
    var content: String = ""
    var answer: String = ""
    var difficulty: Int = 3
    var tagsInput: String = ""
    var wrongReason: String = ""
    
    // MARK: - UI State
    var isEditing: Bool = false
    var showingSaveAlert: Bool = false
    var saveErrorMessage: String = ""
    
    // MARK: - Dependencies
    private let updateQuestionUseCase: UpdateQuestionUseCase
    private let question: Question
    
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
    
    var hasChanges: Bool {
        content != question.content ||
        answer != question.answer ||
        difficulty != question.difficulty ||
        tags != question.tags ||
        wrongReason != (question.wrongReason ?? "")
    }
    
    // MARK: - Initialization
    init(question: Question, modelContext: ModelContext) {
        self.question = question
        self.updateQuestionUseCase = UpdateQuestionUseCase(modelContext: modelContext)
        loadQuestionData()
    }
    
    // MARK: - Actions
    func toggleEditing() {
        if isEditing && hasChanges {
            // 有未保存的更改，提示用户
            showingSaveAlert = true
        } else {
            isEditing.toggle()
            if !isEditing {
                // 取消编辑，恢复原始数据
                loadQuestionData()
            }
        }
    }
    
    func saveChanges() async {
        guard isValid else { return }
        
        do {
            try await updateQuestionUseCase.execute(
                question: question,
                content: content,
                answer: answer,
                difficulty: difficulty,
                tags: tags,
                wrongReason: wrongReason.isEmpty ? nil : wrongReason
            )
            isEditing = false
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
    
    func discardChanges() {
        loadQuestionData()
        isEditing = false
    }
    
    // MARK: - Private Methods
    private func loadQuestionData() {
        content = question.content
        answer = question.answer
        difficulty = question.difficulty
        tagsInput = question.tags.joined(separator: ", ")
        wrongReason = question.wrongReason ?? ""
    }
}