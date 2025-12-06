//
//  ReviewItemModel.swift
//  NotBad
//
//  SwiftData 持久化模型
//
//  这是数据层的持久化模型，与 Domain 层的 ReviewItem 实体分离。
//  通过 ReviewItemMapper 进行双向映射。
//

import Foundation
import SwiftData

// MARK: - ReviewItemModel

/// 复习项持久化模型
///
/// SwiftData 模型，用于数据库存储。
/// 领域层使用 `ReviewItem` 实体，数据层使用此模型。
///
/// ## 映射关系
/// - `ReviewItemModel` → `ReviewItem` (通过 `ReviewItemMapper.toEntity()`)
/// - `ReviewItem` → `ReviewItemModel` (通过 `ReviewItemMapper.toModel()`)
///
/// ## 图片存储
/// - **新数据**：图片存储在独立的 `ReviewItemImageModel` 中，由 `ImageRepository` 管理
/// - **旧数据**：`imageData` 字段仍保留，用于兼容升级前的数据
///
/// ## 存储策略
/// - 值对象以 rawValue 形式存储
/// - 图片使用外部存储优化性能
@Model
final class ReviewItemModel {

    // MARK: - Core Properties

    /// 唯一标识符
    var id: UUID

    /// 错题图片数据
    @Attribute(.externalStorage)
    var imageData: Data?

    /// 标题
    var title: String

    /// 用户备注/笔记
    var note: String

    // MARK: - Timestamp Properties

    /// 创建时间
    var createdAt: Date

    /// 更新时间
    var updatedAt: Date

    // MARK: - Review Properties

    /// 掌握程度原始值
    var masteryLevel: Int

    /// 下次复习时间
    var nextReviewDate: Date

    /// 复习次数
    var reviewCount: Int

    // MARK: - Value Object Raw Storage

    /// 学科原始值
    var subjectRaw: String

    /// 年级原始值
    var gradeRaw: String

    /// 知识点原始值（逗号分隔）
    var knowledgePointsRaw: String

    /// 难度等级原始值
    var difficultyRaw: Int

    /// 错误类型原始值
    var errorTypeRaw: String

    /// 题目来源原始值
    var sourceRaw: String

    /// 题型原始值
    var reviewItemTypeRaw: String
    
    /// 是否收藏
    var isFavorite: Bool

    // MARK: - Initialization

    /// 创建持久化模型
    init(
        id: UUID = UUID(),
        imageData: Data? = nil,
        title: String = "",
        note: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        masteryLevel: Int = 0,
        nextReviewDate: Date = Date(),
        reviewCount: Int = 0,
        subjectRaw: String = "math",
        gradeRaw: String = "grade_10",
        knowledgePointsRaw: String = "",
        difficultyRaw: Int = 2,
        errorTypeRaw: String = "other",
        sourceRaw: String = "other",
        reviewItemTypeRaw: String = "other",
        isFavorite: Bool = false
    ) {
        self.id = id
        self.imageData = imageData
        self.title = title
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.masteryLevel = masteryLevel
        self.nextReviewDate = nextReviewDate
        self.reviewCount = reviewCount
        self.subjectRaw = subjectRaw
        self.gradeRaw = gradeRaw
        self.knowledgePointsRaw = knowledgePointsRaw
        self.difficultyRaw = difficultyRaw
        self.errorTypeRaw = errorTypeRaw
        self.sourceRaw = sourceRaw
        self.reviewItemTypeRaw = reviewItemTypeRaw
        self.isFavorite = isFavorite
    }
}
