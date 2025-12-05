//
//  ReviewItem.swift
//  NotBad
//
//  纯领域实体 - 不依赖任何持久化框架
//

import Foundation

// MARK: - ReviewItem

/// 复习项实体（纯领域对象）
///
/// 代表一个具体的错题或需要复习的知识点。
/// 这是一个纯领域对象，不包含任何持久化逻辑。
///
/// ## DDD 设计
///
/// - **聚合根**：ReviewItem 是聚合根，管理自身状态
/// - **充血模型**：包含业务方法如 `recordReview()`, `resetProgress()`
/// - **不可变 ID**：创建后 ID 不可变
///
/// ## 扩展文件
///
/// - `ReviewItem+Accessors.swift`: 值对象访问器
/// - `ReviewItem+Computed.swift`: 计算属性
/// - `ReviewItem+Display.swift`: 显示属性
/// - `ReviewItem+Actions.swift`: 行为方法
/// - `ReviewItem+Validation.swift`: 数据验证
///
/// ## 使用示例
///
/// ```swift
/// // 创建新错题
/// let reviewItem = ReviewItem(
///     title: "二次函数求极值",
///     subject: .math,
///     grade: .grade10,
///     difficulty: .hard
/// )
///
/// // 记录复习
/// reviewItem.recordReview(newMastery: .partial)
///
/// // 检查是否需要复习
/// if reviewItem.needsReview {
///     print("该复习了！")
/// }
/// ```
final class ReviewItem: Identifiable, Hashable {

    // MARK: - Core Properties

    /// 唯一标识符（不可变）
    let id: UUID

    /// 错题图片数据
    var imageData: Data?

    /// 标题
    var title: String

    /// 用户备注/笔记
    var note: String

    // MARK: - Timestamp Properties

    /// 创建时间
    let createdAt: Date

    /// 更新时间
    private(set) var updatedAt: Date

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

    // MARK: - Initialization (Value Object Style)

    /// 创建新的复习项（使用值对象）
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
    ///   - reviewItemType: 题型
    ///   - isFavorite: 是否收藏，默认 false
    convenience init(
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
        reviewItemType: ReviewItemType = .other,
        isFavorite: Bool = false
    ) {
        self.init(
            id: id,
            imageData: imageData,
            title: Self.normalizeTitle(title),
            note: note,
            createdAt: createdAt,
            updatedAt: createdAt,
            masteryLevel: mastery.rawValue,
            nextReviewDate: createdAt,
            reviewCount: 0,
            subjectRaw: subject.rawValue,
            gradeRaw: grade.rawValue,
            knowledgePointsRaw: knowledgePoints.rawValue,
            difficultyRaw: difficulty.rawValue,
            errorTypeRaw: errorType.rawValue,
            sourceRaw: source.rawValue,
            reviewItemTypeRaw: reviewItemType.rawValue,
            isFavorite: isFavorite
        )
    }

    // MARK: - Initialization (Raw Values - for Mapper)

    /// 从原始值创建（供 Mapper 使用）
    init(
        id: UUID,
        imageData: Data?,
        title: String,
        note: String,
        createdAt: Date,
        updatedAt: Date,
        masteryLevel: Int,
        nextReviewDate: Date,
        reviewCount: Int,
        subjectRaw: String,
        gradeRaw: String,
        knowledgePointsRaw: String,
        difficultyRaw: Int,
        errorTypeRaw: String,
        sourceRaw: String,
        reviewItemTypeRaw: String,
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

    // MARK: - Internal Helpers

    /// 标记为已更新
    func markAsUpdated() {
        updatedAt = Date()
    }
    
    /// 规范化标题
    static func normalizeTitle(_ rawTitle: String) -> String {
        let trimmed = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? String(localized: "untitled_review_item") : trimmed
    }

    // MARK: - Hashable

    static func == (lhs: ReviewItem, rhs: ReviewItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
