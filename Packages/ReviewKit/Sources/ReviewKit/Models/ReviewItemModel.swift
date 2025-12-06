//
//  ReviewItemModel.swift
//  ReviewKit
//
//  SwiftData 持久化模型（充血模型）
//
//  实用主义架构：@Model 直接作为业务实体
//  图片存储在 FileManager，数据库只存路径
//

import Foundation
import SwiftData

// MARK: - Type Aliases (兼容旧代码)

/// 兼容旧代码的类型别名
public typealias ReviewItem = ReviewItemModel

// MARK: - ReviewItemModel

/// 复习项模型
///
/// SwiftData @Model，同时承担持久化和业务逻辑。
/// 图片存储在磁盘（通过 ImageStorageService），此处只存文件名。
///
/// ## 存储策略
/// - 文本数据：直接存储在 SwiftData
/// - 图片数据：存储在 Documents/Images/，这里只存文件名
/// - 值对象：以 rawValue 形式存储
///
/// ## 命名空间说明
/// 将此 Model 放在 ReviewKit Package 中，确保主 App 和 Widget
/// 使用相同的完全限定类名 `ReviewKit.ReviewItemModel`，
/// 避免 SwiftData 无法识别数据的问题。
@Model
public final class ReviewItemModel {

    // MARK: - Core Properties

    /// 唯一标识符
    public var id: UUID

    /// 图片文件名（存储在 Documents/Images/ 目录）
    /// 使用 ImageStorageService 读写实际图片
    public var imagePath: String?

    /// 标题
    public var title: String

    /// 用户备注/笔记
    public var note: String

    // MARK: - Timestamp Properties

    /// 创建时间
    public var createdAt: Date

    /// 更新时间
    public var updatedAt: Date

    // MARK: - Review Properties

    /// 掌握程度 (0-3: none, partial, mostly, mastered)
    public var masteryLevel: Int

    /// 下次复习时间
    public var nextReviewDate: Date

    /// 复习次数
    public var reviewCount: Int

    // MARK: - Classification Properties

    /// 学科原始值
    public var subjectRaw: String

    /// 年级原始值
    public var gradeRaw: String

    /// 知识点（逗号分隔）
    public var knowledgePointsRaw: String

    /// 难度等级 (1-5)
    public var difficultyRaw: Int

    /// 错误类型原始值
    public var errorTypeRaw: String

    /// 题目来源原始值
    public var sourceRaw: String

    /// 题型原始值
    public var reviewItemTypeRaw: String
    
    /// 是否收藏
    public var isFavorite: Bool

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        imagePath: String? = nil,
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
        self.imagePath = imagePath
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
    
    // MARK: - Computed Properties (充血模型)
    
    /// 是否有图片
    public var hasImage: Bool {
        imagePath != nil && !imagePath!.isEmpty
    }
    
    /// 是否需要复习（今天或更早）
    public var needsReview: Bool {
        nextReviewDate <= Date()
    }
    
    /// 是否已掌握
    public var isMastered: Bool {
        masteryLevel >= 3
    }
    
    /// 是否逾期
    public var isOverdue: Bool {
        nextReviewDate < Calendar.current.startOfDay(for: Date())
    }
    
    /// 知识点数组
    public var knowledgePoints: [String] {
        get {
            knowledgePointsRaw.isEmpty ? [] : knowledgePointsRaw.components(separatedBy: ",")
        }
        set {
            knowledgePointsRaw = newValue.joined(separator: ",")
        }
    }
    
    /// 显示用标题（空时返回默认值）
    public var displayTitle: String {
        title.isEmpty ? String(localized: "未命名错题") : title
    }
    
    // MARK: - Value Object Accessors
    
    /// 学科（转换为值对象）
    public var subject: Subject {
        get { Subject(rawValue: subjectRaw) ?? .other }
        set { subjectRaw = newValue.rawValue }
    }
    
    /// 年级（转换为值对象）
    public var grade: Grade {
        get { Grade(rawValue: gradeRaw) ?? .grade10 }
        set { gradeRaw = newValue.rawValue }
    }
    
    /// 难度（转换为值对象）
    public var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .medium }
        set { difficultyRaw = newValue.rawValue }
    }
    
    /// 错误类型（转换为值对象）
    public var errorType: ErrorType {
        get { ErrorType(rawValue: errorTypeRaw) ?? .other }
        set { errorTypeRaw = newValue.rawValue }
    }
    
    /// 来源（转换为值对象）
    public var source: Source {
        get { Source(rawValue: sourceRaw) ?? .other }
        set { sourceRaw = newValue.rawValue }
    }
    
    /// 题型（转换为值对象）
    public var reviewItemType: ReviewItemType {
        get { ReviewItemType(rawValue: reviewItemTypeRaw) ?? .other }
        set { reviewItemTypeRaw = newValue.rawValue }
    }
    
    /// 掌握程度（转换为值对象）
    public var mastery: MasteryLevel {
        get { MasteryLevel(rawValue: masteryLevel) ?? .none }
        set { masteryLevel = newValue.rawValue }
    }
    
    // MARK: - Business Methods (充血模型)
    
    /// 记录一次复习
    /// - Parameter performance: 掌握程度 (0-3)
    public func recordReview(performance: Int) {
        let clampedPerformance = max(0, min(3, performance))
        masteryLevel = clampedPerformance
        reviewCount += 1
        updatedAt = Date()
        
        // 使用 ReviewScheduler 计算下次复习时间
        nextReviewDate = ReviewScheduler.calculateNextReviewDate(
            currentMastery: clampedPerformance,
            reviewCount: reviewCount
        )
    }
    
    /// 重置复习进度
    public func resetProgress() {
        masteryLevel = 0
        reviewCount = 0
        nextReviewDate = Date()
        updatedAt = Date()
    }
    
    /// 标记为已更新
    public func markAsUpdated() {
        updatedAt = Date()
    }
}
