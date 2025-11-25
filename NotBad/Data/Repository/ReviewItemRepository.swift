//
//  ReviewItemRepository.swift
//  NotBad
//
//  错题仓库实现 - SwiftData 存储
//

import Foundation
import SwiftData

/// 错题仓库实现
///
/// 基于 SwiftData 的具体实现
@MainActor
final class ReviewItemRepository: ReviewItemRepositoryProtocol {
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Fetch
    
    func fetchAll() -> [ReviewItem] {
        let descriptor = FetchDescriptor<ReviewItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetch(subject: Subject?, mastery: MasteryLevel?) -> [ReviewItem] {
        var items = fetchAll()
        
        if let subject = subject {
            items = items.filter { $0.subject == subject }
        }
        
        if let mastery = mastery {
            items = items.filter { $0.mastery == mastery }
        }
        
        return items
    }
    
    func fetchForReview() -> [ReviewItem] {
        fetchAll().sorted { item1, item2 in
            // 优先级：未掌握 > 模糊 > 熟悉 > 掌握
            if item1.masteryLevel != item2.masteryLevel {
                return item1.masteryLevel < item2.masteryLevel
            }
            // 同等掌握度，复习次数少的优先
            return item1.reviewCount < item2.reviewCount
        }
    }
    
    func search(query: String) -> [ReviewItem] {
        guard !query.isEmpty else { return fetchAll() }
        
        let lowercasedQuery = query.lowercased()
        return fetchAll().filter { item in
            item.title.lowercased().contains(lowercasedQuery) ||
            item.tags.matches(query) ||
            item.note.lowercased().contains(lowercasedQuery)
        }
    }
    
    // MARK: - Save
    
    func save(_ item: ReviewItem) throws {
        modelContext.insert(item)
        try modelContext.save()
    }
    
    // MARK: - Delete
    
    func delete(_ item: ReviewItem) throws {
        modelContext.delete(item)
        try modelContext.save()
    }
    
    func delete(_ items: [ReviewItem]) throws {
        items.forEach { modelContext.delete($0) }
        try modelContext.save()
    }
    
    // MARK: - Statistics
    
    func statistics() -> ReviewStatistics {
        let items = fetchAll()
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        
        // 掌握度分布
        var masteryDistribution: [MasteryLevel: Int] = [:]
        for level in MasteryLevel.allCases {
            masteryDistribution[level] = items.filter { $0.mastery == level }.count
        }
        
        // 学科分布
        var subjectDistribution: [Subject: Int] = [:]
        for subject in Subject.allCases {
            let count = items.filter { $0.subject == subject }.count
            if count > 0 {
                subjectDistribution[subject] = count
            }
        }
        
        return ReviewStatistics(
            totalCount: items.count,
            masteredCount: items.filter { $0.mastery == .mastered }.count,
            weeklyNewCount: items.filter { $0.createdAt >= weekAgo }.count,
            totalReviewCount: items.reduce(0) { $0 + $1.reviewCount },
            masteryDistribution: masteryDistribution,
            subjectDistribution: subjectDistribution
        )
    }
}
