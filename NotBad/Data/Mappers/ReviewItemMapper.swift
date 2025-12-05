//
//  ReviewItemMapper.swift
//  NotBad
//
//  领域实体与持久化模型的双向映射器
//

import Foundation

// MARK: - ReviewItemMapper

/// ReviewItem 映射器
///
/// 负责 Domain 层实体和 Data 层模型之间的转换。
///
/// ## 使用示例
///
/// ```swift
/// // Model → Entity
/// let entity = ReviewItemMapper.toEntity(from: model)
///
/// // Entity → Model (新建)
/// let model = ReviewItemMapper.toModel(from: entity)
///
/// // Entity → Model (更新现有)
/// ReviewItemMapper.updateModel(model, from: entity)
/// ```
enum ReviewItemMapper {

    // MARK: - Model → Entity

    /// 将持久化模型转换为领域实体
    ///
    /// - Parameter model: SwiftData 模型
    /// - Returns: 领域实体
    static func toEntity(from model: ReviewItemModel) -> ReviewItem {
        ReviewItem(
            id: model.id,
            imageData: model.imageData,
            title: model.title,
            note: model.note,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt,
            masteryLevel: model.masteryLevel,
            nextReviewDate: model.nextReviewDate,
            reviewCount: model.reviewCount,
            subjectRaw: model.subjectRaw,
            gradeRaw: model.gradeRaw,
            knowledgePointsRaw: model.knowledgePointsRaw,
            difficultyRaw: model.difficultyRaw,
            errorTypeRaw: model.errorTypeRaw,
            sourceRaw: model.sourceRaw,
            reviewItemTypeRaw: model.reviewItemTypeRaw,
            isFavorite: model.isFavorite
        )
    }

    /// 批量转换模型为实体
    ///
    /// - Parameter models: 模型数组
    /// - Returns: 实体数组
    static func toEntities(_ models: [ReviewItemModel]) -> [ReviewItem] {
        models.map { toEntity(from: $0) }
    }

    // MARK: - Entity → Model

    /// 将领域实体转换为持久化模型（新建）
    ///
    /// - Parameter entity: 领域实体
    /// - Returns: 新的 SwiftData 模型
    static func toModel(from entity: ReviewItem) -> ReviewItemModel {
        ReviewItemModel(
            id: entity.id,
            imageData: entity.imageData,
            title: entity.title,
            note: entity.note,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            masteryLevel: entity.masteryLevel,
            nextReviewDate: entity.nextReviewDate,
            reviewCount: entity.reviewCount,
            subjectRaw: entity.subjectRaw,
            gradeRaw: entity.gradeRaw,
            knowledgePointsRaw: entity.knowledgePointsRaw,
            difficultyRaw: entity.difficultyRaw,
            errorTypeRaw: entity.errorTypeRaw,
            sourceRaw: entity.sourceRaw,
            reviewItemTypeRaw: entity.reviewItemTypeRaw,
            isFavorite: entity.isFavorite
        )
    }

    /// 更新现有模型（用于保存变更）
    ///
    /// - Parameters:
    ///   - model: 现有的 SwiftData 模型
    ///   - entity: 更新后的领域实体
    static func updateModel(_ model: ReviewItemModel, from entity: ReviewItem) {
        model.imageData = entity.imageData
        model.title = entity.title
        model.note = entity.note
        model.updatedAt = entity.updatedAt
        model.masteryLevel = entity.masteryLevel
        model.nextReviewDate = entity.nextReviewDate
        model.reviewCount = entity.reviewCount
        model.subjectRaw = entity.subjectRaw
        model.gradeRaw = entity.gradeRaw
        model.knowledgePointsRaw = entity.knowledgePointsRaw
        model.difficultyRaw = entity.difficultyRaw
        model.errorTypeRaw = entity.errorTypeRaw
        model.sourceRaw = entity.sourceRaw
        model.reviewItemTypeRaw = entity.reviewItemTypeRaw
        model.isFavorite = entity.isFavorite
    }
}
