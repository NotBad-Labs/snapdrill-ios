//
//  ReviewItemMapper.swift
//  NotBad
//
//  领域实体与持久化模型的映射器
//

import Foundation

// MARK: - ReviewItemMapper

/// ReviewItem 映射器
///
/// 负责 Domain 层实体和 Data 层模型之间的转换。
///
/// ## 重要说明
///
/// **图片数据分离存储**：图片不再存储在 ReviewItemModel 中，
/// 而是由 ImageRepository 独立管理，存储在 ReviewItemImageModel 中。
///
/// ## 映射规则
///
/// | 方向 | 图片处理 |
/// |------|----------|
/// | Model → Entity | `toEntity()` 包含图片（兼容旧数据），`toEntityWithoutImage()` 不含图片 |
/// | Entity → Model | `toModel()` / `updateModel()` 不写入图片，图片由 ImageRepository 管理 |
///
/// ## 使用示例
///
/// ```swift
/// // Model → Entity（列表场景，不加载图片）
/// let entity = ReviewItemMapper.toEntityWithoutImage(from: model)
///
/// // Model → Entity（详情场景，加载完整数据 - 兼容旧数据）
/// let entity = ReviewItemMapper.toEntity(from: model)
///
/// // Entity → Model (新建)
/// let model = ReviewItemMapper.toModel(from: entity)
/// // 图片单独保存：imageRepository.saveImage(imageData, for: entity.id)
///
/// // Entity → Model (更新现有)
/// ReviewItemMapper.updateModel(model, from: entity)
/// // 图片单独更新：imageRepository.updateImage(imageData, for: entity.id)
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
    
    // MARK: - Lightweight Conversion (No Image Data)
    
    /// 将持久化模型转换为轻量领域实体（不加载图片数据）
    ///
    /// 用于列表展示等场景，避免一次性加载大量图片数据导致内存溢出。
    /// 图片数据可以在需要时通过 `fetchImageData(for:)` 单独加载。
    ///
    /// - Parameter model: SwiftData 模型
    /// - Returns: 不含图片数据的领域实体
    static func toEntityWithoutImage(from model: ReviewItemModel) -> ReviewItem {
        ReviewItem(
            id: model.id,
            imageData: nil,  // 不加载图片数据
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
    
    /// 批量转换模型为轻量实体（不加载图片数据）
    ///
    /// - Parameter models: 模型数组
    /// - Returns: 不含图片数据的实体数组
    static func toEntitiesWithoutImage(_ models: [ReviewItemModel]) -> [ReviewItem] {
        models.map { toEntityWithoutImage(from: $0) }
    }

    // MARK: - Entity → Model

    /// 将领域实体转换为持久化模型（新建）
    ///
    /// - Parameter entity: 领域实体
    /// - Returns: 新的 SwiftData 模型
    ///
    /// - Note: imageData 不写入此模型，图片数据由 ImageRepository 独立存储
    static func toModel(from entity: ReviewItem) -> ReviewItemModel {
        ReviewItemModel(
            id: entity.id,
            imageData: nil,  // 图片数据由 ImageRepository 独立存储
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
    ///
    /// - Note: imageData 不在此处更新，图片数据存储在独立的 ReviewItemImageModel 中
    static func updateModel(_ model: ReviewItemModel, from entity: ReviewItem) {
        // 注意：imageData 不更新，图片数据由 ImageRepository 独立管理
        // model.imageData = entity.imageData  // 已移除
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
