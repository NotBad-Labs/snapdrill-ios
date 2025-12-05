//
//  DeleteReviewItemUseCase.swift
//  NotBad
//
//  Application Layer - Use Case Implementation
//

import Foundation

// MARK: - DeleteReviewItemUseCase

/// 删除错题用例实现
///
/// 实现 `DeleteReviewItemUseCaseProtocol`，负责：
/// - 单个删除
/// - 批量删除
/// - 按条件删除
@MainActor
final class DeleteReviewItemUseCase: DeleteReviewItemUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let repository: ReviewItemRepositoryProtocol
    
    // MARK: - Initialization
    
    init(repository: ReviewItemRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - DeleteReviewItemUseCaseProtocol
    
    func execute(itemId: UUID) async throws {
        // 查找并删除
        let allItems = repository.fetchAll()
        guard let item = allItems.first(where: { $0.id == itemId }) else {
            throw DeleteReviewItemError.itemNotFound(id: itemId)
        }
        
        try repository.delete(item)
    }
    
    func execute(itemIds: [UUID]) async throws {
        guard !itemIds.isEmpty else { return }
        
        let allItems = repository.fetchAll()
        let itemsToDelete = allItems.filter { itemIds.contains($0.id) }
        
        guard itemsToDelete.count == itemIds.count else {
            let foundIds = Set(itemsToDelete.map(\.id))
            let missingIds = itemIds.filter { !foundIds.contains($0) }
            throw DeleteReviewItemError.someItemsNotFound(ids: missingIds)
        }
        
        try repository.delete(itemsToDelete)
    }
    
    @discardableResult
    func execute(subject: Subject) async throws -> Int {
        let items = repository.fetch(subject: subject, mastery: nil)
        
        guard !items.isEmpty else { return 0 }
        
        try repository.delete(items)
        return items.count
    }
    
    @discardableResult
    func executeMastered() async throws -> Int {
        let allItems = repository.fetchAll()
        let masteredItems = allItems.filter { $0.masteryLevel == MasteryLevel.mastered.rawValue }
        
        guard !masteredItems.isEmpty else { return 0 }
        
        try repository.delete(masteredItems)
        return masteredItems.count
    }
}

// MARK: - DeleteReviewItemError

/// 删除错题错误
enum DeleteReviewItemError: Error, LocalizedError, Sendable {
    case itemNotFound(id: UUID)
    case someItemsNotFound(ids: [UUID])
    case deleteFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return String(localized: "找不到要删除的错题")
        case .someItemsNotFound(let ids):
            return String(localized: "部分错题不存在（\(ids.count) 个）")
        case .deleteFailed:
            return String(localized: "删除失败，请重试")
        }
    }
}
