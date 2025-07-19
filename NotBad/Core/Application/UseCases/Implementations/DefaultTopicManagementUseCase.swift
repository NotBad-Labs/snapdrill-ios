//
//  DefaultTopicManagementUseCase.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助应用层和领域层类型导入 (这些类型应在各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreApplicationUseCasesTopicManagementUseCase // 包含 TopicManagementUseCase 协议
// import NotBadCoreApplicationCommandQueryBus // 包含 CommandQueryBus
// import NotBadCoreApplicationCommandsTopicCommands // 包含 CreateTopicCommand 等
// import NotBadCoreApplicationQueriesTopicQueries // 包含 GetTopicByIdQuery 等
// import NotBadCoreDomainEntitiesContentTopic // 包含 Topic
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainErrorsQuestionDomainError // 包含 QuestionDomainError
// import NotBadCoreApplicationErrorsApplicationError // 包含 ApplicationError
// import NotBadCoreDomainRepositoriesTopicRepository // 包含 TopicRepository

/// 主题领域实体 (简化版)
struct Topic: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let name: String
    let subject: Subject
    let description: String?
    let createdAt: Date
    let lastModifiedAt: Date

    init(id: UUID = UUID(), name: String, subject: Subject, description: String? = nil, createdAt: Date = Date(), lastModifiedAt: Date = Date()) throws {
        self.id = id; self.name = name; self.subject = subject; self.description = description; self.createdAt = createdAt; self.lastModifiedAt = lastModifiedAt
    }
    static func reconstruct(id: UUID, name: String, subject: Subject, description: String?, createdAt: Date, lastModifiedAt: Date) -> Topic {
        return try! Topic(id: id, name: name, subject: subject, description: description, createdAt: createdAt, lastModifiedAt: lastModifiedAt)
    }
}

/// 学科枚举 (简化版)
enum Subject: String, CaseIterable, Codable, Sendable, Hashable {
    case mathematics = "数学"
    case physics = "物理"
    case general = "综合"
    var displayName: String { rawValue }
    static func findCoreSubject(byName name: String) -> Subject? { return nil }
}

/// 题目领域错误 (简化版)
enum QuestionDomainError: Error, CustomStringConvertible, LocalizedError {
    case topicAlreadyExists(String, Subject)
    case emptyTopicName
    case topicNameTooLong(String)
    case invalidStateForOperation(String)

    var description: String {
        switch self {
        case .topicAlreadyExists(let name, let subject): return "Topic '\(name)' already exists in subject '\(subject.displayName)'."
        case .emptyTopicName: return "Topic name cannot be empty."
        case .topicNameTooLong(let name): return "Topic name '\(name)' is too long."
        case .invalidStateForOperation(let op): return "Invalid state for operation: \(op)"
        }
    }
    var errorDescription: String? { return description }
}

/// 应用层错误 (简化版)
enum ApplicationError: Error, CustomStringConvertible, LocalizedError, Hashable, Sendable {
    case handlerNotFound(String)
    case invalidHandlerType(String)
    case unknownError(String)

    var description: String {
        switch self {
        case .handlerNotFound(let name): return "未找到命令/查询处理器: \(name)。"
        case .invalidHandlerType(let name): return "处理器类型不匹配: \(name)。"
        case .unknownError(let message): return "发生未知错误: \(message)。"
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
    private var commandHandlers: [String: Any] = [:]
    private var queryHandlers: [String: Any] = [:]

    @discardableResult
    func register<C: Command, H: CommandHandler>(handler: H, for commandType: C.Type) -> CommandQueryBus where H.C == C {
        let key = String(describing: commandType)
        commandHandlers[key] = handler
        return self
    }

    @discardableResult
    func register<Q: Query, R, H: QueryHandler>(handler: H, for queryType: Q.Type) -> CommandQueryBus where H.Q == Q, H.R == R {
        let key = String(describing: queryType)
        queryHandlers[key] = handler
        return self
    }

    func execute<C: Command>(_ command: C) async throws {
        let key = String(describing: type(of: command))
        guard let handler = commandHandlers[key] as? any CommandHandler<C> else {
            throw ApplicationError.handlerNotFound("Command handler for \(key) not found or type mismatched.")
        }
        try await handler.handle(command)
    }

    func execute<Q: Query, R>(_ query: Q) async throws -> R {
        let key = String(describing: type(of: query))
        guard let handler = queryHandlers[key] as? any QueryHandler<Q, R> else {
            throw ApplicationError.handlerNotFound("Query handler for \(key) not found or type mismatched.")
        }
        return try await handler.handle(query)
    }
}

/// 主题命令：创建主题 (简化版)
struct CreateTopicCommand: Command {
    let name: String
    let subject: Subject
    let description: String?
}

/// 主题命令：更新主题名称 (简化版)
struct UpdateTopicNameCommand: Command {
    let topicId: UUID
    let newName: String
}

/// 主题命令：更新主题描述 (简化版)
struct UpdateTopicDescriptionCommand: Command {
    let topicId: UUID
    let newDescription: String?
}

/// 主题命令：删除主题 (简化版)
struct DeleteTopicCommand: Command {
    let topicId: UUID
}

/// 主题查询：根据ID获取主题 (简化版)
struct GetTopicByIdQuery: Query {
    let topicId: UUID
}

/// 主题查询：获取所有主题 (简化版)
struct GetAllTopicsQuery: Query {
    // No additional properties
}

/// 主题查询：根据学科获取主题列表 (简化版)
struct GetTopicsBySubjectQuery: Query {
    let subject: Subject
}

/// 主题查询：搜索主题 (简化版)
struct SearchTopicsQuery: Query {
    let searchTerm: String
    let subject: Subject?
}

/// 主题仓储接口 (简化版)
protocol TopicRepository: Sendable {
    func save(_ topic: Topic) async throws
    func find(by id: UUID) async throws -> Topic?
    func find(by name: String, in subject: Subject) async throws -> Topic?
    func delete(_ topic: Topic) async throws
    func findAll() async throws -> [Topic]
    func find(by subject: Subject) async throws -> [Topic]
}


/// 主题管理用例接口 (简化版)
protocol TopicManagementUseCase: Sendable {
    func createTopic(name: String, subject: Subject, description: String?) async throws -> UUID
    func updateTopicName(topicId: UUID, newName: String) async throws
    func updateTopicDescription(topicId: UUID, newDescription: String?) async throws
    func deleteTopic(topicId: UUID) async throws
    func getTopic(by topicId: UUID) async throws -> Topic?
    func getAllTopics() async throws -> [Topic]
    func getTopics(by subject: Subject) async throws -> [Topic]
    func searchTopics(searchTerm: String, subject: Subject?) async throws -> [Topic]
}


/// 默认主题管理用例实现
/// 负责协调主题管理相关的命令和查询，通过 `CommandQueryBus` 与底层处理器交互。
/// 遵循 `TopicManagementUseCase` 协议。
struct DefaultTopicManagementUseCase: TopicManagementUseCase {

    private let commandBus: CommandQueryBus // 用于发送命令
    private let queryBus: CommandQueryBus // 用于发送查询
    private let topicRepository: TopicRepository // 用于在用例层进行一些直接的仓储操作，例如检查主题是否存在

    /// 初始化默认主题管理用例
    /// - Parameters:
    ///   - commandBus: 命令总线实例。
    ///   - queryBus: 查询总线实例。
    ///   - topicRepository: 主题仓储实例。
    init(commandBus: CommandQueryBus, queryBus: CommandQueryBus, topicRepository: TopicRepository) {
        self.commandBus = commandBus
        self.queryBus = queryBus
        self.topicRepository = topicRepository
    }

    /// 创建一个新的学习主题。
    /// - Parameters:
    ///   - name: 主题名称。
    ///   - subject: 主题所属的学科。
    ///   - description: 主题描述，可选。
    /// - Returns: 新创建的主题的 ID。
    /// - Throws: `QuestionDomainError.topicAlreadyExists`, `QuestionDomainError.emptyTopicName`,
    ///           `QuestionDomainError.topicNameTooLong` 或其他相关错误。
    func createTopic(name: String, subject: Subject, description: String?) async throws -> UUID {
        // 在创建主题前，先检查同名主题是否已存在于该学科下
        if let existingTopic = try await topicRepository.find(by: name, in: subject) {
            throw QuestionDomainError.topicAlreadyExists(name, subject)
        }

        let command = CreateTopicCommand(
            name: name,
            subject: subject,
            description: description
        )
        try await commandBus.execute(command)

        // 成功创建后，重新查询以获取新创建的 Topic 的 ID。
        // 在实际的 CreateTopicCommandHandler 中，可能直接返回创建的 ID。
        // 这里为了简化，假设通过名称和学科再次查询。
        guard let newTopic = try await topicRepository.find(by: name, in: subject) else {
            throw ApplicationError.unknownError("主题创建成功但无法检索到新主题ID。")
        }
        return newTopic.id
    }

    /// 更新现有主题的名称。
    /// - Parameters:
    ///   - topicId: 要更新的主题 ID。
    ///   - newName: 新的主题名称。
    /// - Throws: `QuestionDomainError.invalidStateForOperation` (如果主题未找到),
    ///           `QuestionDomainError.emptyTopicName`, `QuestionDomainError.topicNameTooLong`,
    ///           `QuestionDomainError.topicAlreadyExists` (如果新名称在同等学科下冲突)
    ///           或其他相关错误。
    func updateTopicName(topicId: UUID, newName: String) async throws {
        // 首先获取现有主题，以便检查新名称是否与同科目下的其他主题冲突
        guard let existingTopic = try await topicRepository.find(by: topicId) else {
            throw QuestionDomainError.invalidStateForOperation("主题ID \(topicId) 未找到，无法更新名称。")
        }

        // 检查新名称是否与同科目下的其他主题冲突 (排除自身)
        if let conflictingTopic = try await topicRepository.find(by: newName, in: existingTopic.subject),
           conflictingTopic.id != topicId {
            throw QuestionDomainError.topicAlreadyExists(newName, existingTopic.subject)
        }

        let command = UpdateTopicNameCommand(
            topicId: topicId,
            newName: newName
        )
        try await commandBus.execute(command)
    }

    /// 更新现有主题的描述。
    /// - Parameters:
    ///   - topicId: 要更新的主题 ID。
    ///   - newDescription: 新的主题描述，nil 表示清除。
    /// - Throws: `QuestionDomainError.invalidStateForOperation` (如果主题未找到)
    ///           或其他相关错误。
    func updateTopicDescription(topicId: UUID, newDescription: String?) async throws {
        // 验证主题是否存在
        guard let _ = try await topicRepository.find(by: topicId) else {
            throw QuestionDomainError.invalidStateForOperation("主题ID \(topicId) 未找到，无法更新描述。")
        }

        let command = UpdateTopicDescriptionCommand(
            topicId: topicId,
            newDescription: newDescription
        )
        try await commandBus.execute(command)
    }

    /// 删除一个学习主题。
    /// - Parameter topicId: 要删除的主题 ID。
    /// - Throws: `QuestionDomainError.invalidStateForOperation` (如果主题未找到)
    ///           或其他相关错误。
    func deleteTopic(topicId: UUID) async throws {
        // 验证主题是否存在
        guard let _ = try await topicRepository.find(by: topicId) else {
            throw QuestionDomainError.invalidStateForOperation("主题ID \(topicId) 未找到，无法删除。")
        }

        let command = DeleteTopicCommand(topicId: topicId)
        try await commandBus.execute(command)
    }

    /// 根据 ID 获取一个学习主题的详情。
    /// - Parameter topicId: 要获取的主题 ID。
    /// - Returns: `Topic` 实体实例，如果不存在则为 `nil`。
    /// - Throws: 任何查询过程中可能发生的错误。
    func getTopic(by topicId: UUID) async throws -> Topic? {
        let query = GetTopicByIdQuery(topicId: topicId)
        return try await queryBus.execute(query) as Topic?
    }

    /// 获取系统中所有学习主题的列表。
    /// - Returns: `Topic` 实体数组。
    /// - Throws: 任何查询过程中可能发生的错误。
    func getAllTopics() async throws -> [Topic] {
        let query = GetAllTopicsQuery()
        return try await queryBus.execute(query) as [Topic]
    }

    /// 获取特定学科下的学习主题列表。
    /// - Parameter subject: 要查询的学科。
    /// - Returns: `Topic` 实体数组。
    /// - Throws: 任何查询过程中可能发生的错误。
    func getTopics(by subject: Subject) async throws -> [Topic] {
        let query = GetTopicsBySubjectQuery(subject: subject)
        return try await queryBus.execute(query) as [Topic]
    }

    /// 根据关键词搜索学习主题。
    /// - Parameters:
    ///   - searchTerm: 搜索关键词。
    ///   - subject: 可选的学科过滤。
    /// - Returns: 匹配的 `Topic` 实体数组。
    /// - Throws: 任何搜索过程中可能发生的错误。
    func searchTopics(searchTerm: String, subject: Subject?) async throws -> [Topic] {
        let query = SearchTopicsQuery(searchTerm: searchTerm, subject: subject)
        return try await queryBus.execute(query) as [Topic]
    }
}

