//
//  ReviewItemModel.swift
//  NotBad
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
typealias ReviewItem = ReviewItemModel

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
@Model
final class ReviewItemModel {

    // MARK: - Core Properties

    /// 唯一标识符
    var id: UUID

    /// 图片文件名（存储在 Documents/Images/ 目录）
    /// 使用 ImageStorageService 读写实际图片
    var imagePath: String?

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

    /// 掌握程度 (0-3: none, partial, mostly, mastered)
    var masteryLevel: Int

    /// 下次复习时间
    var nextReviewDate: Date

    /// 复习次数
    var reviewCount: Int

    // MARK: - Classification Properties

    /// 学科原始值
    var subjectRaw: String

    /// 年级原始值
    var gradeRaw: String

    /// 知识点（逗号分隔）
    var knowledgePointsRaw: String

    /// 难度等级 (1-5)
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

    init(
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
    var hasImage: Bool {
        imagePath != nil && !imagePath!.isEmpty
    }
    
    /// 是否需要复习（今天或更早）
    var needsReview: Bool {
        nextReviewDate <= Date()
    }
    
    /// 是否已掌握
    var isMastered: Bool {
        masteryLevel >= 3
    }
    
    /// 是否逾期
    var isOverdue: Bool {
        nextReviewDate < Calendar.current.startOfDay(for: Date())
    }
    
    /// 知识点数组
    var knowledgePoints: [String] {
        get {
            knowledgePointsRaw.isEmpty ? [] : knowledgePointsRaw.components(separatedBy: ",")
        }
        set {
            knowledgePointsRaw = newValue.joined(separator: ",")
        }
    }
    
    /// 显示用标题（空时返回默认值）
    var displayTitle: String {
        title.isEmpty ? String(localized: "未命名错题") : title
    }
    
    // MARK: - Value Object Accessors
    
    /// 学科（转换为值对象）
    var subject: Subject {
        get { Subject(rawValue: subjectRaw) ?? .other }
        set { subjectRaw = newValue.rawValue }
    }
    
    /// 年级（转换为值对象）
    var grade: Grade {
        get { Grade(rawValue: gradeRaw) ?? .grade10 }
        set { gradeRaw = newValue.rawValue }
    }
    
    /// 难度（转换为值对象）
    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .medium }
        set { difficultyRaw = newValue.rawValue }
    }
    
    /// 错误类型（转换为值对象）
    var errorType: ErrorType {
        get { ErrorType(rawValue: errorTypeRaw) ?? .other }
        set { errorTypeRaw = newValue.rawValue }
    }
    
    /// 来源（转换为值对象）
    var source: Source {
        get { Source(rawValue: sourceRaw) ?? .other }
        set { sourceRaw = newValue.rawValue }
    }
    
    /// 题型（转换为值对象）
    var reviewItemType: ReviewItemType {
        get { ReviewItemType(rawValue: reviewItemTypeRaw) ?? .other }
        set { reviewItemTypeRaw = newValue.rawValue }
    }
    
    /// 掌握程度（转换为值对象）
    var mastery: MasteryLevel {
        get { MasteryLevel(rawValue: masteryLevel) ?? .none }
        set { masteryLevel = newValue.rawValue }
    }
    
    // MARK: - Business Methods (充血模型)
    
    /// 记录一次复习
    /// - Parameter performance: 掌握程度 (0-3)
    func recordReview(performance: Int) {
        let clampedPerformance = max(0, min(3, performance))
        masteryLevel = clampedPerformance
        reviewCount += 1
        updatedAt = Date()
        
        // 根据表现计算下次复习时间（艾宾浩斯遗忘曲线简化版）
        nextReviewDate = ReviewScheduler.calculateNextReviewDate(
            currentMastery: clampedPerformance,
            reviewCount: reviewCount
        )
    }
    
    /// 重置复习进度
    func resetProgress() {
        masteryLevel = 0
        reviewCount = 0
        nextReviewDate = Date()
        updatedAt = Date()
    }
    
    /// 标记为已更新
    func markAsUpdated() {
        updatedAt = Date()
    }
}

// MARK: - ReviewScheduler

/// 复习调度器（核心算法）
///
/// 基于艾宾浩斯遗忘曲线的简化实现
enum ReviewScheduler {
    
    /// 计算下次复习日期
    /// - Parameters:
    ///   - currentMastery: 当前掌握程度 (0-3)
    ///   - reviewCount: 已复习次数
    /// - Returns: 下次复习日期
    static func calculateNextReviewDate(currentMastery: Int, reviewCount: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        
        // 基础间隔（天）
        let baseIntervals: [Int] = [1, 2, 4, 7, 14, 30, 60]
        
        // 根据掌握程度调整
        let masteryMultiplier: Double = switch currentMastery {
        case 0: 0.5   // 完全不会，缩短间隔
        case 1: 0.75  // 部分掌握
        case 2: 1.0   // 大部分掌握
        case 3: 1.5   // 完全掌握，延长间隔
        default: 1.0
        }
        
        // 取对应的基础间隔
        let index = min(reviewCount, baseIntervals.count - 1)
        let baseInterval = baseIntervals[index]
        
        // 计算实际间隔
        let actualInterval = Int(Double(baseInterval) * masteryMultiplier)
        
        return calendar.date(byAdding: .day, value: max(1, actualInterval), to: today) ?? today
    }
}
