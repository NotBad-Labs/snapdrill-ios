//
//  ReviewItem.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//

import Foundation

// MARK: - 核心实体：复习项
/// 复习项是系统的核心实体，代表需要复习的单个学习内容单元
/// 遵循Clean Architecture的Domain层设计原则，纯Swift结构体，无外部依赖
struct ReviewItem: Identifiable, Equatable, Hashable {
    let id: UUID
    var content: ReviewContent
    var metadata: ReviewMetadata
    var studyHistory: [StudyRecord]
    var masteryLevel: MasteryLevel
    
    init(
        id: UUID = UUID(),
        content: ReviewContent,
        metadata: ReviewMetadata,
        studyHistory: [StudyRecord] = [],
        masteryLevel: MasteryLevel = .notMastered
    ) {
        self.id = id
        self.content = content
        self.metadata = metadata
        self.studyHistory = studyHistory
        self.masteryLevel = masteryLevel
    }
}

// MARK: - 复习内容
/// 复习项的具体内容，包含题目、答案、解析等
struct ReviewContent: Equatable, Hashable {
    var title: String
    var question: String
    var answer: String?
    var explanation: String?
    var imageData: Data?
    var subject: String
    var difficulty: DifficultyLevel
    var tags: [String]
    
    init(
        title: String,
        question: String,
        answer: String? = nil,
        explanation: String? = nil,
        imageData: Data? = nil,
        subject: String,
        difficulty: DifficultyLevel = .medium,
        tags: [String] = []
    ) {
        self.title = title
        self.question = question
        self.answer = answer
        self.explanation = explanation
        self.imageData = imageData
        self.subject = subject
        self.difficulty = difficulty
        self.tags = tags
    }
}

// MARK: - 复习元数据
/// 复习项的元数据，包含创建时间、更新时间、共享状态等
struct ReviewMetadata: Equatable, Hashable {
    var createdAt: Date
    var updatedAt: Date
    var ownerId: UUID
    var parentShareStatus: ParentShareStatus
    var parentAccessRevokedAt: Date?
    var sharedWithClassIds: [UUID]
    var source: ItemSource
    
    init(
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        ownerId: UUID,
        parentShareStatus: ParentShareStatus = .none,
        parentAccessRevokedAt: Date? = nil,
        sharedWithClassIds: [UUID] = [],
        source: ItemSource = .manual
    ) {
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ownerId = ownerId
        self.parentShareStatus = parentShareStatus
        self.parentAccessRevokedAt = parentAccessRevokedAt
        self.sharedWithClassIds = sharedWithClassIds
        self.source = source
    }
}

// MARK: - 学习记录
/// 记录用户对复习项的学习历史
struct StudyRecord: Identifiable, Equatable, Hashable {
    let id: UUID
    var studyDate: Date
    var isCorrect: Bool
    var timeSpent: TimeInterval
    var notes: String?
    
    init(
        id: UUID = UUID(),
        studyDate: Date = Date(),
        isCorrect: Bool,
        timeSpent: TimeInterval,
        notes: String? = nil
    ) {
        self.id = id
        self.studyDate = studyDate
        self.isCorrect = isCorrect
        self.timeSpent = timeSpent
        self.notes = notes
    }
}

// MARK: - 掌握程度
/// 用户对复习项的掌握程度状态
enum MasteryLevel: String, CaseIterable, Equatable, Hashable {
    case notMastered = "not_mastered"
    case fuzzy = "fuzzy"
    case mastered = "mastered"
    
    var displayName: String {
        switch self {
        case .notMastered:
            return "未掌握"
        case .fuzzy:
            return "模糊"
        case .mastered:
            return "已掌握"
        }
    }
    
    var color: String {
        switch self {
        case .notMastered:
            return "red"
        case .fuzzy:
            return "orange"
        case .mastered:
            return "green"
        }
    }
}

// MARK: - 难度等级
/// 复习项的难度等级
enum DifficultyLevel: String, CaseIterable, Equatable, Hashable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var displayName: String {
        switch self {
        case .easy:
            return "简单"
        case .medium:
            return "中等"
        case .hard:
            return "困难"
        }
    }
    
    var weight: Int {
        switch self {
        case .easy:
            return 1
        case .medium:
            return 2
        case .hard:
            return 3
        }
    }
}

// MARK: - 家长分享状态
/// 家长分享状态，用于控制家长对复习项的访问权限
enum ParentShareStatus: String, CaseIterable, Equatable, Hashable {
    case none = "none"
    case summary = "summary"
    case oneTime = "one_time"
    case itemLevel = "item_level"
    
    var displayName: String {
        switch self {
        case .none:
            return "不分享"
        case .summary:
            return "仅摘要"
        case .oneTime:
            return "一次性"
        case .itemLevel:
            return "详细内容"
        }
    }
}

// MARK: - 复习项来源
/// 复习项的创建来源
enum ItemSource: String, CaseIterable, Equatable, Hashable {
    case manual = "manual"
    case ocr = "ocr"
    case importFile = "import_file"
    case teacher = "teacher"
    
    var displayName: String {
        switch self {
        case .manual:
            return "手动创建"
        case .ocr:
            return "拍照识别"
        case .importFile:
            return "文件导入"
        case .teacher:
            return "老师分发"
        }
    }
}
