import Foundation
import SwiftData
import ReviewKitCore

/// 兼容旧代码的类型别名
public typealias ReviewItem = ReviewItemModel

/// 复习项模型
///
/// SwiftData @Model，同时承担持久化和业务逻辑。
/// 图片存储在磁盘（通过 ImageStorageService），此处只存文件名。
@Model
public final class ReviewItemModel {

    // MARK: - Core Properties

    /// 主键 ID
    public var id: UUID
    /// 图片文件路径（可选）
    public var imagePath: String?
    /// 标题
    public var title: String
    /// 题目内容
    public var content: String
    /// 备注
    public var note: String

    // MARK: - Timestamp Properties

    /// 创建时间
    public var createdAt: Date
    /// 最近更新时间
    public var updatedAt: Date

    // MARK: - Review Properties

    /// 掌握程度 (0-4: none → mastered)
    public var masteryLevel: Int
    /// 下次复习时间
    public var nextReviewDate: Date
    /// 累计复习次数
    public var reviewCount: Int

    // MARK: - Classification Properties

    /// 学科原始值
    public var subjectRaw: String
    /// 年级原始值
    public var gradeRaw: String
    /// 知识点标签
    public var knowledgePoints: [String]
    /// 难度原始值
    public var difficultyRaw: Int
    /// 错题类型原始值
    public var errorTypeRaw: String
    /// 来源原始值
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
        content: String = "",
        note: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        masteryLevel: Int = 0,
        nextReviewDate: Date = Date(),
        reviewCount: Int = 0,
        subjectRaw: String = Subject.math.rawValue,
        gradeRaw: String = Grade.grade10.rawValue,
        knowledgePoints: [String] = [],
        difficultyRaw: Int = Difficulty.medium.rawValue,
        errorTypeRaw: String = ErrorType.other.rawValue,
        sourceRaw: String = Source.other.rawValue,
        reviewItemTypeRaw: String = ReviewItemType.other.rawValue,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.imagePath = imagePath
        self.title = title
        self.content = content
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.masteryLevel = masteryLevel
        self.nextReviewDate = nextReviewDate
        self.reviewCount = reviewCount
        self.subjectRaw = subjectRaw
        self.gradeRaw = gradeRaw
        self.knowledgePoints = knowledgePoints
        self.difficultyRaw = difficultyRaw
        self.errorTypeRaw = errorTypeRaw
        self.sourceRaw = sourceRaw
        self.reviewItemTypeRaw = reviewItemTypeRaw
        self.isFavorite = isFavorite
    }
    
    // MARK: - Computed Properties (充血模型)
    /// 是否已绑定图片
    public var hasImage: Bool { imagePath != nil && !imagePath!.isEmpty }
    /// 是否到期需要复习
    public var needsReview: Bool { nextReviewDate <= Date() }
    /// 是否已掌握
    public var isMastered: Bool { masteryLevel >= MasteryLevel.mastered.rawValue }
    /// 是否已逾期
    public var isOverdue: Bool { nextReviewDate < Calendar.current.startOfDay(for: Date()) }
    /// 展示用标题（自动填充占位）
    public var displayTitle: String { title.isEmpty ? String(localized: "未命名错题") : title }
    
    // MARK: - Value Object Accessors
    /// 学科枚举映射
    public var subject: Subject {
        get { Subject(rawValue: subjectRaw) ?? .other }
        set { subjectRaw = newValue.rawValue }
    }
    /// 年级枚举映射
    public var grade: Grade {
        get { Grade(rawValue: gradeRaw) ?? .grade10 }
        set { gradeRaw = newValue.rawValue }
    }
    /// 难度枚举映射
    public var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .medium }
        set { difficultyRaw = newValue.rawValue }
    }
    /// 错题类型枚举映射
    public var errorType: ErrorType {
        get { ErrorType(rawValue: errorTypeRaw) ?? .other }
        set { errorTypeRaw = newValue.rawValue }
    }
    /// 来源枚举映射
    public var source: Source {
        get { Source(rawValue: sourceRaw) ?? .other }
        set { sourceRaw = newValue.rawValue }
    }
    /// 题型枚举映射
    public var reviewItemType: ReviewItemType {
        get { ReviewItemType(rawValue: reviewItemTypeRaw) ?? .other }
        set { reviewItemTypeRaw = newValue.rawValue }
    }
    /// 掌握程度枚举映射
    public var mastery: MasteryLevel {
        get { MasteryLevel(rawValue: masteryLevel) ?? .none }
        set { masteryLevel = newValue.rawValue }
    }
    
    /// 更新更新时间戳
    public func markAsUpdated() {
        updatedAt = Date()
    }
}