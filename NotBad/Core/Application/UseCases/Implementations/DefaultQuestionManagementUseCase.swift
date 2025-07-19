//
//  DefaultQuestionManagementUseCase.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助应用层和领域层类型导入 (这些类型应在各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreApplicationUseCasesQuestionManagementUseCase // 包含 QuestionManagementUseCase 协议
// import NotBadCoreApplicationCommandQueryBus // 包含 CommandQueryBus
// import NotBadCoreApplicationCommandsQuestionCommands // 包含 AddSimpleQuestionCommand 等
// import NotBadCoreApplicationQueriesQuestionQueries // 包含 GetQuestionByIdQuery, SearchQuestionsQuery 等
// import NotBadCoreDomainEntitiesQuestion // 包含 Question (聚合根)
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesContentDifficulty // 包含 Difficulty
// import NotBadCoreDomainEntitiesContentTag // 包含 Tag
// import NotBadCoreDomainValueObjectsQuestionAttachment // 包含 QuestionAttachment
// import NotBadCoreDomainEntitiesLearningQuestionStatistics // 包含 QuestionStatistics
// import NotBadCoreDomainErrorsQuestionDomainError // 包含 QuestionDomainError
// import NotBadCoreApplicationErrorsApplicationError // 包含 ApplicationError
// import NotBadCoreDomainServicesOCRService // 包含 OCRService 协议
// import NotBadInfrastructureFileSystem // 包含 FileSystemManager 协议

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
    func matches(_ userInput: String) -> Bool { return true }
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
    var accuracy: Double { 0.0 }
    var averageResponseTime: TimeInterval { 0.0 }
    func recordAttempt(isCorrect: Bool, difficulty: Difficulty, timestamp: Date, responseTime: TimeInterval = 0) -> LearningState { return self }
    func markReviewed(at date: Date) throws -> LearningState { return self }
    func updateWrongReason(_ reason: String?) -> LearningState { return self }
    func validateCanAnswer() throws { }
    func needsReview(basedOn difficulty: Difficulty, at currentDate: Date) -> Bool { return false }
    func calculateNextReviewDate(difficulty: Difficulty) -> Date { return Date() }
    func calculateReviewPriority(difficulty: Difficulty, createdAt: Date) -> ReviewPriority { return .low }
    func calculateProgressPercentage() -> Double { return 0.0 }
    func identifyStrengths() -> [String] { return [] }
    func identifyWeaknesses() -> [String] { return [] }
}

/// 题目聚合根 (简化版)
struct Question: Identifiable, Hashable, Codable, Sendable {
    let id: QuestionID
    let content: QuestionContent
    let answers: AnswerCollection
    let metadata: QuestionMetadata
    let learningState: LearningState
    init(id: QuestionID = QuestionID(), content: QuestionContent, answers: AnswerCollection, metadata: QuestionMetadata = QuestionMetadata()) throws {
        self.id = id; self.content = content; self.answers = answers; self.metadata = metadata; self.learningState = LearningState()
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
    case questionNotFound // Added for clarity in handlers
    case ocrFailed(String) // For OCR related errors
    case fileParsingFailed(String) // For file import errors
    case fileWritingFailed(String) // For file export errors

    var description: String {
        switch self {
        case .emptyContent: return "题目内容不能为空。"
        case .contentTooLong: return "题目内容过长，请精简。"
        case .noAnswers: return "题目必须有答案。"
        case .noCorrectAnswers: return "题目必须有正确答案。"
        case .noAnswerOptions: return "多选题必须提供选项。"
        case .emptyAnswer: return "答案内容不能为空。"
        case .emptyTag: return "标签内容不能为空。"
        case .conflictingTags(let tag1, let tag2): return "标签冲突: '\(tag1.value)' 与 '\(tag2.value)'。"
        case .cannotReduceDifficultyForMasteredQuestion: return "已掌握的题目不能随意降低难度。"
        case .cannotReviewUnatttemptedQuestion: return "未曾尝试过的题目不能标记为已复习。"
        case .tooManyAttemptsForMasteredQuestion: return "已掌握的题目今天尝试次数过多，请明天再练。"
        case .inconsistentSubjectAndTags(let subject, let tag): return "学科 '\(subject.displayName)' 与标签 '\(tag.value)' 不一致。"
        case .invalidStateForOperation(let operation): return "当前题目状态不允许执行操作: '\(operation)'。"
        case .questionNotFound: return "题目未找到。"
        case .ocrFailed(let reason): return "OCR识别失败: \(reason)。"
        case .fileParsingFailed(let reason): return "文件解析失败: \(reason)。"
        case .fileWritingFailed(let reason): return "文件写入失败: \(reason)。"
        }
    }
    var errorDescription: String? { return description }
}

/// 应用层错误 (简化版)
enum ApplicationError: Error, CustomStringConvertible, LocalizedError, Hashable, Sendable {
    case handlerNotFound(String)
    case invalidHandlerType(String)
    case unknownError(String)
    case notAuthenticated
    case unauthorizedAccess // Added for clarity

    var description: String {
        switch self {
        case .handlerNotFound(let name): return "未找到命令/查询处理器: \(name)。"
        case .invalidHandlerType(let name): return "处理器类型不匹配: \(name)。"
        case .unknownError(let message): return "发生未知错误: \(message)。"
        case .notAuthenticated: return "用户未认证或会话已过期。"
        case .unauthorizedAccess: return "未授权访问。"
        }
    }
    var errorDescription: String? { return description }
}

/// 命令协议 (简化版)
protocol Command: Hashable, Sendable {}

/// 查询协议 (简化版)
protocol Query: Hashable, Sendable {}

/// 命令处理器协议 (简化版)
protocol CommandHandler<C>: Sendable {
    associatedtype C: Command
    func handle(_ command: C) async throws
}

/// 查询处理器协议 (简化版)
protocol QueryHandler<Q, R>: Sendable {
    associatedtype Q: Query
    associatedtype R
    func handle(_ query: Q) async throws -> R
}

/// 命令查询总线 (简化版)
actor CommandQueryBus {
    private var commandHandlers: [String: AnyCommandHandlerWrapper] = [:]
    private var queryHandlers: [String: AnyQueryHandlerWrapper] = [:]

    @discardableResult
    func register<C: Command, H: CommandHandler>(handler: H, for commandType: C.Type) -> CommandQueryBus where H.C == C {
        let key = String(describing: commandType)
        commandHandlers[key] = AnyCommandHandlerWrapper(handler)
        return self
    }

    @discardableResult
    func register<Q: Query, R, H: QueryHandler>(handler: H, for queryType: Q.Type) -> CommandQueryBus where H.Q == Q, H.R == R {
        let key = String(describing: queryType)
        queryHandlers[key] = AnyQueryHandlerWrapper(handler)
        return self
    }

    func execute<C: Command>(_ command: C) async throws {
        let key = String(describing: type(of: command))
        guard let wrapper = commandHandlers[key] else {
            throw ApplicationError.handlerNotFound("Command handler for \(key) not found.")
        }
        guard let handler = wrapper.base as? any CommandHandler<C> else {
            throw ApplicationError.invalidHandlerType("Command handler for \(key) is of an unexpected type.")
        }
        try await handler.handle(command)
    }

    func execute<Q: Query, R>(_ query: Q) async throws -> R {
        let key = String(describing: type(of: query))
        guard let wrapper = queryHandlers[key] else {
            throw ApplicationError.handlerNotFound("Query handler for \(key) not found.")
        }
        guard let handler = wrapper.base as? any QueryHandler<Q, R> else {
            throw ApplicationError.invalidHandlerType("Query handler for \(key) is of an unexpected type or return type.")
        }
        return try await handler.handle(query)
    }

    private protocol AnyCommandHandler { var base: Any { get } }
    private struct AnyCommandHandlerWrapper: AnyCommandHandler {
        let base: Any
        init<C: Command, H: CommandHandler>(_ handler: H) where H.C == C { self.base = handler }
    }
    private protocol AnyQueryHandler { var base: Any { get } }
    private struct AnyQueryHandlerWrapper: AnyQueryHandler {
        let base: Any
        init<Q: Query, R, H: QueryHandler>(_ handler: H) where H.Q == Q, H.R == R { self.base = handler }
    }
}

// MARK: - Question 相关的命令和查询定义 (简化版)

/// 题目命令：添加简单题目
struct AddSimpleQuestionCommand: Command {
    let content: String
    let correctAnswer: String
    let subject: Subject
    let difficulty: Difficulty
    let tags: Set<Tag>?
    let source: String?
    let explanation: String?
}

/// 题目命令：添加多选题
struct AddMultipleChoiceQuestionCommand: Command {
    let content: String
    let options: [(text: String, isCorrect: Bool, explanation: String?)]
    let subject: Subject
    let difficulty: Difficulty
    let tags: Set<Tag>?
    let source: String?
    let explanation: String?
}

/// 题目命令：更新题目内容
struct UpdateQuestionContentCommand: Command {
    let questionId: QuestionID
    let newContentText: String
    let newAttachments: [QuestionAttachment]
}

/// 题目命令：更新题目元数据
struct UpdateQuestionMetadataCommand: Command {
    let questionId: QuestionID
    let newSubject: Subject?
    let newDifficulty: Difficulty?
    let newTags: Set<Tag>?
    let newSource: String?
    let newExplanation: String?
}

/// 题目命令：删除题目
struct DeleteQuestionCommand: Command {
    let questionId: QuestionID
}

/// 题目查询：获取单个题目
struct GetQuestionByIdQuery: Query {
    let questionId: QuestionID
}

/// 题目查询：获取所有题目
struct GetAllQuestionsQuery: Query {}

/// 题目查询：根据学科获取题目列表
struct GetQuestionsBySubjectQuery: Query {
    let subject: Subject
}

/// 题目查询：根据难度获取题目列表
struct GetQuestionsByDifficultyQuery: Query {
    let difficulty: Difficulty
}

/// 题目查询：根据掌握程度获取题目列表
struct GetQuestionsByMasteryLevelQuery: Query {
    let masteryLevel: MasteryLevel
}

/// 题目查询：搜索题目
struct SearchQuestionsQuery: Query {
    let searchTerm: String
    let subject: Subject?
    let difficulty: Difficulty?
    let tags: Set<Tag>?
}

/// 题目查询：获取题目统计信息
struct GetQuestionStatisticsQuery: Query {
    let questionId: QuestionID
}

/// 题目查询：扫描图片中的题目并进行OCR识别
struct ScanQuestionFromImageQuery: Query {
    let imageURL: URL
}

/// 题目命令：导入题目文件
struct ImportQuestionsFromFileCommand: Command {
    let fileURL: URL
    let fileType: String
}

/// 题目查询：导出题目到文件
struct ExportQuestionsToFileQuery: Query {
    let questionIds: [QuestionID]
    let fileType: String
}


/// 题目管理用例接口 (简化版)
protocol QuestionManagementUseCase: Sendable {
    func addSimpleQuestion(
        content: String, correctAnswer: String, subject: Subject, difficulty: Difficulty,
        tags: Set<Tag>?, source: String?, explanation: String?
    ) async throws -> QuestionID
    func addMultipleChoiceQuestion(
        content: String, options: [(text: String, isCorrect: Bool, explanation: String?)],
        subject: Subject, difficulty: Difficulty, tags: Set<Tag>?, source: String?, explanation: String?
    ) async throws -> QuestionID
    func updateQuestionContent(
        questionId: QuestionID, newContentText: String, newAttachments: [QuestionAttachment]
    ) async throws
    func updateQuestionMetadata(
        questionId: QuestionID, newSubject: Subject?, newDifficulty: Difficulty?,
        newTags: Set<Tag>?, newSource: String?, newExplanation: String?
    ) async throws
    func deleteQuestion(questionId: QuestionID) async throws
    func getQuestion(by questionId: QuestionID) async throws -> Question?
    func getAllQuestions() async throws -> [Question]
    func getQuestions(by subject: Subject) async throws -> [Question]
    func getQuestions(by difficulty: Difficulty) async throws -> [Question]
    func getQuestions(by masteryLevel: MasteryLevel) async throws -> [Question]
    func searchQuestions(
        searchTerm: String, subject: Subject?, difficulty: Difficulty?, tags: Set<Tag>?
    ) async throws -> [Question]
    func getQuestionStatistics(for questionId: QuestionID) async throws -> QuestionStatistics
    func scanQuestionFromImage(imageURL: URL, userId: UserID) async throws -> String
    func importQuestionsFromFile(fileURL: URL, fileType: String, userId: UserID) async throws -> Int
    func exportQuestionsToFile(questionIds: [QuestionID], fileType: String, userId: UserID) async throws -> URL
}

/// OCR 服务接口 (简化版)
protocol OCRService: Sendable {
    func performOCR(on imageURL: URL) async throws -> String
}

/// 文件系统管理器接口 (简化版)
protocol FileSystemManager: Sendable {
    func readFile(at url: URL) async throws -> Data
    func writeFile(data: Data, to url: URL) async throws
    func createTemporaryFile(withExtension fileExtension: String) async throws -> URL
}

/// 题目聚合仓储接口 (简化版)
protocol QuestionAggregateRepository: Sendable {
    func save(_ question: Question) async throws
    func find(by id: QuestionID) async throws -> Question?
    func findAll() async throws -> [Question]
    func find(by subject: Subject) async throws -> [Question]
    func find(by difficulty: Difficulty) async throws -> [Question]
    func find(by masteryLevel: MasteryLevel) async throws -> [Question]
    func findQuestionsNeedingReview() async throws -> [Question]
    func delete(_ question: Question) async throws
}


/// 默认题目管理用例实现
/// 负责协调题目创建、编辑、删除、查询、导入/导出和OCR识别等操作，
/// 通过 `CommandQueryBus` 与底层处理器交互。
/// 遵循 `QuestionManagementUseCase` 协议。
struct DefaultQuestionManagementUseCase: QuestionManagementUseCase {

    private let commandBus: CommandQueryBus // 用于发送命令
    private let queryBus: CommandQueryBus // 用于发送查询
    private let ocrService: OCRService // 依赖注入 OCR 服务
    private let fileSystemManager: FileSystemManager // 依赖注入文件系统管理器

    /// 初始化默认题目管理用例
    /// - Parameters:
    ///   - commandBus: 命令总线实例。
    ///   - queryBus: 查询总线实例。
    ///   - ocrService: OCR 服务实例。
    ///   - fileSystemManager: 文件系统管理器实例。
    init(commandBus: CommandQueryBus, queryBus: CommandQueryBus, ocrService: OCRService, fileSystemManager: FileSystemManager) {
        self.commandBus = commandBus
        self.queryBus = queryBus
        self.ocrService = ocrService
        self.fileSystemManager = fileSystemManager
    }

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
    ) async throws -> QuestionID {
        let command = AddSimpleQuestionCommand(
            content: content,
            correctAnswer: correctAnswer,
            subject: subject,
            difficulty: difficulty,
            tags: tags,
            source: source,
            explanation: explanation
        )
        try await commandBus.execute(command)
        // 假设命令处理器会返回新创建的 QuestionID，或者这里需要一个查询来获取
        // 为简化，这里返回一个占位符UUID
        return QuestionID()
    }

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
    ) async throws -> QuestionID {
        let command = AddMultipleChoiceQuestionCommand(
            content: content,
            options: options,
            subject: subject,
            difficulty: difficulty,
            tags: tags,
            source: source,
            explanation: explanation
        )
        try await commandBus.execute(command)
        // 假设命令处理器会返回新创建的 QuestionID
        return QuestionID()
    }

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
    ) async throws {
        let command = UpdateQuestionContentCommand(
            questionId: questionId,
            newContentText: newContentText,
            newAttachments: newAttachments
        )
        try await commandBus.execute(command)
    }

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
    ) async throws {
        let command = UpdateQuestionMetadataCommand(
            questionId: questionId,
            newSubject: newSubject,
            newDifficulty: newDifficulty,
            newTags: newTags,
            newSource: newSource,
            newExplanation: newExplanation
        )
        try await commandBus.execute(command)
    }

    /// 删除一个题目。
    /// - Parameter questionId: 要删除的题目 ID。
    /// - Throws: `QuestionDomainError.invalidStateForOperation` 如果题目未找到，
    ///           `ApplicationError.unauthorizedAccess` 或其他相关错误。
    func deleteQuestion(questionId: QuestionID) async throws {
        let command = DeleteQuestionCommand(questionId: questionId)
        try await commandBus.execute(command)
    }

    /// 获取单个题目详情。
    /// - Parameter questionId: 要获取的题目 ID。
    /// - Returns: `Question` 聚合根实例，如果不存在则为 `nil`。
    /// - Throws: 任何查询过程中可能发生的错误。
    func getQuestion(by questionId: QuestionID) async throws -> Question? {
        let query = GetQuestionByIdQuery(questionId: questionId)
        return try await queryBus.execute(query) as Question?
    }

    /// 获取所有题目列表。
    /// - Returns: `Question` 聚合根数组。
    /// - Throws: 任何查询过程中可能发生的错误。
    func getAllQuestions() async throws -> [Question] {
        let query = GetAllQuestionsQuery()
        return try await queryBus.execute(query) as [Question]
    }

    /// 根据学科获取题目列表。
    /// - Parameter subject: 要查询的学科。
    /// - Returns: 属于指定学科的 `Question` 聚合根数组。
    /// - Throws: 任何查询过程中可能发生的错误。
    func getQuestions(by subject: Subject) async throws -> [Question] {
        let query = GetQuestionsBySubjectQuery(subject: subject)
        return try await queryBus.execute(query) as [Question]
    }

    /// 根据难度获取题目列表。
    /// - Parameter difficulty: 要查询的难度。
    /// - Returns: 属于指定难度的 `Question` 聚合根数组。
    /// - Throws: 任何查询过程中可能发生的错误。
    func getQuestions(by difficulty: Difficulty) async throws -> [Question] {
        let query = GetQuestionsByDifficultyQuery(difficulty: difficulty)
        return try await queryBus.execute(query) as [Question]
    }

    /// 根据掌握程度获取题目列表。
    /// - Parameter masteryLevel: 要查询的掌握程度。
    /// - Returns: 属于指定掌握程度的 `Question` 聚合根数组。
    /// - Throws: 任何查询过程中可能发生的错误。
    func getQuestions(by masteryLevel: MasteryLevel) async throws -> [Question] {
        let query = GetQuestionsByMasteryLevelQuery(masteryLevel: masteryLevel)
        return try await queryBus.execute(query) as [Question]
    }

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
    ) async throws -> [Question] {
        let query = SearchQuestionsQuery(
            searchTerm: searchTerm,
            subject: subject,
            difficulty: difficulty,
            tags: tags
        )
        return try await queryBus.execute(query) as [Question]
    }

    /// 获取某个题目的统计信息。
    /// - Parameter questionId: 题目的 ID。
    /// - Returns: `QuestionStatistics` 值对象。
    /// - Throws: `QuestionDomainError.invalidStateForOperation` 如果题目未找到，
    ///           或其他相关错误。
    func getQuestionStatistics(for questionId: QuestionID) async throws -> QuestionStatistics {
        let query = GetQuestionStatisticsQuery(questionId: questionId)
        return try await queryBus.execute(query) as QuestionStatistics
    }

    /// 扫描图片中的题目并进行 OCR 识别。
    /// - Parameters:
    ///   - imageURL: 图片的本地文件 URL。
    ///   - userId: 执行操作的用户 ID (用于权限或个性化)。
    /// - Returns: 识别出的题目内容字符串。
    /// - Throws: `QuestionDomainError.ocrFailed` 或其他相关错误。
    func scanQuestionFromImage(imageURL: URL, userId: UserID) async throws -> String {
        // 在实际应用中，这里可能需要权限检查 (userId)
        // 并且OCR服务可能需要更复杂的输入，例如图片数据而不是URL
        do {
            let recognizedText = try await ocrService.performOCR(on: imageURL)
            return recognizedText
        } catch {
            throw QuestionDomainError.ocrFailed("OCR服务处理图片失败: \(error.localizedDescription)")
        }
    }

    /// 导入题目文件（例如，从 CSV、JSON 或其他格式）。
    /// - Parameters:
    ///   - fileURL: 导入文件的本地文件 URL。
    ///   - fileType: 文件的类型（例如 "csv", "json"）。
    ///   - userId: 执行操作的用户 ID (用于权限或个性化)。
    /// - Returns: 成功导入的题目数量。
    /// - Throws: `QuestionDomainError.fileParsingFailed`, `QuestionDomainError`
    ///           或其他相关错误。
    func importQuestionsFromFile(fileURL: URL, fileType: String, userId: UserID) async throws -> Int {
        // 在实际应用中，这里可能需要权限检查 (userId)
        // 并且导入逻辑可能非常复杂，涉及文件解析、数据验证、批量保存等
        let command = ImportQuestionsFromFileCommand(fileURL: fileURL, fileType: fileType)
        try await commandBus.execute(command)
        // 假设命令处理器会返回导入的数量
        return 0 // Placeholder
    }

    /// 导出题目到文件。
    /// - Parameters:
    ///   - questionIds: 要导出的题目 ID 列表。
    ///   - fileType: 导出文件的类型（例如 "csv", "json"）。
    ///   - userId: 执行操作的用户 ID (用于权限或个性化)。
    /// - Returns: 导出文件的本地文件 URL。
    /// - Throws: `QuestionDomainError.fileWritingFailed`, `QuestionDomainError`
    ///           或其他相关错误。
    func exportQuestionsToFile(questionIds: [QuestionID], fileType: String, userId: UserID) async throws -> URL {
        // 在实际应用中，这里可能需要权限检查 (userId)
        // 导出逻辑可能涉及从数据库读取数据、格式化、写入文件等
        let query = ExportQuestionsToFileQuery(questionIds: questionIds, fileType: fileType)
        return try await queryBus.execute(query) as URL
    }
}

