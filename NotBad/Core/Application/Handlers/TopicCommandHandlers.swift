//
//  TopicCommandHandlers.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助应用层和领域层类型导入 (这些类型应在各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreApplicationCommands // 包含 CreateTopicCommand 等
// import NotBadCoreApplicationHandlers // 包含 CommandHandler 协议
// import NotBadCoreDomainEntitiesContentTopic // 包含 Topic
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainRepositories // 包含 TopicRepository 协议
// import NotBadCoreDomainErrors // 包含 QuestionDomainError

/// 主题领域实体 (仅为编译目的包含，实际应从 Topic.swift 导入)
// Note: In a real project, this would be in its own file: Core/Domain/Entities/Content/Topic.swift
struct Topic: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let name: String
    let subject: Subject
    let description: String?
    let createdAt: Date
    let lastModifiedAt: Date

    // Simplified init for compilation
    init(id: UUID = UUID(), name: String, subject: Subject, description: String? = nil, createdAt: Date = Date(), lastModifiedAt: Date = Date()) throws {
        // Dummy validation for compilation
        if name.isEmpty { throw QuestionDomainError.emptyTopicName }
        self.id = id; self.name = name; self.subject = subject; self.description = description; self.createdAt = createdAt; self.lastModifiedAt = lastModifiedAt
    }

    // Simplified update methods for compilation
    func updateName(_ newName: String) throws -> Topic {
        return try Topic(id: id, name: newName, subject: subject, description: description, createdAt: createdAt, lastModifiedAt: Date())
    }

    func updateDescription(_ newDescription: String?) -> Topic {
        return try! Topic(id: id, name: name, subject: subject, description: newDescription, createdAt: createdAt, lastModifiedAt: Date())
    }

    // Simplified reconstruct for compilation
    static func reconstruct(id: UUID, name: String, subject: Subject, description: String?, createdAt: Date, lastModifiedAt: Date) -> Topic {
        return try! Topic(id: id, name: name, subject: subject, description: description, createdAt: createdAt, lastModifiedAt: lastModifiedAt)
    }
}

/// 学科枚举 (仅为编译目的包含，实际应从 Subject.swift 导入)
// Note: In a real project, this would be in its own file: Core/Domain/Entities/Content/Subject.swift
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

    static func findCoreSubject(byName name: String) -> Subject? {
        return Subject.allCases.first(where: { $0.rawValue == name })
    }
}

/// 题目领域错误 (仅为编译目的包含，实际应从 QuestionDomainError.swift 导入)
// Note: In a real project, this would be in its own file: Core/Domain/Errors/QuestionDomainError.swift
enum QuestionDomainError: Error, CustomStringConvertible, LocalizedError {
    case invalidStateForOperation(String)
    case emptyTopicName
    case topicNameTooLong(String)
    case topicAlreadyExists(String, Subject)
    // Simplified for compilation
    var description: String {
        switch self {
        case .invalidStateForOperation(let op): return "Invalid state for operation: \(op)"
        case .emptyTopicName: return "Topic name cannot be empty."
        case .topicNameTooLong(let name): return "Topic name '\(name)' is too long."
        case .topicAlreadyExists(let name, let subject): return "Topic '\(name)' already exists in subject '\(subject.displayName)'."
        default: return "An unknown error occurred."
        }
    }
    var errorDescription: String? { return description }
}

/// 命令协议 (仅为编译目的包含，实际应从 Command.swift 导入)
// Note: In a real project, this would be in its own file: Core/Application/Commands/Command.swift
protocol Command: Hashable, Sendable { }

/// 命令处理器协议 (仅为编译目的包含，实际应从 CommandHandler.swift 导入)
// Note: In a real project, this would be in its own file: Core/Application/Handlers/CommandHandler.swift
protocol CommandHandler<C>: Sendable {
    associatedtype C: Command
    func handle(_ command: C) async throws
}

/// 主题命令：创建主题 (仅为编译目的包含，实际应从 TopicCommands.swift 导入)
struct CreateTopicCommand: Command {
    let name: String
    let subject: Subject
    let description: String?
}

/// 主题命令：更新主题名称 (仅为编译目的包含，实际应从 TopicCommands.swift 导入)
struct UpdateTopicNameCommand: Command {
    let topicId: UUID
    let newName: String
}

/// 主题命令：更新主题描述 (仅为编译目的包含，实际应从 TopicCommands.swift 导入)
struct UpdateTopicDescriptionCommand: Command {
    let topicId: UUID
    let newDescription: String?
}

/// 主题命令：删除主题 (仅为编译目的包含，实际应从 TopicCommands.swift 导入)
struct DeleteTopicCommand: Command {
    let topicId: UUID
}

/// 主题仓储接口 (仅为编译目的包含，实际应从 TopicRepository.swift 导入)
// Note: In a real project, this would be in its own file: Core/Domain/Repositories/TopicRepository.swift
protocol TopicRepository: Sendable {
    func save(_ topic: Topic) async throws
    func find(by id: UUID) async throws -> Topic?
    func find(by name: String, in subject: Subject) async throws -> Topic?
    func delete(_ topic: Topic) async throws
    func findAll() async throws -> [Topic]
    func find(by subject: Subject) async throws -> [Topic]
}


/// 创建主题命令处理器
/// 负责处理 `CreateTopicCommand`，创建 `Topic` 实体并保存。
struct CreateTopicCommandHandler: CommandHandler {
    typealias C = CreateTopicCommand

    private let topicRepository: TopicRepository // 依赖注入主题仓储

    /// 初始化命令处理器
    /// - Parameter topicRepository: 主题仓储的实例。
    init(topicRepository: TopicRepository) {
        self.topicRepository = topicRepository
    }

    /// 处理 `CreateTopicCommand` 命令。
    /// - Parameter command: 要处理的命令实例。
    /// - Throws: `QuestionDomainError` (如 `emptyTopicName`, `topicNameTooLong`, `topicAlreadyExists`) 或其他持久化相关的错误。
    func handle(_ command: CreateTopicCommand) async throws {
        // 1. 检查同名主题是否已存在于同一学科下
        if try await topicRepository.find(by: command.name, in: command.subject) != nil {
            throw QuestionDomainError.topicAlreadyExists(command.name, command.subject)
        }

        // 2. 使用领域层的初始化器创建 Topic 实体，这里会进行名称验证
        let topic = try Topic(
            name: command.name,
            subject: command.subject,
            description: command.description
        )

        // 3. 通过仓储保存 Topic 实体
        try await topicRepository.save(topic)

        // 4. (可选) 发布领域事件，例如 TopicCreatedEvent
        // EventBus.shared.publish(TopicCreatedEvent(topicId: topic.id))
    }
}

/// 更新主题名称命令处理器
/// 负责处理 `UpdateTopicNameCommand`，更新现有主题的名称。
struct UpdateTopicNameCommandHandler: CommandHandler {
    typealias C = UpdateTopicNameCommand

    private let topicRepository: TopicRepository

    init(topicRepository: TopicRepository) {
        self.topicRepository = topicRepository
    }

    func handle(_ command: UpdateTopicNameCommand) async throws {
        // 1. 从仓储获取要更新的 Topic 实体
        guard let existingTopic = try await topicRepository.find(by: command.topicId) else {
            throw QuestionDomainError.invalidStateForOperation("主题ID \(command.topicId.uuidString) 未找到。")
        }

        // 2. 检查新名称是否与同一学科下的其他主题冲突
        if let existingTopicWithNewName = try await topicRepository.find(by: command.newName, in: existingTopic.subject),
           existingTopicWithNewName.id != existingTopic.id {
            throw QuestionDomainError.topicAlreadyExists(command.newName, existingTopic.subject)
        }

        // 3. 调用 Topic 实体的方法更新名称（返回新实例）
        let updatedTopic = try existingTopic.updateName(command.newName)

        // 4. 通过仓储保存更新后的 Topic 实体
        try await topicRepository.save(updatedTopic)
    }
}

/// 更新主题描述命令处理器
/// 负责处理 `UpdateTopicDescriptionCommand`，更新现有主题的描述。
struct UpdateTopicDescriptionCommandHandler: CommandHandler {
    typealias C = UpdateTopicDescriptionCommand

    private let topicRepository: TopicRepository

    init(topicRepository: TopicRepository) {
        self.topicRepository = topicRepository
    }

    func handle(_ command: UpdateTopicDescriptionCommand) async throws {
        // 1. 从仓储获取要更新的 Topic 实体
        guard let existingTopic = try await topicRepository.find(by: command.topicId) else {
            throw QuestionDomainError.invalidStateForOperation("主题ID \(command.topicId.uuidString) 未找到。")
        }

        // 2. 调用 Topic 实体的方法更新描述（返回新实例）
        let updatedTopic = existingTopic.updateDescription(command.newDescription)

        // 3. 通过仓储保存更新后的 Topic 实体
        try await topicRepository.save(updatedTopic)
    }
}

/// 删除主题命令处理器
/// 负责处理 `DeleteTopicCommand`，从仓储中删除主题。
struct DeleteTopicCommandHandler: CommandHandler {
    typealias C = DeleteTopicCommand

    private let topicRepository: TopicRepository

    init(topicRepository: TopicRepository) {
        self.topicRepository = topicRepository
    }

    func handle(_ command: DeleteTopicCommand) async throws {
        // 1. 从仓储获取要删除的 Topic 实体
        guard let topicToDelete = try await topicRepository.find(by: command.topicId) else {
            throw QuestionDomainError.invalidStateForOperation("主题ID \(command.topicId.uuidString) 未找到，无法删除。")
        }

        // 2. 通过仓储删除 Topic 实体
        try await topicRepository.delete(topicToDelete)

        // 3. (可选) 发布领域事件，例如 TopicDeletedEvent
        // EventBus.shared.publish(TopicDeletedEvent(topicId: command.topicId))
    }
}

