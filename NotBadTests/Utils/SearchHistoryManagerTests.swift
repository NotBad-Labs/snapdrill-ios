//
//  SearchHistoryManagerTests.swift
//  NotBadTests
//
//  搜索历史管理器测试
//

import Testing
@testable import NotBad

@Suite("SearchHistoryManager 测试")
@MainActor
struct SearchHistoryManagerTests {
    
    // MARK: - Setup
    
    /// 创建隔离的测试实例
    /// 注意：由于 SearchHistoryManager 是单例，这里测试会影响真实数据
    /// 在实际项目中，应该使用依赖注入来避免这个问题
    
    @Test("添加搜索记录")
    func addSearch() {
        let manager = SearchHistoryManager.shared
        let initialCount = manager.searchHistory.count
        
        // 添加新记录
        manager.addSearch("测试搜索")
        
        #expect(manager.searchHistory.contains("测试搜索"))
        
        // 清理
        manager.removeSearch("测试搜索")
    }
    
    @Test("空字符串不添加")
    func emptyStringNotAdded() {
        let manager = SearchHistoryManager.shared
        let initialCount = manager.searchHistory.count
        
        manager.addSearch("")
        manager.addSearch("   ")
        
        #expect(manager.searchHistory.count == initialCount)
    }
    
    @Test("重复搜索移到顶部")
    func duplicateMovesToTop() {
        let manager = SearchHistoryManager.shared
        
        // 添加多个记录
        manager.addSearch("第一个")
        manager.addSearch("第二个")
        manager.addSearch("第三个")
        
        // 重复添加第一个
        manager.addSearch("第一个")
        
        #expect(manager.searchHistory.first == "第一个")
        
        // 清理
        manager.removeSearch("第一个")
        manager.removeSearch("第二个")
        manager.removeSearch("第三个")
    }
    
    @Test("删除搜索记录")
    func removeSearch() {
        let manager = SearchHistoryManager.shared
        
        manager.addSearch("待删除")
        #expect(manager.searchHistory.contains("待删除"))
        
        manager.removeSearch("待删除")
        #expect(!manager.searchHistory.contains("待删除"))
    }
    
    @Test("清空所有历史")
    func clearHistory() {
        let manager = SearchHistoryManager.shared
        
        // 保存当前历史
        let previousHistory = manager.searchHistory
        
        // 添加测试数据
        manager.addSearch("清空测试1")
        manager.addSearch("清空测试2")
        
        // 清空
        manager.clearHistory()
        
        #expect(manager.searchHistory.isEmpty)
        
        // 恢复之前的历史（如果有）
        for item in previousHistory.reversed() {
            manager.addSearch(item)
        }
    }
}
