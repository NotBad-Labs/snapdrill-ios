//
//  SearchHistoryUseCase.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//


//
//  SearchHistoryUseCase.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import Foundation

actor SearchHistoryUseCase {
    private let userDefaults = UserDefaults.standard
    private let historyKey = "SearchHistory"
    private let maxHistoryCount = 10
    
    func saveSearchTerm(_ term: String, resultCount: Int) async {
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 不保存空搜索或过短的搜索
        guard !trimmedTerm.isEmpty && trimmedTerm.count >= 2 else { return }
        
        var history = await getSearchHistory()
        
        // 如果已存在相同的搜索词，先移除
        history.removeAll { $0.term.lowercased() == trimmedTerm.lowercased() }
        
        // 添加新的搜索记录
        let newSearch = SearchHistory(term: trimmedTerm, resultCount: resultCount)
        history.insert(newSearch, at: 0)
        
        // 限制历史记录数量
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        
        // 保存到 UserDefaults
        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }
    
    func getSearchHistory() async -> [SearchHistory] {
        guard let data = userDefaults.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([SearchHistory].self, from: data) else {
            return []
        }
        return history.sorted()
    }
    
    func clearSearchHistory() async {
        userDefaults.removeObject(forKey: historyKey)
    }
    
    func removeSearchTerm(_ term: String) async {
        var history = await getSearchHistory()
        history.removeAll { $0.term == term }
        
        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }
}