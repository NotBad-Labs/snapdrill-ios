//
//  GetReviewItemsUseCase.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//

import Foundation

// MARK: - 获取复习项列表用例实现
/// 获取复习项列表用例的具体实现
/// 支持多种查询条件和排序方式
class GetReviewItemsUseCaseImpl: GetReviewItemsUseCase {
    private let repository: ReviewItemRepository
    
    init(repository: ReviewItemRepository) {
        self.repository = repository
    }
    
    /// 执行获取复习项列表操作
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
        case .byDifficulty(let difficulty):
            return try await repository.getByDifficulty(difficulty)
        case .byTags(let tags):
            return try await fetchWithCustomFilter(CustomReviewItemFilter(tags: tags))
        case .byDateRange(let dateRange):
            return try await fetchWithCustomFilter(CustomReviewItemFilter(dateRange: dateRange))
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
