//
//  ReviewItem.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import Foundation
import SwiftData

// MARK: - ReviewItem

/// 复习项实体
///
/// 代表一个具体的错题或需要复习的知识点。
/// 使用 SwiftData 进行持久化存储。
///
/// ## 数据模型设计
///
/// 为了与 SwiftData 兼容，值对象（Value Objects）通过 `rawValue` 形式存储：
/// - 枚举类型：存储 `String` 或 `Int` 类型的 `rawValue`
/// - 复合类型：存储序列化后的字符串
///
/// ## 扩展文件
///
/// - `ReviewItem+Accessors.swift`: 值对象访问器
/// - `ReviewItem+Computed.swift`: 计算属性
/// - `ReviewItem+Display.swift`: 显示属性
/// - `ReviewItem+Actions.swift`: 行为方法
///
/// ## 使用示例
///
/// ```swift
/// // 创建新错题
/// let item = ReviewItem(
///     title: "二次函数求极值",
///     subject: .math,
///     grade: .grade10,
///     difficulty: .hard
/// )
///
/// // 记录复习
/// item.recordReview(newMastery: .partial)
///
/// // 检查是否需要复习
/// if item.needsReview {
///     print("该复习了！")
/// }
/// ```
@Model
final class ReviewItem {
    
    // MARK: - Core Properties
    
    /// 唯一标识符
    var id: UUID
    
    /// 错题图片数据
    ///
    /// 使用 `.externalStorage` 优化大数据存储，
    /// 图片数据将存储在外部文件中。
    @Attribute(.externalStorage)
    var imageData: Data?
    
    /// 标题
    ///
    /// 通常是 OCR 识别出的首行文字或用户自定义标题。
    /// 创建时如果为空，默认设置为「未命名错题」。
    var title: String
    
    /// 用户备注/笔记
    ///
    /// 用于记录解题思路、易错点等补充信息。
    var note: String
    
    // MARK: - Timestamp Properties
    
    /// 创建时间
    var createdAt: Date
    
    /// 更新时间
    ///
    /// 每次修改时应更新此字段。
    var updatedAt: Date
    
    // MARK: - Review Properties
    
    /// 掌握程度原始值
    ///
    /// 存储 `MasteryLevel` 的 `rawValue`。
    /// 请通过 `mastery` 访问器使用。
    var masteryLevel: Int
    
    /// 下次复习时间
    ///
    /// 基于艾宾浩斯遗忘曲线算法计算。
    var nextReviewDate: Date
    
    /// 复习次数
    ///
    /// 记录已完成的复习次数，影响复习间隔计算。
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
    
    /// 题目类型原始值
    var questionTypeRaw: String
    
    // MARK: - Initialization
    
    /// 创建新的复习项
    ///
    /// - Parameters:
    ///   - id: 唯一标识符，默认自动生成
    ///   - imageData: 错题图片数据
    ///   - title: 标题，为空时默认「未命名错题」
    ///   - note: 用户笔记
    ///   - createdAt: 创建时间，默认当前时间
    ///   - mastery: 初始掌握程度，默认 `.none`
    ///   - subject: 学科，默认数学
    ///   - grade: 年级，默认高一
    ///   - knowledgePoints: 知识点列表
    ///   - difficulty: 难度等级，默认中等
    ///   - errorType: 错误类型
    ///   - source: 题目来源
    ///   - questionType: 题目类型
    init(
        id: UUID = UUID(),
        imageData: Data? = nil,
        title: String = "",
        note: String = "",
        createdAt: Date = Date(),
        mastery: MasteryLevel = .none,
        subject: Subject = .math,
        grade: Grade = .grade10,
        knowledgePoints: KnowledgePoints = .empty,
        difficulty: Difficulty = .medium,
        errorType: ErrorType = .other,
        source: Source = .other,
        questionType: ReviewItemType = .other
    ) {
        self.id = id
        self.imageData = imageData
        self.title = title.isEmpty ? "未命名错题" : title
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.masteryLevel = mastery.rawValue
        self.nextReviewDate = createdAt
        self.reviewCount = 0
        self.subjectRaw = subject.rawValue
        self.gradeRaw = grade.rawValue
        self.knowledgePointsRaw = knowledgePoints.rawValue
        self.difficultyRaw = difficulty.rawValue
        self.errorTypeRaw = errorType.rawValue
        self.sourceRaw = source.rawValue
        self.questionTypeRaw = questionType.rawValue
    }
    
    // MARK: - Internal Helpers
    
    /// 标记为已更新
    ///
    /// 更新 `updatedAt` 时间戳。
    /// 供扩展文件中的方法调用。
    func markAsUpdated() {
        updatedAt = Date()
    }
}
