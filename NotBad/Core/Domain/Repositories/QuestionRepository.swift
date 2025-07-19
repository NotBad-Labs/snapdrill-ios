//
//  QuestionRepository.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesContentQuestion // 包含 Question (实体)
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesContentTopic // 包含 Topic
// import NotBadCoreDomainErrors // 包含 AcademicDomainError (或其他通用领域错误)

/// 用户ID强类型 (仅为编译目的包含，实际应从 UserID.swift 导入)
struct UserID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
    init() { self.rawValue = UUID().uuidString }
}

/// 学科枚举 (仅为编译目的包含，实际应从 Subject.swift 导入)
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
    static func findCoreSubject(byName name: String) -> Subject? { return Subject.allCases.first(where: { $0.rawValue == name }) }
}

/// 主题领域实体 (仅为编译目的包含，实际应从 Topic.swift 导入)
struct Topic: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let name: String
    let subject: Subject
    let description: String?
    let createdAt: Date
    let lastModifiedAt: Date

    init(id: UUID = UUID(), name: String, subject: Subject, description: String? = nil, createdAt: Date = Date(), lastModifiedAt: Date = Date()) {
        self.id = id; self.name = name; self.subject = subject; self.description = description; self.createdAt = createdAt; self.lastModifiedAt = lastModifiedAt
    }
    static func reconstruct(id: UUID, name: String, subject: Subject, description: String?, createdAt: Date, lastModifiedAt: Date) -> Topic {
        return Topic(id: id, name: name, subject: subject, description: description, createdAt: createdAt, lastModifiedAt: lastModifiedAt)
    }
}

/// 问题类型枚举 (仅为编译目的包含，实际应从 QuestionType.swift 导入)
enum QuestionType: String, Codable, CaseIterable, Sendable, Hashable {
    case multipleChoice = "选择题"
    case trueFalse = "判断题"
    case shortAnswer = "简答题"
    case essay = "论述题"
    case fillInTheBlank = "填空题"
    case matching = "匹配题"
    case calculation = "计算题"
    case programming = "编程题"
    case diagram = "图示题"
    case other = "其他"

    var displayName: String { rawValue }
}

/// 问题难度枚举 (仅为编译目的包含，实际应从 QuestionDifficulty.swift 导入)
enum QuestionDifficulty: String, Codable, CaseIterable, Sendable, Hashable {
    case easy = "简单"
    case medium = "中等"
    case hard = "困难"
    case veryHard = "非常困难"

    var displayName: String { rawValue }
}

/// 问题状态枚举 (仅为编译目的包含，实际应从 QuestionStatus.swift 导入)
enum QuestionStatus: String, Codable, CaseIterable, Sendable, Hashable {
    case draft = "草稿"
    case active = "活跃"
    case archived = "已归档"
    case deleted = "已删除"

    var displayName: String { rawValue }
}

/// 问题来源枚举 (仅为编译目的包含，实际应从 QuestionSource.swift 导入)
enum QuestionSource: String, Codable, CaseIterable, Sendable, Hashable {
    case userCreated = "用户创建"
    case imported = "导入"
    case generated = "AI生成"
    case textbook = "教材"
    case exam = "考试"
    case other = "其他"

    var displayName: String { rawValue }
}

/// 问题标签值对象 (仅为编译目的包含，实际应从 QuestionTag.swift 导入)
struct QuestionTag: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

/// 问题领域实体 (仅为编译目的包含，实际应从 Question.swift 导入)
struct Question: Identifiable, Hashable, Codable, Sendable {
    let id: UUID // 问题的唯一标识符
    let userId: UserID // 问题创建者或所属用户ID
    let subject: Subject // 问题所属学科
    let topicId: UUID? // 可选：问题所属主题ID
    private(set) var type: QuestionType // 问题类型
    private(set) var difficulty: QuestionDifficulty // 问题难度
    private(set) var content: String // 问题内容
    private(set) var options: [String]? // 选择题选项，或其他类型题目的相关数据
    private(set) var correctAnswer: String? // 正确答案
    private(set) var explanation: String? // 答案解析
    private(set) var status: QuestionStatus // 问题状态
    private(set) var source: QuestionSource // 问题来源
    private(set) var tags: [QuestionTag] // 问题标签
    let createdAt: Date // 问题创建时间
    private(set) var lastModifiedAt: Date // 问题上次修改时间

    init(
        id: UUID = UUID(),
        userId: UserID,
        subject: Subject,
        topicId: UUID? = nil,
        type: QuestionType,
        difficulty: QuestionDifficulty,
        content: String,
        options: [String]? = nil,
        correctAnswer: String? = nil,
        explanation: String? = nil,
        status: QuestionStatus = .active,
        source: QuestionSource = .userCreated,
        tags: [QuestionTag] = [],
        createdAt: Date = Date(),
        lastModifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.subject = subject
        self.topicId = topicId
        self.type = type
        self.difficulty = difficulty
        self.content = content
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.status = status
        self.source = source
        self.tags = tags
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
    }

    static func reconstruct(
        id: UUID,
        userId: UserID,
        subject: Subject,
        topicId: UUID?,
        type: QuestionType,
        difficulty: QuestionDifficulty,
        content: String,
        options: [String]?,
        correctAnswer: String?,
        explanation: String?,
        status: QuestionStatus,
        source: QuestionSource,
        tags: [QuestionTag],
        createdAt: Date,
        lastModifiedAt: Date
    ) -> Question {
        return Question(
            id: id,
            userId: userId,
            subject: subject,
            topicId: topicId,
            type: type,
            difficulty: difficulty,
            content: content,
            options: options,
            correctAnswer: correctAnswer,
            explanation: explanation,
            status: status,
            source: source,
            tags: tags,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
    }

    func updateContent(newContent: String) -> Question {
        return Question(
            id: id, userId: userId, subject: subject, topicId: topicId, type: type,
            difficulty: difficulty, content: newContent, options: options,
            correctAnswer: correctAnswer, explanation: explanation, status: status,
            source: source, tags: tags, createdAt: createdAt, lastModifiedAt: Date()
        )
    }

    func updateOptions(newOptions: [String]?) -> Question {
        return Question(
            id: id, userId: userId, subject: subject, topicId: topicId, type: type,
            difficulty: difficulty, content: content, options: newOptions,
            correctAnswer: correctAnswer, explanation: explanation, status: status,
            source: source, tags: tags, createdAt: createdAt, lastModifiedAt: Date()
        )
    }

    func updateAnswer(newAnswer: String?) -> Question {
        return Question(
            id: id, userId: userId, subject: subject, topicId: topicId, type: type,
            difficulty: difficulty, content: content, options: options,
            correctAnswer: newAnswer, explanation: explanation, status: status,
            source: source, tags: tags, createdAt: createdAt, lastModifiedAt: Date()
        )
    }

    func updateExplanation(newExplanation: String?) -> Question {
        return Question(
            id: id, userId: userId, subject: subject, topicId: topicId, type: type,
            difficulty: difficulty, content: content, options: options,
            correctAnswer: correctAnswer, explanation: newExplanation, status: status,
            source: source, tags: tags, createdAt: createdAt, lastModifiedAt: Date()
        )
    }

    func updateStatus(newStatus: QuestionStatus) -> Question {
        return Question(
            id: id, userId: userId, subject: subject, topicId: topicId, type: type,
            difficulty: difficulty, content: content, options: options,
            correctAnswer: correctAnswer, explanation: explanation, status: newStatus,
            source: source, tags: tags, createdAt: createdAt, lastModifiedAt: Date()
        )
    }

    func addTag(_ tag: QuestionTag) -> Question {
        var updatedTags = tags
        if !updatedTags.contains(tag) {
            updatedTags.append(tag)
        }
        return Question(
            id: id, userId: userId, subject: subject, topicId: topicId, type: type,
            difficulty: difficulty, content: content, options: options,
            correctAnswer: correctAnswer, explanation: explanation, status: status,
            source: source, tags: updatedTags, createdAt: createdAt, lastModifiedAt: Date()
        )
    }

    func removeTag(_ tag: QuestionTag) -> Question {
        let updatedTags = tags.filter { $0 != tag }
        return Question(
            id: id, userId: userId, subject: subject, topicId: topicId, type: type,
            difficulty: difficulty, content: content, options: options,
            correctAnswer: correctAnswer, explanation: explanation, status: status,
            source: source, tags: updatedTags, createdAt: createdAt, lastModifiedAt: Date()
        )
    }
}

/// 学术领域错误 (仅为编译目的包含，实际应从 AcademicDomainError.swift 导入)
enum AcademicDomainError: Error, CustomStringConvertible, LocalizedError {
    case questionNotFound(UUID)
    case invalidQuestionData(String)
    case subjectNotFoundForQuestion(Subject)
    case topicNotFoundForQuestion(UUID)

    var description: String {
        switch self {
        case .questionNotFound(let id):
            return "问题ID '\(id.uuidString)' 未找到。"
        case .invalidQuestionData(let reason):
            return "问题数据无效: \(reason)。"
        case .subjectNotFoundForQuestion(let subject):
            return "学科 '\(subject.displayName)' 未找到，无法关联问题。"
        case .topicNotFoundForQuestion(let topicId):
            return "主题ID '\(topicId.uuidString)' 未找到，无法关联问题。"
        }
    }

    var errorDescription: String? {
        return description
    }
}

/// 问题仓储接口
/// 定义了对 `Question` 实体进行持久化和检索的契约。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol QuestionRepository: Sendable {

    /// 保存或更新一个 `Question` 实体。
    /// 如果 `Question` 已存在（通过其 ID 判断），则更新；否则，添加。
    /// - Parameter question: 要保存或更新的 `Question` 实体实例。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func save(_ question: Question) async throws

    /// 根据 ID 查找一个 `Question` 实体。
    /// - Parameter id: 要查找的 `Question` 的唯一标识符。
    /// - Returns: 找到的 `Question` 实体实例，如果不存在则为 `nil`。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func find(by id: UUID) async throws -> Question?

    /// 根据用户 ID 查找所有问题。
    /// - Parameter userId: 用户 ID。
    /// - Returns: 属于指定用户的所有 `Question` 实体数组。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func find(by userId: UserID) async throws -> [Question]

    /// 根据用户 ID 和学科查找问题。
    /// - Parameters:
    ///   - userId: 用户 ID。
    ///   - subject: 学科过滤。
    /// - Returns: 属于指定用户和学科的所有 `Question` 实体数组。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func find(by userId: UserID, subject: Subject) async throws -> [Question]

    /// 根据用户 ID、学科和主题查找问题。
    /// - Parameters:
    ///   - userId: 用户 ID。
    ///   - subject: 学科过滤。
    ///   - topicId: 主题 ID 过滤。
    /// - Returns: 属于指定用户、学科和主题的所有 `Question` 实体数组。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func find(by userId: UserID, subject: Subject, topicId: UUID) async throws -> [Question]

    /// 根据用户 ID 和标签查找问题。
    /// - Parameters:
    ///   - userId: 用户 ID。
    ///   - tag: 标签过滤。
    /// - Returns: 属于指定用户并包含指定标签的所有 `Question` 实体数组。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func find(by userId: UserID, tag: QuestionTag) async throws -> [Question]

    /// 根据用户 ID 和问题类型查找问题。
    /// - Parameters:
    ///   - userId: 用户 ID。
    ///   - type: 问题类型过滤。
    /// - Returns: 属于指定用户和问题类型的所有 `Question` 实体数组。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func find(by userId: UserID, type: QuestionType) async throws -> [Question]

    /// 删除一个 `Question` 实体。
    /// - Parameter question: 要删除的 `Question` 实体实例。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func delete(_ question: Question) async throws

    // 您可以根据业务需求添加更多查询方法，例如：
    // func findQuestionsByDifficulty(userId: UserID, difficulty: QuestionDifficulty) async throws -> [Question]
    // func searchQuestions(userId: UserID, query: String) async throws -> [Question]
}

