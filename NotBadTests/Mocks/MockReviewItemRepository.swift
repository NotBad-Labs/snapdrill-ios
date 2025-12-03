//
//  MockReviewItemRepository.swift
//  NotBadTests
//
//  Mock 实现用于单元测试
//

import Foundation
@testable import NotBad

// MARK: - MockReviewItemRepository

/// 错题仓库的 Mock 实现
///
/// 用于单元测试，提供可控的数据源和行为验证。
///
/// ## 使用示例
///
/// ```swift
/// @Test("测试获取所有错题")
/// @MainActor
/// func testFetchAll() {
///     let mock = MockReviewItemRepository()
///     mock.items = [ReviewItem.mock()]
///     
///     let result = mock.fetchAll()
///     
///     #expect(result.count == 1)
///     #expect(mock.fetchAllCalled == true)
/// }
/// ```
@MainActor
final class MockReviewItemRepository: ReviewItemRepositoryProtocol {
    
    // MARK: - Mock Data
    
    /// 模拟的错题数据
    var items: [ReviewItem] = []
    
    /// 模拟的统计数据
    var mockStatistics: ReviewStatistics?
    
    // MARK: - Call Tracking
    
    /// 是否调用了 fetchAll
    var fetchAllCalled = false
    
    /// 是否调用了 fetchForReview
    var fetchForReviewCalled = false
    
    /// 是否调用了 save
    var saveCalled = false
    
    /// 是否调用了 delete
    var deleteCalled = false
    
    /// 保存的错题
    var savedItem: ReviewItem?
    
    /// 删除的错题 ID
    var deletedItemId: UUID?
    
    // MARK: - Error Simulation
    
    /// 是否模拟保存错误
    var shouldThrowOnSave = false
    
    /// 是否模拟删除错误
    var shouldThrowOnDelete = false
    
    // MARK: - Required Protocol Methods
    
    func fetchAll() -> [ReviewItem] {
        fetchAllCalled = true
        return items
    }
    
    func fetch(subject: Subject?, mastery: MasteryLevel?) -> [ReviewItem] {
        var result = items
        if let subject = subject {
            result = result.filter { $0.subject == subject }
        }
        if let mastery = mastery {
            result = result.filter { $0.mastery == mastery }
        }
        return result
    }
    
    func fetchForReview() -> [ReviewItem] {
        fetchForReviewCalled = true
        return items.filter { $0.needsReview }
    }
    
    func search(query: String) -> [ReviewItem] {
        guard !query.isEmpty else { return items }
        return items.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.note.localizedCaseInsensitiveContains(query)
        }
    }
    
    func save(_ item: ReviewItem) throws {
        saveCalled = true
        savedItem = item
        
        if shouldThrowOnSave {
            throw MockError.saveFailed
        }
        
        if !items.contains(where: { $0.id == item.id }) {
            items.append(item)
        }
    }
    
    func delete(_ item: ReviewItem) throws {
        deleteCalled = true
        deletedItemId = item.id
        
        if shouldThrowOnDelete {
            throw MockError.deleteFailed
        }
        
        items.removeAll { $0.id == item.id }
    }
    
    func delete(_ items: [ReviewItem]) throws {
        for item in items {
            try delete(item)
        }
    }
    
    func deleteAll() throws {
        items.removeAll()
    }
    
    func statistics() -> ReviewStatistics {
        return mockStatistics ?? ReviewStatistics(from: items)
    }
    
    // MARK: - Reset
    
    /// 重置所有调用记录
    func reset() {
        fetchAllCalled = false
        fetchForReviewCalled = false
        saveCalled = false
        deleteCalled = false
        savedItem = nil
        deletedItemId = nil
        shouldThrowOnSave = false
        shouldThrowOnDelete = false
    }
}

// MARK: - MockError

/// Mock 测试错误
enum MockError: Error, LocalizedError {
    case saveFailed
    case deleteFailed
    case fetchFailed
    case customError(String)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed: return "Mock: 保存失败"
        case .deleteFailed: return "Mock: 删除失败"
        case .fetchFailed: return "Mock: 获取失败"
        case .customError(let message): return "Mock: \(message)"
        }
    }
}
