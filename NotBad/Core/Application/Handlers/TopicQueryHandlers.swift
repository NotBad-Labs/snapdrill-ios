//
//  TopicQueryHandlers.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助应用层和领域层类型导入 (这些类型应在各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreApplicationQueries // 包含 GetTopicByIdQuery 等
// import NotBadCoreApplicationHandlers // 包含 QueryHandler 协议
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
        self.id = id; self.name = name; self.subject = subject; self.description = description; self.createdAt = createdAt; self.lastModifiedAt = lastModifiedAt
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
    // Simplified for compilation
    var description: String {
        switch self {
        case .invalidStateForOperation(let op): return "Invalid state for operation: \(op)"
        }
    }
    var errorDescription: String? { return description }
}

/// 查询协议 (仅为编译目的包含，实际应从 Query.swift 导入)
// Note: In a real project, this would be in its own file: Core/Application/Queries/Query.swift
protocol Query: Hashable, Sendable { }

/// 查询处理器协议 (仅为编译目的包含，实际应从 QueryHandler.swift 导入)
// Note: In a real project, this would be in its own file: Core/Application/Handlers/QueryHandler.swift
protocol QueryHandler<Q, R>: Sendable {
    associatedtype Q: Query
    associatedtype R
    func handle(_ query: Q) async throws -> R
}

/// 主题查询：根据ID获取主题 (仅为编译目的包含，实际应从 TopicQueries.swift 导入)
struct GetTopicByIdQuery: Query {
    let topicId: UUID
}

/// 主题查询：获取所有主题 (仅为编译目的包含，实际应从 TopicQueries.swift 导入)
struct GetAllTopicsQuery: Query {
    // No additional properties
}

/// 主题查询：根据学科获取主题列表 (仅为编译目的包含，实际应从 TopicQueries.swift 导入)
struct GetTopicsBySubjectQuery: Query {
    let subject: Subject
}

/// 主题查询：搜索主题 (仅为编译目的包含，实际应从 TopicQueries.swift 导入)
struct SearchTopicsQuery: Query {
    let searchTerm: String
    let subject: Subject?
}

/// 主题仓储接口 (仅为编译目的包含，实际应从 TopicRepository.swift 导入)
// Note: In a real project, this would be in its own file: Core/Domain/Repositories/TopicRepository.swift
protocol TopicRepository: Sendable {
    func find(by id: UUID) async throws -> Topic?
    func findAll() async throws -> [Topic]
    func find(by subject: Subject) async throws -> [Topic]
    // Simplified for compilation
    func save(_ topic: Topic) async throws
    func delete(_ topic: Topic) async throws
    func find(by name: String, in subject: Subject) async throws -> Topic?
}


/// 根据ID获取主题查询处理器
/// 负责处理 `GetTopicByIdQuery`，从仓储中获取单个主题。
struct GetTopicByIdQueryHandler: QueryHandler {
    typealias Q = GetTopicByIdQuery
    typealias R = Topic? // 返回可选的 Topic 实体

    private let topicRepository: TopicRepository // 依赖注入主题仓储

    /// 初始化查询处理器
    /// - Parameter topicRepository: 主题仓储的实例。
    init(topicRepository: TopicRepository) {
        self.topicRepository = topicRepository
    }

    /// 处理 `GetTopicByIdQuery` 查询。
    /// - Parameter query: 要处理的查询实例。
    /// - Returns: 找到的 `Topic` 实体实例，如果不存在则为 `nil`。
    /// - Throws: 持久化相关的错误。
    func handle(_ query: GetTopicByIdQuery) async throws -> Topic? {
        return try await topicRepository.find(by: query.topicId)
    }
}

/// 获取所有主题查询处理器
/// 负责处理 `GetAllTopicsQuery`，从仓储中获取所有主题。
struct GetAllTopicsQueryHandler: QueryHandler {
    typealias Q = GetAllTopicsQuery
    typealias R = [Topic] // 返回 Topic 实体数组

    private let topicRepository: TopicRepository

    init(topicRepository: TopicRepository) {
        self.topicRepository = topicRepository
    }

    func handle(_ query: GetAllTopicsQuery) async throws -> [Topic] {
        return try await topicRepository.findAll()
    }
}

/// 根据学科获取主题列表查询处理器
/// 负责处理 `GetTopicsBySubjectQuery`，根据指定学科获取主题。
struct GetTopicsBySubjectQueryHandler: QueryHandler {
    typealias Q = GetTopicsBySubjectQuery
    typealias R = [Topic]

    private let topicRepository: TopicRepository

    init(topicRepository: TopicRepository) {
        self.topicRepository = topicRepository
    }

    func handle(_ query: GetTopicsBySubjectQuery) async throws -> [Topic] {
        return try await topicRepository.find(by: query.subject)
    }
}

/// 搜索主题查询处理器
/// 负责处理 `SearchTopicsQuery`，根据搜索条件筛选主题。
struct SearchTopicsQueryHandler: QueryHandler {
    typealias Q = SearchTopicsQuery
    typealias R = [Topic]

    private let topicRepository: TopicRepository

    init(topicRepository: TopicRepository) {
        self.topicRepository = topicRepository
    }

    func handle(_ query: SearchTopicsQuery) async throws -> [Topic] {
        // 1. 获取所有主题或根据初步条件筛选
        var topics = try await topicRepository.findAll()

        // 2. 应用搜索词过滤
        if !query.searchTerm.isEmpty {
            let lowercasedSearchTerm = query.searchTerm.lowercased()
            topics = topics.filter { topic in
                topic.name.lowercased().contains(lowercasedSearchTerm) ||
                topic.description?.lowercased().contains(lowercasedSearchTerm) ?? false
            }
        }

        // 3. 应用学科过滤
        if let subject = query.subject {
            topics = topics.filter { $0.subject == subject }
        }

        return topics
    }
}

