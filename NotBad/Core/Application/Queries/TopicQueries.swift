//
//  TopicQueries.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesContentTopic // 包含 Topic
// import NotBadCoreApplicationQueries // 包含 Query 协议

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

/// 查询协议 (仅为编译目的包含，实际应从 Query.swift 导入)
// Note: In a real project, this would be in its own file: Core/Application/Queries/Query.swift
protocol Query: Hashable, Sendable { }


/// 主题查询：根据ID获取主题
/// 用于通过唯一标识符获取单个主题。
/// 遵循 `Query` 协议。
struct GetTopicByIdQuery: Query {
    let topicId: UUID // 要查询的主题ID

    // Hashable 和 Equatable 协议的自动实现
}

/// 主题查询：获取所有主题
/// 用于获取系统中所有主题的列表。
/// 遵循 `Query` 协议。
struct GetAllTopicsQuery: Query {
    // 此查询无需额外参数
    // Hashable 和 Equatable 协议的自动实现
}

/// 主题查询：根据学科获取主题列表
/// 用于获取特定学科下的主题列表。
/// 遵循 `Query` 协议。
struct GetTopicsBySubjectQuery: Query {
    let subject: Subject // 要查询的学科

    // Hashable 和 Equatable 协议的自动实现
}

/// 主题查询：搜索主题
/// 用于根据关键词搜索主题。
/// 遵循 `Query` 协议。
struct SearchTopicsQuery: Query {
    let searchTerm: String // 搜索关键词
    let subject: Subject? // 可选的学科过滤

    // Hashable 和 Equatable 协议的自动实现
}

