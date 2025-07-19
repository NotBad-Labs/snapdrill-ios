//
//  QuestionAggregateRepository.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesQuestionQuestion // 包含 Question (聚合根)
// import NotBadCoreDomainValueObjectsIdentityQuestionID // 包含 QuestionID
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesLearningMasteryLevel // 包含 MasteryLevel
// import NotBadCoreDomainErrorsQuestionDomainError // 包含 QuestionDomainError
// import NotBadCoreDomainRepositoriesBaseRepository // 包含 Repository 基础协议

/// 领域错误基础协议 (简化版，实际应从 Core/Domain/Errors/DomainError.swift 导入)
protocol DomainError: Error, CustomStringConvertible, LocalizedError { }

/// 题目ID强类型 (简化版，实际应从 Core/Domain/ValueObjects/Identity/QuestionID.swift 导入)
struct QuestionID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: UUID
    init() { self.rawValue = UUID() }
    init(rawValue: UUID) { self.rawValue = rawValue }
}

/// 学科枚举 (简化版，实际应从 Core/Domain/Entities/Content/Subject.swift 导入)
enum Subject: String, CaseIterable, Codable, Sendable, Hashable {
    case mathematics = "数学"
    case physics = "物理"
    case general = "综合"
    var displayName: String { rawValue }
    static func findCoreSubject(byName name: String) -> Subject? { return nil }
}

/// 掌握程度枚举 (简化版，实际应从 Core/Domain/Entities/Learning/MasteryLevel.swift 导入)
enum MasteryLevel: String, CaseIterable, Codable, Sendable, Hashable {
    case unknown = "未知"
    case struggling = "困难"
    case learning = "学习中"
    case improving = "进步中"
    case mastered = "已掌握"
    var displayName: String { rawValue }
    var progressValue: Double { return 0.0 } // Simplified
}

/// 题目领域错误 (简化版，实际应从 Core/Domain/Errors/QuestionDomainError.swift 导入)
enum QuestionDomainError: DomainError {
    case questionNotFound
    case genericQuestionError(String)
    case cannotReviewUnatttemptedQuestion // For LearningState
    case tooManyAttemptsForMasteredQuestion // For LearningState
    case cannotReduceDifficultyForMasteredQuestion // For Question
    case inconsistentSubjectAndTags(subject: Subject, tag: Tag) // For Question
    case invalidStateForOperation(String) // For Question

    var description: String {
        switch self {
        case .questionNotFound: return "题目未找到。"
        case .genericQuestionError(let message): return "题目相关错误: \(message)。"
        case .cannotReviewUnatttemptedQuestion: return "未曾尝试过的题目不能标记为已复习。"
        case .tooManyAttemptsForMasteredQuestion: return "已掌握的题目今天尝试次数过多，请明天再练。"
        case .cannotReduceDifficultyForMasteredQuestion: return "已掌握的题目不能随意降低难度。"
        case .inconsistentSubjectAndTags(let subject, let tag): return "学科 '\(subject.displayName)' 与标签 '\(tag.value)' 不一致。"
        case .invalidStateForOperation(let operation): return "当前题目状态不允许执行操作: '\(operation)'。"
        }
    }
    var errorDescription: String? { return description }
}

/// 题目附件值对象 (简化版)
struct QuestionAttachment: Codable, Sendable, Hashable {
    let id: UUID
    let type: AttachmentType
    let url: URL
    let description: String?
    enum AttachmentType: String, Codable, Sendable { case image }
    init(id: UUID = UUID(), type: AttachmentType, url: URL, description: String? = nil) {
        self.id = id; self.type = type; self.url = url; self.description = description
    }
}

/// 题目内容值对象 (简化版)
struct QuestionContent: Codable, Sendable, Hashable {
    let text: String
    let attachments: [QuestionAttachment]
    init(text: String, attachments: [QuestionAttachment] = []) throws {
        self.text = text; self.attachments = attachments
    }
    var isEmpty: Bool { text.isEmpty }
}

/// 单个答案值对象 (简化版)
struct Answer: Codable, Sendable, Hashable {
    let text: String
    let isCorrect: Bool
    let explanation: String?
    init(text: String, isCorrect: Bool, explanation: String? = nil) throws {
        self.text = text; self.isCorrect = isCorrect; self.explanation = explanation
    }
    func matches(_ userInput: String) -> Bool { return false } // Simplified
}

/// 答案集合值对象 (简化版)
struct AnswerCollection: Codable, Sendable, Hashable {
    private let answers: [Answer]
    init(correctAnswers: [String]) throws { self.answers = [] } // Simplified
    init(options: [(text: String, isCorrect: Bool)]) throws { self.answers = [] } // Simplified
    var hasCorrectAnswers: Bool { return false } // Simplified
    var correctAnswers: [Answer] { return [] } // Simplified
    func check(_ userAnswer: String) -> AnswerResult { return AnswerResult(userAnswer: "", isCorrect: false, correctAnswers: []) } // Simplified
}

/// 题目元数据值对象 (简化版)
struct QuestionMetadata: Codable, Sendable, Hashable {
    let subject: Subject
    let difficulty: Difficulty
    let tags: Set<Tag>
    let source: String?
    let createdAt: Date
    let explanation: String?
    init(subject: Subject = .mathematics, difficulty: Difficulty = .medium, tags: Set<Tag> = [], source: String? = nil, createdAt: Date = Date(), explanation: String? = nil) {
        self.subject = subject; self.difficulty = difficulty; self.tags = tags; self.source = source; self.createdAt = createdAt; self.explanation = explanation
    }
    func withDifficulty(_ newDifficulty: Difficulty) -> QuestionMetadata { return self } // Simplified
    func addTag(_ tag: Tag) throws -> QuestionMetadata { return self } // Simplified
    func removeTag(_ tag: Tag) -> QuestionMetadata { return self } // Simplified
    func hasTag(_ tag: Tag) -> Bool { return false } // Simplified
}

/// 学习状态值对象 (简化版)
struct LearningState: Codable, Sendable, Hashable {
    let totalAttempts: Int
    let correctAttempts: Int
    let reviewCount: Int
    let lastReviewedAt: Date?
    let lastAttemptAt: Date?
    let wrongReason: String?
    let responseTimeHistory: [TimeInterval]
    let masteryLevel: MasteryLevel
    private let dailyAttempts: [Date: Int]
    init(totalAttempts: Int = 0, correctAttempts: Int = 0, reviewCount: Int = 0, lastReviewedAt: Date? = nil, lastAttemptAt: Date? = nil, wrongReason: String? = nil, responseTimeHistory: [TimeInterval] = [], masteryLevel: MasteryLevel = .unknown, dailyAttempts: [Date: Int] = [:]) {
        self.totalAttempts = totalAttempts; self.correctAttempts = correctAttempts; self.reviewCount = reviewCount; self.lastReviewedAt = lastReviewedAt; self.lastAttemptAt = lastAttemptAt; self.wrongReason = wrongReason; self.responseTimeHistory = responseTimeHistory; self.masteryLevel = masteryLevel; self.dailyAttempts = dailyAttempts
    }
    func recordAttempt(isCorrect: Bool, difficulty: Difficulty, timestamp: Date, responseTime: TimeInterval = 0) -> LearningState { return self } // Simplified
    func markReviewed(at date: Date) throws -> LearningState { return self } // Simplified
    func updateWrongReason(_ reason: String?) -> LearningState { return self } // Simplified
    func validateCanAnswer() throws { } // Simplified
    func needsReview(basedOn difficulty: Difficulty, at currentDate: Date) -> Bool { return false } // Simplified
    func calculateNextReviewDate(difficulty: Difficulty) -> Date { return Date() } // Simplified
    func calculateReviewPriority(difficulty: Difficulty, createdAt: Date) -> ReviewPriority { return .low } // Simplified
    func calculateProgressPercentage() -> Double { return 0.0 } // Simplified
    func identifyStrengths() -> [String] { return [] } // Simplified
    func identifyWeaknesses() -> [String] { return [] } // Simplified
}

/// 答题结果值对象 (简化版)
struct AnswerResult: Codable, Sendable, Hashable {
    let userAnswer: String
    let isCorrect: Bool
    let correctAnswers: [String]
    let explanation: String?
    let timestamp: Date
    init(userAnswer: String, isCorrect: Bool, correctAnswers: [String], explanation: String? = nil) {
        self.userAnswer = userAnswer; self.isCorrect = isCorrect; self.correctAnswers = correctAnswers; self.explanation = explanation; self.timestamp = Date()
    }
}

/// 学习建议值对象 (简化版)
struct StudySuggestion: Codable, Sendable, Hashable {
    let message: String
    let actionItems: [String]
    let estimatedTime: TimeInterval
    let difficulty: Difficulty
    let priority: StudyPriority
    enum StudyPriority: String, Codable, Sendable { case low }
    init(message: String, actionItems: [String], estimatedTime: TimeInterval, difficulty: Difficulty, priority: StudyPriority) {
        self.message = message; self.actionItems = actionItems; self.estimatedTime = estimatedTime; self.difficulty = difficulty; self.priority = priority
    }
    static func generate(for question: Question, basedOn learningState: LearningState, difficulty: Difficulty) -> StudySuggestion { return StudySuggestion(message: "", actionItems: [], estimatedTime: 0, difficulty: difficulty, priority: .low) } // Simplified
}

/// 题目统计信息值对象 (简化版)
struct QuestionStatistics: Codable, Sendable, Hashable {
    let questionId: QuestionID
    let totalAttempts: Int
    let correctAttempts: Int
    let accuracy: Double
    let masteryLevel: MasteryLevel
    let reviewCount: Int
    let lastReviewedAt: Date?
    let averageResponseTime: TimeInterval
    let createdAt: Date
    init(questionId: QuestionID, totalAttempts: Int, correctAttempts: Int, accuracy: Double, masteryLevel: MasteryLevel, reviewCount: Int, lastReviewedAt: Date?, averageResponseTime: TimeInterval, createdAt: Date) {
        self.questionId = questionId; self.totalAttempts = totalAttempts; self.correctAttempts = correctAttempts; self.accuracy = accuracy; self.masteryLevel = masteryLevel; self.reviewCount = reviewCount; self.lastReviewedAt = lastReviewedAt; self.averageResponseTime = averageResponseTime; self.createdAt = createdAt
    }
}

/// 学习进度评估结果值对象 (简化版)
struct LearningProgressAssessment: Codable, Sendable, Hashable {
    let currentLevel: MasteryLevel
    let progressPercentage: Double
    let strengthAreas: [String]
    let improvementAreas: [String]
    let recommendations: [String]
    init(currentLevel: MasteryLevel, progressPercentage: Double, strengthAreas: [String], improvementAreas: [String], recommendations: [String]) {
        self.currentLevel = currentLevel; self.progressPercentage = progressPercentage; self.strengthAreas = strengthAreas; self.improvementAreas = improvementAreas; self.recommendations = recommendations
    }
}

/// 难度级别枚举 (简化版)
enum Difficulty: String, CaseIterable, Codable, Comparable, Sendable, Hashable {
    case easy = "简单"
    case medium = "中等"
    case hard = "困难"
    var displayName: String { rawValue }
    var coefficient: Double { return 1.0 } // Simplified
    func isHard() -> Bool { return false } // Simplified
    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool { return true } // Simplified
}

/// 标签值对象 (简化版)
struct Tag: Codable, Hashable, Sendable {
    let value: String
    let type: TagType
    enum TagType: String, Codable, Sendable { case subject }
    init(_ value: String, type: TagType = .subject) throws { self.value = value; self.type = type }
    func conflicts(with other: Tag) -> Bool { return false } // Simplified
    func isCompatibleWith(subject: Subject) -> Bool { return true } // Simplified
}

/// 复习优先级枚举 (简化版)
enum ReviewPriority: Int, Comparable, Codable, Sendable {
    case low = 1
    case medium = 2
    case high = 3
    static func < (lhs: ReviewPriority, rhs: ReviewPriority) -> Bool { return true } // Simplified
    var displayName: String { rawValue }
    var color: String { return "" } // Simplified
}

/// 题目聚合根 (简化版，实际应从 Core/Domain/Entities/Question/Question.swift 导入)
struct Question: Equatable, Hashable, Identifiable, Codable, Sendable {
    let id: QuestionID
    private let content: QuestionContent
    private let answers: AnswerCollection
    private let metadata: QuestionMetadata
    private let learningState: LearningState

    init(id: QuestionID = QuestionID(), content: QuestionContent, answers: AnswerCollection, metadata: QuestionMetadata = QuestionMetadata()) throws {
        self.id = id; self.content = content; self.answers = answers; self.metadata = metadata; self.learningState = LearningState()
    }

    static func reconstruct(id: QuestionID, content: QuestionContent, answers: AnswerCollection, metadata: QuestionMetadata, learningState: LearningState) -> Question {
        return Question(id: id, content: content, answers: answers, metadata: metadata, learningState: learningState)
    }

    // Simplified properties for compilation
    var displayContent: String { content.text }
    var difficulty: Difficulty { metadata.difficulty }
    var subject: Subject { metadata.subject }
    var tags: Set<Tag> { metadata.tags }
    var masteryLevel: MasteryLevel { learningState.masteryLevel }
    var accuracy: Double { learningState.accuracy }
    var totalAttempts: Int { learningState.totalAttempts }
    var correctAttempts: Int { learningState.correctAttempts }
    var isNew: Bool { learningState.totalAttempts == 0 }
    var isMastered: Bool { learningState.masteryLevel == .mastered }
    var needsReview: Bool { return false } // Simplified
    var nextReviewDate: Date { return Date() } // Simplified
    var reviewPriority: ReviewPriority { return .low } // Simplified

    func answerQuestion(_ userAnswer: String, responseTime: TimeInterval = 0) throws -> (result: AnswerResult, updatedQuestion: Question) {
        return (AnswerResult(userAnswer: "", isCorrect: false, correctAnswers: []), self) // Simplified
    }
    func markAsReviewed() throws -> Question { return self } // Simplified
    func updateDifficulty(_ newDifficulty: Difficulty) throws -> Question { return self } // Simplified
    func addTag(_ tag: Tag) throws -> Question { return self } // Simplified
    func removeTag(_ tag: Tag) -> Question { return self } // Simplified
    func updateWrongReason(_ reason: String?) -> Question { return self } // Simplified
    func hasTag(_ tag: Tag) -> Bool { return false } // Simplified
    func belongsTo(_ subject: Subject) -> Bool { return false } // Simplified
    func getStudySuggestion() -> StudySuggestion { return .generate(for: self, basedOn: learningState, difficulty: difficulty) } // Simplified
    func getStatisticsSummary() -> QuestionStatistics { return QuestionStatistics(questionId: id, totalAttempts: 0, correctAttempts: 0, accuracy: 0, masteryLevel: .unknown, reviewCount: 0, lastReviewedAt: nil, averageResponseTime: 0, createdAt: Date()) } // Simplified
    func assessLearningProgress() -> LearningProgressAssessment { return LearningProgressAssessment(currentLevel: .unknown, progressPercentage: 0, strengthAreas: [], improvementAreas: [], recommendations: []) } // Simplified
}


/// 题目聚合仓储接口
/// 定义了对 `Question` 聚合根进行持久化和检索的契约。
/// 仓储操作的单位是整个聚合，确保聚合的事务边界和数据一致性。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol QuestionAggregateRepository: Sendable {

    /// 保存或更新一个 `Question` 聚合根。
    /// 如果 `Question` 已存在（通过其 ID 判断），则更新；否则，添加。
    /// - Parameter question: 要保存或更新的 `Question` 聚合根实例。
    /// - Throws: `QuestionDomainError` 或其他持久化相关的错误。
    func save(_ question: Question) async throws

    /// 根据 ID 查找一个 `Question` 聚合根。
    /// - Parameter id: 要查找的 `Question` 的唯一标识符。
    /// - Returns: 找到的 `Question` 聚合根实例，如果不存在则为 `nil`。
    /// - Throws: `QuestionDomainError` 或其他持久化相关的错误。
    func find(by id: QuestionID) async throws -> Question?

    /// 删除一个 `Question` 聚合根。
    /// - Parameter question: 要删除的 `Question` 聚合根实例。
    /// - Throws: `QuestionDomainError` 或其他持久化相关的错误。
    func delete(_ question: Question) async throws

    /// 获取所有 `Question` 聚合根。
    /// - Returns: 包含所有 `Question` 聚合根的数组。
    /// - Throws: `QuestionDomainError` 或其他持久化相关的错误。
    func findAll() async throws -> [Question]

    /// 根据学科查找 `Question` 聚合根列表。
    /// - Parameter subject: 要查找的学科。
    /// - Returns: 属于指定学科的 `Question` 聚合根数组。
    /// - Throws: `QuestionDomainError` 或其他持久化相关的错误。
    func find(by subject: Subject) async throws -> [Question]

    /// 根据掌握程度查找 `Question` 聚合根列表。
    /// - Parameter masteryLevel: 要查找的掌握程度。
    /// - Returns: 具有指定掌握程度的 `Question` 聚合根数组。
    /// - Throws: `QuestionDomainError` 或其他持久化相关的错误。
    func find(by masteryLevel: MasteryLevel) async throws -> [Question]

    /// 查找需要复习的 `Question` 聚合根列表。
    /// - Returns: 需要复习的 `Question` 聚合根数组。
    /// - Throws: `QuestionDomainError` 或其他持久化相关的错误。
    func findQuestionsNeedingReview() async throws -> [Question]

    // 您可以根据业务需求添加更多查询方法，例如：
    // func search(query: String, options: QuestionSearchOptions) async throws -> [Question]
    // func countAll() async throws -> Int
}

