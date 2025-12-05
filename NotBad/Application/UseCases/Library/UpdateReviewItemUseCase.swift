//
//  UpdateReviewItemUseCase.swift
//  NotBad
//
//  Application Layer - Use Case Implementation
//

import Foundation

// MARK: - UpdateReviewItemUseCase

/// 更新错题用例实现
///
/// 实现 `UpdateReviewItemUseCaseProtocol`，负责：
/// - 验证更新数据
/// - 更新 Domain 实体
/// - 保存到仓库
@MainActor
final class UpdateReviewItemUseCase: UpdateReviewItemUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let repository: ReviewItemRepositoryProtocol
    
    // MARK: - Initialization
    
    init(repository: ReviewItemRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - UpdateReviewItemUseCaseProtocol
    
    @discardableResult
    func execute(
        itemId: UUID,
        updates: ReviewItemUpdates
    ) async throws -> ReviewItem {
        // 1. 查找现有项目
        guard let item = repository.fetchAll().first(where: { $0.id == itemId }) else {
            throw UpdateReviewItemError.itemNotFound(id: itemId)
        }
        
        // 2. 应用更新
        let updatedItem = applyUpdates(updates, to: item)
        
        // 3. 保存
        do {
            try repository.save(updatedItem)
        } catch {
            throw UpdateReviewItemError.saveFailed(underlying: error)
        }
        
        return updatedItem
    }
    
    // MARK: - Batch Update
    
    /// 批量更新掌握程度
    func executeBatch(
        itemIds: [UUID],
        mastery: MasteryLevel
    ) async throws {
        let allItems = repository.fetchAll()
        var itemsToUpdate: [ReviewItem] = []
        
        for itemId in itemIds {
            guard let item = allItems.first(where: { $0.id == itemId }) else {
                continue
            }
            
            let updatedItem = ReviewItem(
                id: item.id,
                imageData: item.imageData,
                title: item.title,
                note: item.note,
                createdAt: item.createdAt,
                updatedAt: Date(),
                masteryLevel: mastery.rawValue,
                nextReviewDate: item.nextReviewDate,
                reviewCount: item.reviewCount,
                subjectRaw: item.subjectRaw,
                gradeRaw: item.gradeRaw,
                knowledgePointsRaw: item.knowledgePointsRaw,
                difficultyRaw: item.difficultyRaw,
                errorTypeRaw: item.errorTypeRaw,
                sourceRaw: item.sourceRaw,
                reviewItemTypeRaw: item.reviewItemTypeRaw,
                isFavorite: item.isFavorite
            )
            
            itemsToUpdate.append(updatedItem)
        }
        
        if !itemsToUpdate.isEmpty {
            try repository.save(itemsToUpdate)
        }
    }
    
    // MARK: - Private Methods
    
    private func applyUpdates(_ updates: ReviewItemUpdates, to item: ReviewItem) -> ReviewItem {
        ReviewItem(
            id: item.id,
            imageData: updates.removeImage ? nil : (updates.imageData ?? item.imageData),
            title: updates.title ?? item.title,
            note: updates.note ?? item.note,
            createdAt: item.createdAt,
            updatedAt: Date(),
            masteryLevel: updates.mastery?.rawValue ?? item.masteryLevel,
            nextReviewDate: item.nextReviewDate,
            reviewCount: item.reviewCount,
            subjectRaw: updates.subject?.rawValue ?? item.subjectRaw,
            gradeRaw: updates.grade?.rawValue ?? item.gradeRaw,
            knowledgePointsRaw: updates.knowledgePoints.map { KnowledgePoints($0).rawValue } ?? item.knowledgePointsRaw,
            difficultyRaw: updates.difficulty?.rawValue ?? item.difficultyRaw,
            errorTypeRaw: updates.errorType?.rawValue ?? item.errorTypeRaw,
            sourceRaw: item.sourceRaw,
            reviewItemTypeRaw: item.reviewItemTypeRaw,
            isFavorite: item.isFavorite
        )
    }
}

// MARK: - UpdateReviewItemError

/// 更新错题错误
enum UpdateReviewItemError: Error, LocalizedError, Sendable {
    case itemNotFound(id: UUID)
    case saveFailed(underlying: Error)
    case invalidUpdate(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return String(localized: "找不到要更新的错题")
        case .saveFailed:
            return String(localized: "保存失败，请重试")
        case .invalidUpdate(let reason):
            return String(localized: "更新无效：\(reason)")
        }
    }
}
