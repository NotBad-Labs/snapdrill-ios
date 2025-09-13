//
//  GetReviewItemsUseCase.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//

import Foundation

// MARK: - 获取复习项列表用例
/// 获取复习项列表的用例，封装查询复习项的业务逻辑
/// 支持多种查询条件和排序方式
class GetReviewItemsUseCase {
    private let repository: ReviewItemRepository
    
    init(repository: ReviewItemRepository) {
        self.repository = repository
    }
    
    /// 执行获取复习项列表操作
    /// - Parameter request: 查询请求
    /// - Returns: 查询结果
    /// - Throws: 查询失败时抛出错误
    func execute(_ request: GetReviewItemsRequest) async throws -> GetReviewItemsResponse {
        // 1. 根据查询条件获取复习项
        let items = try await fetchItems(by: request.filter)
        
        // 2. 应用排序
        let sortedItems = applySorting(items, by: request.sortBy)
        
        // 3. 应用分页
        let paginatedItems = applyPagination(sortedItems, page: request.page, pageSize: request.pageSize)
        
        // 4. 计算统计信息
        let statistics = calculateStatistics(items)
        
        return GetReviewItemsResponse(
            items: paginatedItems,
            totalCount: items.count,
            page: request.page,
            pageSize: request.pageSize,
            statistics: statistics
        )
    }
    
    // MARK: - 私有方法
    
    /// 根据过滤条件获取复习项
    private func fetchItems(by filter: ReviewItemFilter) async throws -> [ReviewItem] {
        switch filter {
        case .all:
            return try await repository.getAll()
        case .byOwner(let ownerId):
            return try await repository.getByOwner(ownerId)
        case .bySubject(let subject):
            return try await repository.getBySubject(subject)
        case .byMasteryLevel(let masteryLevel):
            return try await repository.getByMasteryLevel(masteryLevel)
        case .bySearch(let query):
            return try await repository.search(query)
        case .custom(let customFilter):
            return try await fetchWithCustomFilter(customFilter)
        }
    }
    
    /// 使用自定义过滤条件获取复习项
    private func fetchWithCustomFilter(_ filter: CustomReviewItemFilter) async throws -> [ReviewItem] {
        // 获取所有复习项
        var items = try await repository.getAll()
        
        // 应用过滤条件
        if let ownerId = filter.ownerId {
            items = items.filter { $0.metadata.ownerId == ownerId }
        }
        
        if let subject = filter.subject {
            items = items.filter { $0.content.subject == subject }
        }
        
        if let masteryLevel = filter.masteryLevel {
            items = items.filter { $0.masteryLevel == masteryLevel }
        }
        
        if let difficulty = filter.difficulty {
            items = items.filter { $0.content.difficulty == difficulty }
        }
        
        if let tags = filter.tags, !tags.isEmpty {
            items = items.filter { item in
                tags.allSatisfy { tag in
                    item.content.tags.contains(tag)
                }
            }
        }
        
        if let dateRange = filter.dateRange {
            items = items.filter { item in
                item.metadata.createdAt >= dateRange.startDate &&
                item.metadata.createdAt <= dateRange.endDate
            }
        }
        
        return items
    }
    
    /// 应用排序
    private func applySorting(_ items: [ReviewItem], by sortBy: ReviewItemSortBy) -> [ReviewItem] {
        switch sortBy {
        case .createdDateAsc:
            return items.sorted { $0.metadata.createdAt < $1.metadata.createdAt }
        case .createdDateDesc:
            return items.sorted { $0.metadata.createdAt > $1.metadata.createdAt }
        case .updatedDateAsc:
            return items.sorted { $0.metadata.updatedAt < $1.metadata.updatedAt }
        case .updatedDateDesc:
            return items.sorted { $0.metadata.updatedAt > $1.metadata.updatedAt }
        case .titleAsc:
            return items.sorted { $0.content.title < $1.content.title }
        case .titleDesc:
            return items.sorted { $0.content.title > $1.content.title }
        case .masteryLevel:
            return items.sorted { $0.masteryLevel.rawValue < $1.masteryLevel.rawValue }
        case .difficulty:
            return items.sorted { $0.content.difficulty.weight < $1.content.difficulty.weight }
        }
    }
    
    /// 应用分页
    private func applyPagination(_ items: [ReviewItem], page: Int, pageSize: Int) -> [ReviewItem] {
        let startIndex = page * pageSize
        let endIndex = min(startIndex + pageSize, items.count)
        
        guard startIndex < items.count else {
            return []
        }
        
        return Array(items[startIndex..<endIndex])
    }
    
    /// 计算统计信息
    private func calculateStatistics(_ items: [ReviewItem]) -> ReviewItemStatistics {
        let totalCount = items.count
        let masteryCounts = Dictionary(grouping: items, by: { $0.masteryLevel })
            .mapValues { $0.count }
        let difficultyCounts = Dictionary(grouping: items, by: { $0.content.difficulty })
            .mapValues { $0.count }
        let subjectCounts = Dictionary(grouping: items, by: { $0.content.subject })
            .mapValues { $0.count }
        
        return ReviewItemStatistics(
            totalCount: totalCount,
            masteryLevelCounts: masteryCounts,
            difficultyLevelCounts: difficultyCounts,
            subjectCounts: subjectCounts
        )
    }
}

// MARK: - 获取复习项列表请求
/// 获取复习项列表的请求参数
struct GetReviewItemsRequest {
    let filter: ReviewItemFilter
    let sortBy: ReviewItemSortBy
    let page: Int
    let pageSize: Int
    
    init(
        filter: ReviewItemFilter = .all,
        sortBy: ReviewItemSortBy = .createdDateDesc,
        page: Int = 0,
        pageSize: Int = 20
    ) {
        self.filter = filter
        self.sortBy = sortBy
        self.page = page
        self.pageSize = pageSize
    }
}

// MARK: - 获取复习项列表响应
/// 获取复习项列表的响应数据
struct GetReviewItemsResponse {
    let items: [ReviewItem]
    let totalCount: Int
    let page: Int
    let pageSize: Int
    let statistics: ReviewItemStatistics
}

// MARK: - 复习项过滤条件
/// 复习项查询的过滤条件
enum ReviewItemFilter {
    case all
    case byOwner(UUID)
    case bySubject(String)
    case byMasteryLevel(MasteryLevel)
    case bySearch(String)
    case custom(CustomReviewItemFilter)
}

// MARK: - 自定义过滤条件
/// 自定义的复习项过滤条件
struct CustomReviewItemFilter {
    let ownerId: UUID?
    let subject: String?
    let masteryLevel: MasteryLevel?
    let difficulty: DifficultyLevel?
    let tags: [String]?
    let dateRange: DateRange?
    
    init(
        ownerId: UUID? = nil,
        subject: String? = nil,
        masteryLevel: MasteryLevel? = nil,
        difficulty: DifficultyLevel? = nil,
        tags: [String]? = nil,
        dateRange: DateRange? = nil
    ) {
        self.ownerId = ownerId
        self.subject = subject
        self.masteryLevel = masteryLevel
        self.difficulty = difficulty
        self.tags = tags
        self.dateRange = dateRange
    }
}

// MARK: - 日期范围
/// 日期范围结构
struct DateRange {
    let startDate: Date
    let endDate: Date
    
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - 复习项排序方式
/// 复习项排序方式
enum ReviewItemSortBy: String, CaseIterable {
    case createdDateAsc = "created_date_asc"
    case createdDateDesc = "created_date_desc"
    case updatedDateAsc = "updated_date_asc"
    case updatedDateDesc = "updated_date_desc"
    case titleAsc = "title_asc"
    case titleDesc = "title_desc"
    case masteryLevel = "mastery_level"
    case difficulty = "difficulty"
    
    var displayName: String {
        switch self {
        case .createdDateAsc:
            return "创建时间（升序）"
        case .createdDateDesc:
            return "创建时间（降序）"
        case .updatedDateAsc:
            return "更新时间（升序）"
        case .updatedDateDesc:
            return "更新时间（降序）"
        case .titleAsc:
            return "标题（升序）"
        case .titleDesc:
            return "标题（降序）"
        case .masteryLevel:
            return "掌握程度"
        case .difficulty:
            return "难度等级"
        }
    }
}

// MARK: - 复习项统计信息
/// 复习项统计信息
struct ReviewItemStatistics {
    let totalCount: Int
    let masteryLevelCounts: [MasteryLevel: Int]
    let difficultyLevelCounts: [DifficultyLevel: Int]
    let subjectCounts: [String: Int]
}
