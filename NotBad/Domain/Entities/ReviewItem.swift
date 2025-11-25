import Foundation
import SwiftData

/// 复习项 (Review Item)
/// 代表一个具体的错题或需要复习的知识点
@Model
final class ReviewItem {
    /// 唯一标识符
    var id: UUID
    
    /// 错题图片数据
    @Attribute(.externalStorage)
    var imageData: Data?
    
    /// 标题（通常是 OCR 识别出的首行文字或用户自定义）
    var title: String
    
    /// 用户备注/笔记
    var note: String
    
    /// 创建时间
    var createdAt: Date
    
    /// 更新时间
    var updatedAt: Date
    
    /// 掌握程度 (0: 新建, 1: 模糊, 2: 熟悉, 3: 掌握)
    var masteryLevel: Int
    
    /// 下次复习时间 (基于艾宾浩斯或其他算法计算)
    var nextReviewDate: Date
    
    /// 复习次数
    var reviewCount: Int
    
    // MARK: - 值对象存储字段
    
    /// 学科（存储 rawValue）
    var subjectRaw: String
    
    /// 年级（存储 rawValue）
    var gradeRaw: String
    
    /// 知识点标签（逗号分隔存储）
    var tagsRaw: String
    
    /// 难度等级
    var difficultyRaw: Int
    
    /// 错误类型（存储 rawValue）
    var errorTypeRaw: String
    
    /// 题目来源（存储 rawValue）
    var sourceRaw: String
    
    /// 题目类型（存储 rawValue）
    var questionTypeRaw: String
    
    // MARK: - 值对象访问器
    
    /// 学科
    var subject: Subject {
        get { Subject(rawValue: subjectRaw) ?? .other }
        set { subjectRaw = newValue.rawValue }
    }
    
    /// 年级
    var grade: Grade {
        get { Grade(rawValue: gradeRaw) ?? .grade10 }
        set { gradeRaw = newValue.rawValue }
    }
    
    /// 掌握程度
    var mastery: MasteryLevel {
        get { MasteryLevel(rawValue: masteryLevel) ?? .none }
        set { masteryLevel = newValue.rawValue }
    }
    
    /// 知识点标签
    var tags: Tags {
        get { Tags(from: tagsRaw) }
        set { tagsRaw = newValue.rawValue }
    }
    
    /// 难度等级
    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .medium }
        set { difficultyRaw = newValue.rawValue }
    }
    
    /// 错误类型
    var errorType: ErrorType {
        get { ErrorType(rawValue: errorTypeRaw) ?? .other }
        set { errorTypeRaw = newValue.rawValue }
    }
    
    /// 题目来源
    var source: Source {
        get { Source(rawValue: sourceRaw) ?? .other }
        set { sourceRaw = newValue.rawValue }
    }
    
    /// 题目类型
    var questionType: ReviewItemType {
        get { ReviewItemType(rawValue: questionTypeRaw) ?? .other }
        set { questionTypeRaw = newValue.rawValue }
    }
    
    /// 复习间隔计算
    var reviewInterval: ReviewInterval {
        ReviewInterval.calculate(reviewCount: reviewCount, mastery: mastery)
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        imageData: Data? = nil,
        title: String = "",
        note: String = "",
        createdAt: Date = Date(),
        mastery: MasteryLevel = .none,
        subject: Subject = .math,
        grade: Grade = .grade10,
        tags: Tags = .empty,
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
        self.tagsRaw = tags.rawValue
        self.difficultyRaw = difficulty.rawValue
        self.errorTypeRaw = errorType.rawValue
        self.sourceRaw = source.rawValue
        self.questionTypeRaw = questionType.rawValue
    }
}
