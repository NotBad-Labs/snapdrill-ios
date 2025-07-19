//
//  QuestionManagementUseCase.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainValueObjectsIdentityQuestionID // 包含 QuestionID
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesContentDifficulty // 包含 Difficulty
// import NotBadCoreDomainEntitiesContentTag // 包含 Tag
// import NotBadCoreDomainEntitiesQuestion // 包含 Question (聚合根)
// import NotBadCoreDomainEntitiesLearningAnswerResult // 包含 AnswerResult
// import NotBadCoreDomainErrorsQuestionDomainError // 包含 QuestionDomainError
// import NotBadCoreApplicationErrorsApplicationError // 包含 ApplicationError

/// 用户ID强类型 (简化版)
struct UserID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
    init() { self.rawValue = UUID().uuidString }
}

/// 题目ID强类型 (简化版)
struct QuestionID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: UUID
    init() { self.rawValue = UUID() }
    init(rawValue: UUID) { self.rawValue = rawValue }
}

/// 学科枚举 (简化版)
enum Subject: String, CaseIterable, Codable, Sendable, Hashable {
    case mathematics = "数学"
    case physics = "物理"
    case chemistry = "化学"
    case biology = "生物"
    case english = "英语"
    case chinese = "语文"
    case history = "历史"
    case geography = "地理"
    case politics = "政治"
    case computerScience = "计算机科学"
    case general = "综合"
    var displayName: String { rawValue }
    static func findCoreSubject(byName name: String) -> Subject? { return nil }
}

/// 难度级别枚举 (简化版)
enum Difficulty: String, CaseIterable, Codable, Comparable, Sendable, Hashable {
    case easy, medium, hard
    var displayName: String { rawValue }
    var coefficient: Double { 1.0 }
    func isHard() -> Bool { return false }
    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool { return true }
}

/// 标签值对象 (简化版)
struct Tag: Codable, Hashable, Sendable {
    let value: String
    let type: TagType
    enum TagType: String, Codable, Sendable { case topic }
    init(_ value: String, type: TagType = .topic) throws { self.value = value; self.type = type }
    func conflicts(with other: Tag) -> Bool { return false }
    func isCompatibleWith(subject: Subject) -> Bool { return true }
}

/// 题目附件值对象 (简化版)
struct QuestionAttachment: Codable, Sendable, Hashable {
    let id: UUID
    let type: AttachmentType
    let url: URL
    let description: String?
    enum AttachmentType: String, Codable, Sendable { case image, audio, video, document }
    init(id: UUID = UUID(), type: AttachmentType, url: URL, description: String? = nil) { self.id = id; self.type = type; self.url = url; self.description = description }
}

/// 题目内容值对象 (简化版)
struct QuestionContent: Codable, Sendable, Hashable {
    let text: String
    let attachments: [QuestionAttachment]
    init(text: String, attachments: [QuestionAttachment] = []) throws { self.text = text; self.attachments = attachments }
    var isEmpty: Bool { text.isEmpty }
}

/// 单个答案值对象 (简化版)
struct Answer: Codable, Sendable, Hashable {
    let text: String
    let isCorrect: Bool
    let explanation: String?
    init(text: String, isCorrect: Bool, explanation: String? = nil) throws { self.text = text; self.isCorrect = isCorrect; self.explanation = explanation }
}

/// 答案集合值对象 (简化版)
struct AnswerCollection: Codable, Sendable, Hashable {
    private let answers: [Answer]
    init(correctAnswers: [String]) throws { self.answers = [] }
    init(options: [(text: String, isCorrect: Bool)]) throws { self.answers = [] }
    var hasCorrectAnswers: Bool { return true }
    func check(_ userAnswer: String) -> AnswerResult { return AnswerResult(userAnswer: "", isCorrect: true, correctAnswers: []) }
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
    func withDifficulty(_ newDifficulty: Difficulty) -> QuestionMetadata { return self }
    func addTag(_ tag: Tag) throws -> QuestionMetadata { return self }
    func removeTag(_ tag: Tag) -> QuestionMetadata { return self }
    func hasTag(_ tag: Tag) -> Bool { return false }
}

/// 掌握程度枚举 (简化版)
enum MasteryLevel: String, CaseIterable, Codable, Sendable, Hashable {
    case unknown, struggling, learning, improving, mastered
    var displayName: String { rawValue }
    var progressValue: Double { 0.0 }
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
    func recordAttempt(isCorrect: Bool, difficulty: Difficulty, timestamp: Date, responseTime: TimeInterval = 0) -> LearningState { return self }
    func markReviewed(at date: Date) throws -> LearningState { return self }
    func updateWrongReason(_ reason: String?) -> LearningState { return self }
    func validateCanAnswer() throws { }
}

/// 题目聚合根 (简化版)
struct Question: Identifiable, Hashable, Codable, Sendable {
    let id: QuestionID
    private let content: QuestionContent
    private let answers: AnswerCollection
    private let metadata: QuestionMetadata
    private let learningState: LearningState
    init(id: QuestionID = QuestionID(), content: QuestionContent, answers: AnswerCollection, metadata: QuestionMetadata = QuestionMetadata()) throws {
        self.id = id; self.content = content; self.answers = answers; self.metadata = metadata; self.learningState = LearningState()
    }
    private init(id: QuestionID, content: QuestionContent, answers: AnswerCollection, metadata: QuestionMetadata, learningState: LearningState) {
        self.id = id; self.content = content; self.answers = answers; self.metadata = metadata; self.learningState = learningState
    }
    static func createSimpleQuestion(content: String, correctAnswer: String, subject: Subject = .mathematics, difficulty: Difficulty = .medium) throws -> Question {
        return try Question(content: try QuestionContent(text: content), answers: try AnswerCollection(correctAnswers: [correctAnswer]), metadata: QuestionMetadata(subject: subject, difficulty: difficulty))
    }
    static func createMultipleChoiceQuestion(content: String, options: [(text: String, isCorrect: Bool)], subject: Subject = .mathematics, difficulty: Difficulty = .medium) throws -> Question {
        return try Question(content: try QuestionContent(text: content), answers: try AnswerCollection(options: options), metadata: QuestionMetadata(subject: subject, difficulty: difficulty))
    }
    static func reconstruct(id: QuestionID, content: QuestionContent, answers: AnswerCollection, metadata: QuestionMetadata, learningState: LearningState) -> Question {
        return Question(id: id, content: content, answers: answers, metadata: metadata, learningState: learningState)
    }
    func answerQuestion(_ userAnswer: String, responseTime: TimeInterval = 0) throws -> (result: AnswerResult, updatedQuestion: Question) {
        return (AnswerResult(userAnswer: userAnswer, isCorrect: true, correctAnswers: []), self)
    }
    func markAsReviewed() throws -> Question { return self }
    func updateDifficulty(_ newDifficulty: Difficulty) throws -> Question { return self }
    func addTag(_ tag: Tag) throws -> Question { return self }
    func removeTag(_ tag: Tag) -> Question { return self }
    func updateWrongReason(_ reason: String?) -> Question { return self }
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
    var needsReview: Bool { return false }
    var nextReviewDate: Date { return Date() }
    var reviewPriority: ReviewPriority { .low }
    func hasTag(_ tag: Tag) -> Bool { return false }
    func belongsTo(_ subject: Subject) -> Bool { return false }
    func getStudySuggestion() -> StudySuggestion { return StudySuggestion(message: "", actionItems: [], estimatedTime: 0, difficulty: .easy, priority: .low) }
    func getStatisticsSummary() -> QuestionStatistics { return QuestionStatistics(questionId: id, totalAttempts: 0, correctAttempts: 0, accuracy: 0, masteryLevel: .unknown, reviewCount: 0, lastReviewedAt: nil, averageResponseTime: 0, createdAt: Date()) }
    func assessLearningProgress() -> LearningProgressAssessment { return LearningProgressAssessment(currentLevel: .unknown, progressPercentage: 0, strengthAreas: [], improvementAreas: [], recommendations: []) }
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
    enum StudyPriority: String, Codable, Sendable { case low, medium, high }
    init(message: String, actionItems: [String], estimatedTime: TimeInterval, difficulty: Difficulty, priority: StudyPriority) {
        self.message = message; self.actionItems = actionItems; self.estimatedTime = estimatedTime; self.difficulty = difficulty; self.priority = priority
    }
    static func generate(for question: Question, basedOn learningState: LearningState, difficulty: Difficulty) -> StudySuggestion {
        return StudySuggestion(message: "", actionItems: [], estimatedTime: 0, difficulty: difficulty, priority: .low)
    }
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

/// 题目领域错误 (简化版)
enum QuestionDomainError: Error, CustomStringConvertible, LocalizedError {
    case emptyContent
    case contentTooLong
    case noAnswers
    case noCorrectAnswers
    case noAnswerOptions
    case emptyAnswer
    case emptyTag
    case conflictingTags(Tag, Tag)
    case cannotReduceDifficultyForMasteredQuestion
    case cannotReviewUnatttemptedQuestion
    case tooManyAttemptsForMasteredQuestion
    case inconsistentSubjectAndTags(subject: Subject, tag: Tag)
    case invalidStateForOperation(String)

    var description: String {
        switch self {
        case .emptyContent:
            return "题目内容不能为空。"
        case .contentTooLong:
            return "题目内容过长，请精简。"
        case .noAnswers:
            return "题目必须有答案。"
        case .noCorrectAnswers:
            return "题目必须有正确答案。"
        case .noAnswerOptions:
            return "多选题必须提供选项。"
        case .emptyAnswer:
            return "答案内容不能为空。"
        case .emptyTag:
            return "标签内容不能为空。"
        case .conflictingTags(let tag1, let tag2):
            return "标签冲突: '\(tag1.value)' 与 '\(tag2.value)'。"
        case .cannotReduceDifficultyForMasteredQuestion:
            return "已掌握的题目不能随意降低难度。"
        case .cannotReviewUnatttemptedQuestion:
            return "未曾尝试过的题目不能标记为已复习。"
        case .tooManyAttemptsForMasteredQuestion:
            return "已掌握的题目今天尝试次数过多，请明天再练。"
        case .inconsistentSubjectAndTags(let subject, let tag):
            return "学科 '\(subject.displayName)' 与标签 '\(tag.value)' 不一致。"
        case .invalidStateForOperation(let operation):
            return "当前题目状态不允许执行操作: '\(operation)'。"
        }
    }
    var errorDescription: String? { return description }
}

/// 应用层错误 (简化版)
enum ApplicationError: Error, CustomStringConvertible, LocalizedError, Hashable, Sendable {
    case notAuthenticated
    var description: String { "用户未认证或会话已过期。" }
    var errorDescription: String? { return description }
}


/// 题目管理用例接口
/// 定义了与题目创建、编辑、删除、查询和导入/导出相关的所有应用层功能。
/// 表现层将通过此接口与应用层进行交互，而无需了解底层命令和查询的实现细节。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol QuestionManagementUseCase: Sendable {

    /// 添加一道新的简单题目（文本内容 + 单个正确答案）。
    /// - Parameters:
    ///   - content: 题目文本内容。
    ///   - correctAnswer: 正确答案文本。
    ///   - subject: 所属学科。
    ///   - difficulty: 难度级别。
    ///   - tags: 标签集合，可选。
    ///   - source: 题目来源，可选。
    ///   - explanation: 题目级别的总解释，可选。
    /// - Returns: 新创建题目的 ID。
    /// - Throws: `QuestionDomainError` 如果题目数据无效，`ApplicationError.notAuthenticated`
    ///           或任何其他相关错误。
    func addSimpleQuestion(
        content: String,
        correctAnswer: String,
        subject: Subject,
        difficulty: Difficulty,
        tags: Set<Tag>?,
        source: String?,
        explanation: String?
    ) async throws -> QuestionID

    /// 添加一道新的多选题。
    /// - Parameters:
    ///   - content: 题目文本内容。
    ///   - options: 选项列表（文本, 是否正确, 解释）。
    ///   - subject: 所属学科。
    ///   - difficulty: 难度级别。
    ///   - tags: 标签集合，可选。
    ///   - source: 题目来源，可选。
    ///   - explanation: 题目级别的总解释，可选。
    /// - Returns: 新创建题目的 ID。
    /// - Throws: `QuestionDomainError` 如果题目数据无效，`ApplicationError.notAuthenticated`
    ///           或任何其他相关错误。
    func addMultipleChoiceQuestion(
        content: String,
        options: [(text: String, isCorrect: Bool, explanation: String?)],
        subject: Subject,
        difficulty: Difficulty,
        tags: Set<Tag>?,
        source: String?,
        explanation: String?
    ) async throws -> QuestionID

    /// 更新题目的文本内容和附件。
    /// - Parameters:
    ///   - questionId: 要更新的题目 ID。
    ///   - newContentText: 新的题目文本内容。
    ///   - newAttachments: 新的附件列表。
    /// - Throws: `QuestionDomainError.invalidStateForOperation` 如果题目未找到，
    ///           `QuestionDomainError.emptyContent` 或其他相关错误。
    func updateQuestionContent(
        questionId: QuestionID,
        newContentText: String,
        newAttachments: [QuestionAttachment]
    ) async throws

    /// 更新题目的元数据（学科、难度、标签、来源、总解释）。
    /// - Parameters:
    ///   - questionId: 要更新的题目 ID。
    ///   - newSubject: 新的学科，可选。
    ///   - newDifficulty: 新的难度，可选。
    ///   - newTags: 新的标签集合，可选（nil 表示不修改，空集合表示清空）。
    ///   - newSource: 新的来源，可选。
    ///   - newExplanation: 新的题目总解释，可选。
    /// - Throws: `QuestionDomainError.invalidStateForOperation` 如果题目未找到，
    ///           `QuestionDomainError.conflictingTags` 或其他相关错误。
    func updateQuestionMetadata(
        questionId: QuestionID,
        newSubject: Subject?,
        newDifficulty: Difficulty?,
        newTags: Set<Tag>?,
        newSource: String?,
        newExplanation: String?
    ) async throws

    /// 删除一个题目。
    /// - Parameter questionId: 要删除的题目 ID。
    /// - Throws: `QuestionDomainError.invalidStateForOperation` 如果题目未找到，
    ///           `ApplicationError.unauthorizedAccess` 或其他相关错误。
    func deleteQuestion(questionId: QuestionID) async throws

    /// 获取单个题目详情。
    /// - Parameter questionId: 要获取的题目 ID。
    /// - Returns: `Question` 聚合根实例，如果不存在则为 `nil`。
    /// - Throws: 任何查询过程中可能发生的错误。
    func getQuestion(by questionId: QuestionID) async throws -> Question?

    /// 获取所有题目列表。
    /// - Returns: `Question` 聚合根数组。
    /// - Throws: 任何查询过程中可能发生的错误。
    func getAllQuestions() async throws -> [Question]

    /// 根据学科获取题目列表。
    /// - Parameter subject: 要查询的学科。
    /// - Returns: 属于指定学科的 `Question` 聚合根数组。
    /// - Throws: 任何查询过程中可能发生的错误。
    func getQuestions(by subject: Subject) async throws -> [Question]

    /// 根据难度获取题目列表。
    /// - Parameter difficulty: 要查询的难度。
    /// - Returns: 属于指定难度的 `Question` 聚合根数组。
    /// - Throws: 任何查询过程中可能发生的错误。
    func getQuestions(by difficulty: Difficulty) async throws -> [Question]

    /// 根据掌握程度获取题目列表。
    /// - Parameter masteryLevel: 要查询的掌握程度。
    /// - Returns: 属于指定掌握程度的 `Question` 聚合根数组。
    /// - Throws: 任何查询过程中可能发生的错误。
    func getQuestions(by masteryLevel: MasteryLevel) async throws -> [Question]

    /// 搜索题目。
    /// - Parameters:
    ///   - searchTerm: 搜索关键词。
    ///   - subject: 可选的学科过滤。
    ///   - difficulty: 可选的难度过滤。
    ///   - tags: 可选的标签过滤。
    /// - Returns: 匹配的题目聚合根数组。
    /// - Throws: 任何查询过程中可能发生的错误。
    func searchQuestions(
        searchTerm: String,
        subject: Subject?,
        difficulty: Difficulty?,
        tags: Set<Tag>?
    ) async throws -> [Question]

    /// 获取某个题目的统计信息。
    /// - Parameter questionId: 题目的 ID。
    /// - Returns: `QuestionStatistics` 值对象。
    /// - Throws: `QuestionDomainError.invalidStateForOperation` 如果题目未找到，
    ///           或其他相关错误。
    func getQuestionStatistics(for questionId: QuestionID) async throws -> QuestionStatistics

    /// 扫描图片中的题目并进行 OCR 识别。
    /// - Parameters:
    ///   - imageURL: 图片的本地文件 URL。
    ///   - userId: 执行操作的用户 ID (用于权限或个性化)。
    /// - Returns: 识别出的题目内容字符串。
    /// - Throws: `InfrastructureError.ocrFailed` 或其他相关错误。
    func scanQuestionFromImage(imageURL: URL, userId: UserID) async throws -> String

    /// 导入题目文件（例如，从 CSV、JSON 或其他格式）。
    /// - Parameters:
    ///   - fileURL: 导入文件的本地文件 URL。
    ///   - fileType: 文件的类型（例如 "csv", "json"）。
    ///   - userId: 执行操作的用户 ID (用于权限或个性化)。
    /// - Returns: 成功导入的题目数量。
    /// - Throws: `InfrastructureError.fileParsingFailed`, `QuestionDomainError`
    ///           或其他相关错误。
    func importQuestionsFromFile(fileURL: URL, fileType: String, userId: UserID) async throws -> Int

    /// 导出题目到文件。
    /// - Parameters:
    ///   - questionIds: 要导出的题目 ID 列表。
    ///   - fileType: 导出文件的类型（例如 "csv", "json"）。
    ///   - userId: 执行操作的用户 ID (用于权限或个性化)。
    /// - Returns: 导出文件的本地文件 URL。
    /// - Throws: `InfrastructureError.fileWritingFailed`, `QuestionDomainError`
    ///           或其他相关错误。
    func exportQuestionsToFile(questionIds: [QuestionID], fileType: String, userId: UserID) async throws -> URL
}

