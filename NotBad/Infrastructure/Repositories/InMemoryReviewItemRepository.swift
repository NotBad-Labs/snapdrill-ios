//
//  InMemoryReviewItemRepository.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import Foundation

/// 内存中的ReviewItem仓储实现
/// Infrastructure层实现，用于开发和测试
final class InMemoryReviewItemRepository: ReviewItemRepository, @unchecked Sendable {
    
    // MARK: - Storage
    private var items: [ReviewItemID: ReviewItem] = [:]
    private let queue = DispatchQueue(label: "reviewitem.repository", attributes: .concurrent)
    
    // MARK: - 基本 CRUD 操作
    
    func save(_ item: ReviewItem) async throws -> ReviewItemID {
        return try await withCheckedThrowingContinuation { continuation in
            self.queue.async(flags: .barrier) {
                self.items[item.id] = item
                continuation.resume(returning: item.id)
            }
        }
    }
    
    func findById(_ id: ReviewItemID) async throws -> ReviewItem? {
        return await withCheckedContinuation { continuation in
            self.queue.async {
                continuation.resume(returning: self.items[id])
            }
        }
    }
    
    func update(_ id: ReviewItemID, with updates: ReviewItemUpdates) async throws -> ReviewItem {
        return try await withCheckedThrowingContinuation { continuation in
            self.queue.async(flags: .barrier) {
                guard var item = self.items[id] else {
                    continuation.resume(throwing: RepositoryError.itemNotFound(id))
                    return
                }
                
                do {
                    // 应用更新
                    if let question = updates.question {
                        try item.updateQuestion(question)
                    }
                    if let answer = updates.answer {
                        try item.updateAnswer(answer)
                    }
                    if let subject = updates.subject {
                        if let subjectEnum = ReviewItem.Subject(rawValue: subject) {
                            item.updateSubject(subjectEnum)
                        }
                    }
                    if let difficulty = updates.difficulty {
                        if let difficultyEnum = ReviewItem.Difficulty(rawValue: difficulty) {
                            item.updateDifficulty(difficultyEnum)
                        }
                    }
                    if let tags = updates.tags {
                        item.updateTags(Set(tags))
                    }
                    if let notes = updates.notes {
                        item.updateNotes(notes)
                    }
                    
                    // 保存更新后的项目
                    self.items[id] = item
                    continuation.resume(returning: item)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func delete(_ id: ReviewItemID) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.queue.async(flags: .barrier) {
                guard self.items[id] != nil else {
                    continuation.resume(throwing: RepositoryError.itemNotFound(id))
                    return
                }
                self.items.removeValue(forKey: id)
                continuation.resume(returning: ())
            }
        }
    }
    
    // MARK: - 查询操作
    
    func findAll() async throws -> [ReviewItem] {
        return await withCheckedContinuation { continuation in
            self.queue.async {
                let allItems = Array(self.items.values)
                continuation.resume(returning: allItems)
            }
        }
    }
    
    func findBy(_ criteria: ReviewItemQueryCriteria) async throws -> [ReviewItem] {
        let allItems = try await findAll()
        
        return allItems.filter { item in
            // 应用所有过滤条件
            if let subject = criteria.subject, item.subject != subject {
                return false
            }
            if let difficulty = criteria.difficulty, item.difficulty != difficulty {
                return false
            }
            if let proficiencyLevel = criteria.proficiencyLevel, item.proficiencyLevel != proficiencyLevel {
                return false
            }
            if let tags = criteria.tags, !tags.isSubset(of: item.tags) {
                return false
            }
            if let dateRange = criteria.dateRange {
                if !dateRange.contains(item.createdAt) {
                    return false
                }
            }
            if let searchText = criteria.searchText {
                let lowercaseSearch = searchText.lowercased()
                if !item.question.lowercased().contains(lowercaseSearch) &&
                   !item.answer.lowercased().contains(lowercaseSearch) &&
                   !(item.notes?.lowercased().contains(lowercaseSearch) ?? false) {
                    return false
                }
            }
            return true
        }
    }
    
    func search(query: String, limit: Int) async throws -> [ReviewItem] {
        let criteria = ReviewItemQueryCriteria(searchText: query)
        let results = try await findBy(criteria)
        return Array(results.prefix(limit))
    }
    
    func findItemsForReview(on date: Date, limit: Int) async throws -> [ReviewItem] {
        let allItems = try await findAll()
        
        let itemsForReview = allItems.filter { item in
            // 需要复习的条件：
            // 1. 从未复习过的项目
            // 2. 下次复习日期已到或已过的项目
            guard let nextReviewDate = item.nextReviewDate else {
                return true // 从未复习过
            }
            return nextReviewDate <= date
        }
        
        // 按优先级排序：熟练度低的优先，然后按创建时间
        let sortedItems = itemsForReview.sorted { item1, item2 in
            if item1.proficiencyLevel != item2.proficiencyLevel {
                return item1.proficiencyLevel.rawValue < item2.proficiencyLevel.rawValue
            }
            return item1.createdAt < item2.createdAt
        }
        
        return Array(sortedItems.prefix(limit))
    }
    
    // MARK: - 统计操作
    
    func count() async throws -> Int {
        return await withCheckedContinuation { continuation in
            self.queue.async {
                continuation.resume(returning: self.items.count)
            }
        }
    }
    
    func count(by criteria: ReviewItemQueryCriteria) async throws -> Int {
        let filteredItems = try await findBy(criteria)
        return filteredItems.count
    }
    
    func exists(_ id: ReviewItemID) async throws -> Bool {
        return await withCheckedContinuation { continuation in
            self.queue.async {
                continuation.resume(returning: self.items[id] != nil)
            }
        }
    }
}

// MARK: - 测试支持
#if DEBUG
extension InMemoryReviewItemRepository {
    /// 清空所有数据（仅用于测试）
    func clear() async {
        await withCheckedContinuation { continuation in
            self.queue.async(flags: .barrier) {
                self.items.removeAll()
                continuation.resume(returning: ())
            }
        }
    }
    
    /// 获取当前存储的数据数量（仅用于测试）
    func getItemCount() async -> Int {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.items.count)
            }
        }
    }
}
#endif