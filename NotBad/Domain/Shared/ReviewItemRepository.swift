//
//  ReviewItemRepository.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import Foundation

/// ReviewItem 仓储接口
/// 遵循 Clean Architecture 原则，定义数据访问抽象
/// Domain 层定义接口，Infrastructure 层实现具体逻辑
protocol ReviewItemRepository {
    
    // MARK: - 基本 CRUD 操作
    
    /// 保存复习项
    /// - Parameter item: 要保存的复习项
    /// - Returns: 保存成功的复习项ID
    func save(_ item: ReviewItem) async throws -> ReviewItemID
    
    /// 根据ID获取复习项
    /// - Parameter id: 复习项ID
    /// - Returns: 复习项实例，如果不存在则返回nil
    func findById(_ id: ReviewItemID) async throws -> ReviewItem?
    
    /// 更新复习项
    /// - Parameters:
    ///   - id: 要更新的复习项ID
    ///   - updates: 更新内容
    /// - Returns: 更新后的复习项
    func update(_ id: ReviewItemID, with updates: ReviewItemUpdates) async throws -> ReviewItem
    
    /// 删除复习项
    /// - Parameter id: 要删除的复习项ID
    func delete(_ id: ReviewItemID) async throws
    
    // MARK: - 查询操作
    
    /// 获取所有复习项
    /// - Returns: 所有复习项列表
    func findAll() async throws -> [ReviewItem]
    
    /// 根据条件查询复习项
    /// - Parameter criteria: 查询条件
    /// - Returns: 符合条件的复习项列表
    func findBy(_ criteria: ReviewItemQueryCriteria) async throws -> [ReviewItem]
    
    /// 搜索复习项
    /// - Parameters:
    ///   - query: 搜索关键词
    ///   - limit: 结果数量限制
    /// - Returns: 搜索结果列表
    func search(query: String, limit: Int) async throws -> [ReviewItem]
    
    /// 获取需要复习的项目
    /// - Parameters:
    ///   - date: 基准日期
    ///   - limit: 数量限制
    /// - Returns: 需要复习的项目列表
    func findItemsForReview(on date: Date, limit: Int) async throws -> [ReviewItem]
    
    // MARK: - 统计操作
    
    /// 获取总数量
    /// - Returns: 复习项总数
    func count() async throws -> Int
    
    /// 根据条件获取数量
    /// - Parameter criteria: 查询条件
    /// - Returns: 符合条件的数量
    func count(by criteria: ReviewItemQueryCriteria) async throws -> Int
    
    /// 检查复习项是否存在
    /// - Parameter id: 复习项ID
    /// - Returns: 是否存在
    func exists(_ id: ReviewItemID) async throws -> Bool
}

// MARK: - 查询条件

/// 复习项查询条件
struct ReviewItemQueryCriteria {
    let subject: ReviewItem.Subject?
    let difficulty: ReviewItem.Difficulty?
    let proficiencyLevel: ReviewItem.ProficiencyLevel?
    let tags: Set<String>?
    let dateRange: DateRange?
    let searchText: String?
    
    init(
        subject: ReviewItem.Subject? = nil,
        difficulty: ReviewItem.Difficulty? = nil,
        proficiencyLevel: ReviewItem.ProficiencyLevel? = nil,
        tags: Set<String>? = nil,
        dateRange: DateRange? = nil,
        searchText: String? = nil
    ) {
        self.subject = subject
        self.difficulty = difficulty
        self.proficiencyLevel = proficiencyLevel
        self.tags = tags
        self.dateRange = dateRange
        self.searchText = searchText
    }
}

/// 日期范围值对象
struct DateRange {
    let start: Date
    let end: Date
    
    init(start: Date, end: Date) throws {
        guard start <= end else {
            throw DateRangeError.invalidRange
        }
        self.start = start
        self.end = end
    }
    
    func contains(_ date: Date) -> Bool {
        return date >= start && date <= end
    }
}

/// 日期范围错误
enum DateRangeError: Error, LocalizedError {
    case invalidRange
    
    var errorDescription: String? {
        switch self {
        case .invalidRange:
            return "开始日期不能晚于结束日期"
        }
    }
}

// MARK: - Repository 错误

/// 仓储层错误
enum RepositoryError: Error, LocalizedError {
    case itemNotFound(ReviewItemID)
    case duplicateItem(ReviewItemID)
    case persistenceFailure(Error)
    case queryError(String)
    case connectionFailure
    
    var errorDescription: String? {
        switch self {
        case .itemNotFound(let id):
            return "未找到复习项: \(id.value)"
        case .duplicateItem(let id):
            return "复习项已存在: \(id.value)"
        case .persistenceFailure(let error):
            return "持久化失败: \(error.localizedDescription)"
        case .queryError(let message):
            return "查询错误: \(message)"
        case .connectionFailure:
            return "数据库连接失败"
        }
    }
}