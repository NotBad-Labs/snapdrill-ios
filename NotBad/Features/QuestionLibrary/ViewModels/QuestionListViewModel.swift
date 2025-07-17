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
    
    // 搜索相关状态
    var searchText: String = ""
    var isSearching: Bool = false
    
    // MARK: - UI State
    var showingDeleteAlert = false
    var questionToDelete: Question?
    var showingSortMenu = false
    var showingFilterMenu = false
    
    // MARK: - Dependencies
    private let deleteQuestionUseCase: DeleteQuestionUseCase
    private let searchHistoryUseCase = SearchHistoryUseCase()
    
    // MARK: - Search History State
    var searchHistory: [SearchHistory] = []
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.deleteQuestionUseCase = DeleteQuestionUseCase(modelContext: modelContext)
    }
    
    // MARK: - Computed Properties
    var hasActiveFilters: Bool {
        selectedDifficulty != nil || selectedTag != nil || !searchText.isEmpty
    }
    
    // 搜索建议（动态计算，需从外部传入 questions）
    func getSearchSuggestions(from questions: [Question]) -> [String] {
        // 如果搜索文本为空，返回热门标签
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return getPopularTags(from: questions)
        }

        let searchTerm = searchText.lowercased()
        var suggestions: [String] = []

        // 1. 标签建议
        let tagSuggestions = getAllTags(from: questions).filter {
            $0.lowercased().contains(searchTerm)
        }
        suggestions.append(contentsOf: tagSuggestions)

        // 2. 学科建议
        let subjectSuggestions = getCoreSubjects().filter {
            $0.lowercased().contains(searchTerm)
        }
        suggestions.append(contentsOf: subjectSuggestions)

        // 3. 难度建议
        let difficultySuggestions = getDifficultyTerms().filter {
            $0.lowercased().contains(searchTerm)
        }
        suggestions.append(contentsOf: difficultySuggestions)

        // 去重并限制数量
        return Array(Set(suggestions)).sorted().prefix(8).map { String($0) }
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
            print("删除失败: \(error)")
        }
    }
    
    func deleteQuestions(_ questions: [Question]) async {
        do {
            try await deleteQuestionUseCase.execute(questions)
        } catch {
            print("批量删除失败: \(error)")
        }
    }
    
    func resetFilters() {
        selectedDifficulty = nil
        selectedTag = nil
    }
    
    func startSearching() {
        isSearching = true
    }
    
    func stopSearching() {
        isSearching = false
        searchText = ""
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    // MARK: - Search History Methods
    func loadSearchHistory() async {
        searchHistory = await searchHistoryUseCase.getSearchHistory()
    }

    func saveSearchTerm(_ term: String, resultCount: Int) async {
        await searchHistoryUseCase.saveSearchTerm(term, resultCount: resultCount)
        await loadSearchHistory()
    }

    func removeSearchTerm(_ term: String) async {
        await searchHistoryUseCase.removeSearchTerm(term)
        await loadSearchHistory()
    }

    func clearSearchHistory() async {
        await searchHistoryUseCase.clearSearchHistory()
        await loadSearchHistory()
    }
    
    // MARK: - Data Processing
    func filteredAndSorted(_ questions: [Question]) -> [Question] {
        var result = questions
        
        // 搜索过滤
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let searchTerm = searchText.lowercased()
            result = result.filter { question in
                question.content.lowercased().contains(searchTerm) ||
                question.answer.lowercased().contains(searchTerm) ||
                question.tags.contains { $0.lowercased().contains(searchTerm) }
            }
        }
        
        // 其他筛选
        if let difficulty = selectedDifficulty {
            result = result.filter { $0.difficulty == difficulty }
        }
        
        if let tag = selectedTag {
            result = result.filter { $0.tags.contains(tag) }
        }
        
        // 扩展的排序逻辑
        switch sortOption {
        case .newest:
            result = result.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            result = result.sorted { $0.createdAt < $1.createdAt }
        case .easiest:
            result = result.sorted { $0.difficulty < $1.difficulty }
        case .hardest:
            result = result.sorted { $0.difficulty > $1.difficulty }
        case .reviewedFirst:
            result = result.sorted { $0.isReviewed && !$1.isReviewed }
        case .unreviewedFirst:
            result = result.sorted { !$0.isReviewed && $1.isReviewed }
        case .shortestContent:
            result = result.sorted { $0.content.count < $1.content.count }
        case .longestContent:
            result = result.sorted { $0.content.count > $1.content.count }
        case .mostReviewed:
            result = result.sorted { $0.reviewCount > $1.reviewCount }
        case .leastReviewed:
            result = result.sorted { $0.reviewCount < $1.reviewCount }
        case .mostTags:
            result = result.sorted { $0.tags.count > $1.tags.count }
        case .leastTags:
            result = result.sorted { $0.tags.count < $1.tags.count }
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
    
    func handleSearchCompletion(_ term: String, questions: [Question]) async {
        searchText = term
        let filteredQuestions = filteredAndSorted(questions)
        await saveSearchTerm(term, resultCount: filteredQuestions.count)
    }
}

// MARK: - Private Methods
private func getAllTags(from questions: [Question]) -> [String] {
    return Array(Set(questions.flatMap { $0.tags })).sorted()
}

private func getPopularTags(from questions: [Question]) -> [String] {
    // 统计标签使用频率
    let tagCounts = Dictionary(grouping: questions.flatMap { $0.tags }, by: { $0 })
        .mapValues { $0.count }

    return tagCounts.sorted { $0.value > $1.value }
        .prefix(6)
        .map { $0.key }
}

private func getCoreSubjects() -> [String] {
    return ["语文", "数学", "外语", "物理", "化学", "生物", "历史", "地理", "道德与法治", "信息技术"]
}

private func getDifficultyTerms() -> [String] {
    return ["基础题", "简单题", "中等题", "困难题", "极难题"]
}
