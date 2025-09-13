import Foundation
import SwiftData

// MARK: - 核心实体

/// 复习项 - 系统的核心实体
@Model
final class ReviewItem: @unchecked Sendable, Equatable {
    @Attribute(.unique) var id: UUID
    var content: ReviewContent
    var metadata: ReviewItemMetadata
    var studyHistory: [StudyRecord]
    var masteryLevel: MasteryLevel
    var createdAt: Date
    var updatedAt: Date
    
    init(content: ReviewContent, metadata: ReviewItemMetadata) {
        self.id = UUID()
        self.content = content
        self.metadata = metadata
        self.studyHistory = []
        self.masteryLevel = .notLearned
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    static func == (lhs: ReviewItem, rhs: ReviewItem) -> Bool {
        return lhs.id == rhs.id
    }
}

/// 复习内容
@Model
final class ReviewContent: @unchecked Sendable {
    var imageData: Data?
    var recognizedText: String
    var userNotes: String
    var subject: String
    var tags: [String]
    var difficulty: DifficultyLevel
    
    init(
        imageData: Data? = nil,
        recognizedText: String = "",
        userNotes: String = "",
        subject: String = "",
        tags: [String] = [],
        difficulty: DifficultyLevel = .medium
    ) {
        self.imageData = imageData
        self.recognizedText = recognizedText
        self.userNotes = userNotes
        self.subject = subject
        self.tags = tags
        self.difficulty = difficulty
    }
}

/// 复习项元数据
@Model
final class ReviewItemMetadata: @unchecked Sendable {
    var ownerId: UUID
    var parentShareStatus: ParentShareStatus
    var parentAccessRevokedAt: Date?
    var sharedWithClassIds: [UUID]
    var isArchived: Bool
    
    init(
        ownerId: UUID,
        parentShareStatus: ParentShareStatus = .none,
        parentAccessRevokedAt: Date? = nil,
        sharedWithClassIds: [UUID] = [],
        isArchived: Bool = false
    ) {
        self.ownerId = ownerId
        self.parentShareStatus = parentShareStatus
        self.parentAccessRevokedAt = parentAccessRevokedAt
        self.sharedWithClassIds = sharedWithClassIds
        self.isArchived = isArchived
    }
}

/// 学习记录
@Model
final class StudyRecord: @unchecked Sendable {
    var id: UUID
    var studyDate: Date
    var studyType: StudyType
    var duration: TimeInterval
    var result: StudyResult
    var notes: String
    
    init(
        studyType: StudyType,
        duration: TimeInterval,
        result: StudyResult,
        notes: String = ""
    ) {
        self.id = UUID()
        self.studyDate = Date()
        self.studyType = studyType
        self.duration = duration
        self.result = result
        self.notes = notes
    }
}

// MARK: - 枚举定义

/// 掌握度等级
enum MasteryLevel: String, CaseIterable, Codable {
    case notLearned = "not_learned"
    case unclear = "unclear"
    case learned = "learned"
    
    var displayName: String {
        switch self {
        case .notLearned:
            return "未掌握"
        case .unclear:
            return "模糊"
        case .learned:
            return "已掌握"
        }
    }
    
    var color: String {
        switch self {
        case .notLearned:
            return "red"
        case .unclear:
            return "orange"
        case .learned:
            return "green"
        }
    }
}

/// 难度等级
enum DifficultyLevel: String, CaseIterable, Codable {
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

/// 家长分享状态
enum ParentShareStatus: String, CaseIterable, Codable {
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
            return "项目级"
        }
    }
}

/// 学习类型
enum StudyType: String, CaseIterable, Codable {
    case review = "review"
    case redo = "redo"
    case practice = "practice"
    
    var displayName: String {
        switch self {
        case .review:
            return "复习"
        case .redo:
            return "重做"
        case .practice:
            return "练习"
        }
    }
}

/// 学习结果
enum StudyResult: String, CaseIterable, Codable {
    case correct = "correct"
    case incorrect = "incorrect"
    case partial = "partial"
    case skipped = "skipped"
    
    var displayName: String {
        switch self {
        case .correct:
            return "正确"
        case .incorrect:
            return "错误"
        case .partial:
            return "部分正确"
        case .skipped:
            return "跳过"
        }
    }
}
