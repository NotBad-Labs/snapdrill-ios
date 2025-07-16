//
//  QuestionListViewModel.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class QuestionListViewModel {
    // MARK: - State
    var editMode: EditMode = .inactive
    var sortOption: SortOption = .newest
    var selectedDifficulty: Int? = nil
    var selectedTag: String? = nil
    
    // MARK: - UI State
    var showingDeleteAlert = false
    var questionToDelete: Question?
    var showingSortMenu = false
    var showingFilterMenu = false
    
    // MARK: - Dependencies
    private let deleteQuestionUseCase: DeleteQuestionUseCase
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.deleteQuestionUseCase = DeleteQuestionUseCase(modelContext: modelContext)
    }
    
    // MARK: - Computed Properties
    var hasActiveFilters: Bool {
        selectedDifficulty != nil || selectedTag != nil
    }
    
    // MARK: - Actions
    func prepareDelete(_ question: Question) {
        questionToDelete = question
        showingDeleteAlert = true
    }
    
    func deleteQuestion() async {
        guard let question = questionToDelete else { return }
        
        do {
            try await deleteQuestionUseCase.execute(question)
            questionToDelete = nil
        } catch {
            // TODO: 处理错误
            print("删除失败: \(error)")
        }
    }
    
    func deleteQuestions(_ questions: [Question]) async {
        do {
            try await deleteQuestionUseCase.execute(questions)
        } catch {
            // TODO: 处理错误
            print("批量删除失败: \(error)")
        }
    }
    
    func resetFilters() {
        selectedDifficulty = nil
        selectedTag = nil
    }
    
    // MARK: - Data Processing
    func filteredAndSorted(_ questions: [Question]) -> [Question] {
        var result = questions
        
        // 筛选逻辑
        if let difficulty = selectedDifficulty {
            result = result.filter { $0.difficulty == difficulty }
        }
        
        if let tag = selectedTag {
            result = result.filter { $0.tags.contains(tag) }
        }
        
        // 排序逻辑
        switch sortOption {
        case .newest:
            result = result.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            result = result.sorted { $0.createdAt < $1.createdAt }
        case .easiest:
            result = result.sorted { $0.difficulty < $1.difficulty }
        case .hardest:
            result = result.sorted { $0.difficulty > $1.difficulty }
        }
        
        return result
    }
    
    func availableTags(from questions: [Question]) -> [String] {
        Array(Set(questions.flatMap { $0.tags })).sorted()
    }
    
    func difficultyText(for difficulty: Int) -> String {
        switch difficulty {
        case 1: return "基础题"
        case 2: return "简单题"
        case 3: return "中等题"
        case 4: return "困难题"
        case 5: return "极难题"
        default: return "中等题"
        }
    }
}