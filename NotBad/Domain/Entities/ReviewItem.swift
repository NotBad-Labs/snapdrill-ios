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
/// ## 核心功能
///
/// - **错题记录**：图片、标题、笔记
/// - **分类标签**：学科、年级、题型、来源
/// - **学习追踪**：掌握程度、复习次数、知识点
/// - **复习调度**：基于艾宾浩斯遗忘曲线计算复习时间
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
///
/// - Note: SwiftData `@Model` 宏会自动生成持久化相关代码
/// - Important: 值对象访问器提供类型安全的接口
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
}

// MARK: - ReviewItem Value Object Accessors

extension ReviewItem {
    
    /// 学科
    var subject: Subject {
        get { Subject(rawValue: subjectRaw) ?? .other }
        set {
            subjectRaw = newValue.rawValue
            markAsUpdated()
        }
    }
    
    /// 年级
    var grade: Grade {
        get { Grade(rawValue: gradeRaw) ?? .grade10 }
        set {
            gradeRaw = newValue.rawValue
            markAsUpdated()
        }
    }
    
    /// 掌握程度
    var mastery: MasteryLevel {
        get { MasteryLevel(rawValue: masteryLevel) ?? .none }
        set {
            masteryLevel = newValue.rawValue
            markAsUpdated()
        }
    }
    
    /// 知识点
    var knowledgePoints: KnowledgePoints {
        get { KnowledgePoints(from: knowledgePointsRaw) }
        set {
            knowledgePointsRaw = newValue.rawValue
            markAsUpdated()
        }
    }
    
    /// 难度等级
    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .medium }
        set {
            difficultyRaw = newValue.rawValue
            markAsUpdated()
        }
    }
    
    /// 错误类型
    var errorType: ErrorType {
        get { ErrorType(rawValue: errorTypeRaw) ?? .other }
        set {
            errorTypeRaw = newValue.rawValue
            markAsUpdated()
        }
    }
    
    /// 题目来源
    var source: Source {
        get { Source(rawValue: sourceRaw) ?? .other }
        set {
            sourceRaw = newValue.rawValue
            markAsUpdated()
        }
    }
    
    /// 题目类型
    var questionType: ReviewItemType {
        get { ReviewItemType(rawValue: questionTypeRaw) ?? .other }
        set {
            questionTypeRaw = newValue.rawValue
            markAsUpdated()
        }
    }
}

// MARK: - ReviewItem Computed Properties

extension ReviewItem {
    
    /// 复习间隔计算器
    ///
    /// 基于当前复习次数和掌握程度计算。
    var reviewInterval: ReviewInterval {
        ReviewInterval.calculate(reviewCount: reviewCount, mastery: mastery)
    }
    
    /// 是否有图片
    var hasImage: Bool {
        imageData != nil && !(imageData?.isEmpty ?? true)
    }
    
    /// 是否有笔记
    var hasNote: Bool {
        !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// 是否有知识点
    var hasKnowledgePoints: Bool {
        !knowledgePoints.isEmpty
    }
    
    /// 是否需要复习
    ///
    /// 基于下次复习日期判断。
    var needsReview: Bool {
        nextReviewDate <= Date()
    }
    
    /// 是否已逾期
    var isOverdue: Bool {
        reviewInterval.isOverdue
    }
    
    /// 是否已掌握
    ///
    /// 掌握程度达到 `.good` 或以上。
    var isMastered: Bool {
        mastery.isMastered
    }
    
    /// 是否为新录入（从未复习）
    var isNew: Bool {
        reviewCount == 0
    }
    
    /// 距离下次复习的天数
    var daysUntilReview: Int {
        reviewInterval.daysUntilReview
    }
    
    /// 估算记忆保持率
    var estimatedRetention: Double {
        reviewInterval.estimatedRetention
    }
    
    /// 复习紧迫程度（1-5）
    var urgencyLevel: Int {
        reviewInterval.urgencyLevel
    }
    
    /// 创建至今的天数
    var daysSinceCreation: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }
    
    /// 综合难度分数
    ///
    /// 结合题型权重和难度等级计算。
    var overallDifficultyScore: Double {
        Double(difficulty.rawValue) * questionType.difficultyWeight
    }
}

// MARK: - ReviewItem Display Properties

extension ReviewItem {
    
    /// 显示标题
    ///
    /// 如果标题为空或仅空白，返回默认标题。
    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "未命名错题" : trimmed
    }
    
    /// 简短描述
    ///
    /// 格式：「学科 · 题型」
    var shortDescription: String {
        "\(subject.displayName) · \(questionType.displayName)"
    }
    
    /// 完整描述
    ///
    /// 格式：「学科 · 年级 · 题型 · 难度」
    var fullDescription: String {
        "\(subject.displayName) · \(grade.displayName) · \(questionType.displayName) · \(difficulty.displayName)"
    }
    
    /// 复习状态描述
    var reviewStatusDescription: String {
        if isNew {
            return "新录入，尚未复习"
        } else if needsReview {
            return isOverdue ? "已逾期 \(reviewInterval.overdueByDays) 天" : "今天需要复习"
        } else {
            return "\(daysUntilReview) 天后复习"
        }
    }
    
    /// 掌握状态描述
    var masteryStatusDescription: String {
        "\(mastery.displayName) · 已复习 \(reviewCount) 次"
    }
}

// MARK: - ReviewItem Actions

extension ReviewItem {
    
    /// 记录一次复习
    ///
    /// 更新掌握程度、复习次数和下次复习日期。
    ///
    /// - Parameter newMastery: 本次复习后的掌握程度
    func recordReview(newMastery: MasteryLevel) {
        mastery = newMastery
        reviewCount += 1
        
        // 计算下次复习日期
        let interval = ReviewInterval.calculate(
            reviewCount: reviewCount,
            mastery: newMastery
        )
        nextReviewDate = interval.nextReviewDate
        
        markAsUpdated()
    }
    
    /// 重置复习进度
    ///
    /// 将复习次数清零，掌握程度重置为初始状态。
    func resetProgress() {
        reviewCount = 0
        mastery = .none
        nextReviewDate = Date()
        markAsUpdated()
    }
    
    /// 添加知识点
    ///
    /// - Parameter point: 要添加的知识点
    func addKnowledgePoint(_ point: String) {
        var current = knowledgePoints
        current = current.adding(point)
        knowledgePoints = current
    }
    
    /// 移除知识点
    ///
    /// - Parameter point: 要移除的知识点
    func removeKnowledgePoint(_ point: String) {
        var current = knowledgePoints
        current = current.removing(point)
        knowledgePoints = current
    }
    
    /// 更新笔记
    ///
    /// - Parameter newNote: 新的笔记内容
    func updateNote(_ newNote: String) {
        note = newNote
        markAsUpdated()
    }
    
    /// 更新标题
    ///
    /// - Parameter newTitle: 新的标题
    func updateTitle(_ newTitle: String) {
        title = newTitle.isEmpty ? "未命名错题" : newTitle
        markAsUpdated()
    }
    
    /// 标记为已更新
    ///
    /// 更新 `updatedAt` 时间戳。
    private func markAsUpdated() {
        updatedAt = Date()
    }
}

// MARK: - ReviewItem Validation

extension ReviewItem {
    
    /// 验证数据完整性
    ///
    /// - Returns: 验证结果和问题列表
    func validate() -> (isValid: Bool, issues: [String]) {
        var issues: [String] = []
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append("标题不能为空")
        }
        
        if imageData == nil && note.isEmpty {
            issues.append("建议添加图片或笔记")
        }
        
        if knowledgePoints.isEmpty {
            issues.append("建议添加知识点标签")
        }
        
        return (issues.isEmpty, issues)
    }
    
    /// 是否数据完整
    var isComplete: Bool {
        hasImage && hasKnowledgePoints && !title.isEmpty
    }
}

// MARK: - ReviewItem Comparable

extension ReviewItem: Comparable {
    
    /// 按紧迫程度排序
    ///
    /// 越需要复习的排在前面。
    static func < (lhs: ReviewItem, rhs: ReviewItem) -> Bool {
        lhs.nextReviewDate < rhs.nextReviewDate
    }
}

// MARK: - ReviewItem CustomStringConvertible

extension ReviewItem: CustomStringConvertible {
    
    /// 调试描述
    var description: String {
        "ReviewItem(\(displayTitle), \(shortDescription), \(masteryStatusDescription))"
    }
}
