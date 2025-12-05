//
//  SearchHistoryManager.swift
//  NotBad
//
//  搜索历史管理器
//

import SwiftUI
import Observation

// MARK: - SearchHistoryManager

/// 搜索历史管理器
///
/// 负责管理用户的搜索历史记录，支持添加、删除和清空操作。
///
/// ## 功能特性
///
/// - 最多保存 10 条搜索历史
/// - 自动去重（相同关键词不重复添加）
/// - 新搜索置顶
/// - 数据持久化到 UserDefaults
///
/// ## 使用示例
///
/// ```swift
/// // 添加搜索记录
/// SearchHistoryManager.shared.addSearch("数学")
///
/// // 获取历史记录
/// let history = SearchHistoryManager.shared.searchHistory
///
/// // 删除单条记录
/// SearchHistoryManager.shared.removeSearch("数学")
///
/// // 清空所有记录
/// SearchHistoryManager.shared.clearHistory()
/// ```
@MainActor
@Observable
final class SearchHistoryManager {
    
    // MARK: - Singleton
    
    /// 单例实例
    static let shared = SearchHistoryManager()
    
    // MARK: - Constants
    
    /// 最大历史记录数量
    private let maxHistoryCount = 10
    
    /// UserDefaults 键
    private let historyKey = "search_history"
    
    // MARK: - Properties
    
    /// 搜索历史记录
    private(set) var searchHistory: [String] = []
    
    // MARK: - Initialization
    
    private init() {
        loadHistory()
    }
    
    // MARK: - Public Methods
    
    /// 添加搜索记录
    ///
    /// - Parameter query: 搜索关键词
    ///
    /// 自动去重，相同关键词会移到顶部而不是重复添加。
    /// 超过最大数量时自动删除最旧的记录。
    func addSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // 移除已存在的相同记录
        searchHistory.removeAll { $0 == trimmed }
        
        // 添加到顶部
        searchHistory.insert(trimmed, at: 0)
        
        // 限制数量
        if searchHistory.count > maxHistoryCount {
            searchHistory = Array(searchHistory.prefix(maxHistoryCount))
        }
        
        saveHistory()
    }
    
    /// 删除搜索记录
    ///
    /// - Parameter query: 要删除的关键词
    func removeSearch(_ query: String) {
        searchHistory.removeAll { $0 == query }
        saveHistory()
    }
    
    /// 清空所有搜索历史
    func clearHistory() {
        searchHistory.removeAll()
        saveHistory()
    }
    
    // MARK: - Private Methods
    
    /// 加载历史记录
    private func loadHistory() {
        if let history = UserDefaults.standard.stringArray(forKey: historyKey) {
            searchHistory = history
        }
    }
    
    /// 保存历史记录
    private func saveHistory() {
        UserDefaults.standard.set(searchHistory, forKey: historyKey)
    }
}
