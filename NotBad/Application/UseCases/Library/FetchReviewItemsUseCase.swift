//
//  FetchReviewItemsUseCase.swift
//  NotBad
//
//  Application Layer - Use Case Implementation
//

import Foundation

// MARK: - FetchReviewItemsUseCase

/// 获取错题用例实现
///
/// 实现 `FetchReviewItemsUseCaseProtocol`，负责：
/// - 从仓库获取数据
/// - 应用筛选条件
/// - 排序结果
@MainActor
final class FetchReviewItemsUseCase: FetchReviewItemsUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let repository: ReviewItemRepositoryProtocol
    
    // MARK: - Initialization
    
    init(repository: ReviewItemRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - FetchReviewItemsUseCaseProtocol
    
    func execute() async -> [ReviewItem] {
        return repository.fetchAll()
    }
    
    func execute(filter: ReviewItemFilter) async -> [ReviewItem] {
        var items = repository.fetch(
            subject: filter.subject,
            mastery: filter.mastery
        )
        
        // 应用额外筛选
        if let grade = filter.grade {
            items = items.filter { $0.grade == grade }
        }
        
        if let difficulty = filter.difficulty {
            items = items.filter { $0.difficulty == difficulty }
        }
        
        if let errorType = filter.errorType {
            items = items.filter { $0.errorType == errorType }
        }
        
        if let dateRange = filter.dateRange {
            items = items.filter { item in
                item.createdAt >= dateRange.start && item.createdAt < dateRange.end
            }
        }
        
        // 排序
        items = sort(items, by: filter.sortBy, ascending: filter.ascending)
        
        return items
    }
    
    func execute(query: String) async -> [ReviewItem] {
        return repository.search(query: query)
    }
    
    func execute(id: UUID) async -> ReviewItem? {
        return repository.fetchAll().first { $0.id == id }
    }
    
    // MARK: - Private Methods
    
    private func sort(
        _ items: [ReviewItem],
        by option: ReviewItemSortOption,
        ascending: Bool
    ) -> [ReviewItem] {
        let sorted = items.sorted { item1, item2 in
            let result: Bool
            switch option {
            case .createdAt:
                result = item1.createdAt < item2.createdAt
            case .updatedAt:
                result = item1.updatedAt < item2.updatedAt
            case .nextReviewDate:
                result = item1.nextReviewDate < item2.nextReviewDate
            case .mastery:
                result = item1.masteryLevel < item2.masteryLevel
            case .difficulty:
                result = item1.difficulty.rawValue < item2.difficulty.rawValue
            case .reviewCount:
                result = item1.reviewCount < item2.reviewCount
            case .title:
                result = item1.title.localizedCompare(item2.title) == .orderedAscending
            }
            return ascending ? result : !result
        }
        return sorted
    }
}
