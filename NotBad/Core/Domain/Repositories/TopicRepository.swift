//
//  TopicRepository.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesContentTopic // 包含 Topic (实体)
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
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
    private(set) var lastModifiedAt: Date

    init(id: UUID = UUID(), name: String, subject: Subject, description: String? = nil, createdAt: Date = Date(), lastModifiedAt: Date = Date()) {
        self.id = id; self.name = name; self.subject = subject; self.description = description; self.createdAt = createdAt; self.lastModifiedAt = lastModifiedAt
    }
    
    static func reconstruct(id: UUID, name: String, subject: Subject, description: String?, createdAt: Date, lastModifiedAt: Date) -> Topic {
        return Topic(id: id, name: name, subject: subject, description: description, createdAt: createdAt, lastModifiedAt: lastModifiedAt)
    }

    func updateName(newName: String) -> Topic {
        return Topic(id: id, name: newName, subject: subject, description: description, createdAt: createdAt, lastModifiedAt: Date())
    }

    func updateDescription(newDescription: String?) -> Topic {
        return Topic(id: id, name: name, subject: subject, description: newDescription, createdAt: createdAt, lastModifiedAt: Date())
    }
}

/// 学术领域错误 (仅为编译目的包含，实际应从 AcademicDomainError.swift 导入)
enum AcademicDomainError: Error, CustomStringConvertible, LocalizedError {
    case topicNotFound(UUID)
    case invalidTopicData(String)
    case subjectNotFoundForTopic(Subject)

    var description: String {
        switch self {
        case .topicNotFound(let id):
            return "主题ID '\(id.uuidString)' 未找到。"
        case .invalidTopicData(let reason):
            return "主题数据无效: \(reason)。"
        case .subjectNotFoundForTopic(let subject):
            return "学科 '\(subject.displayName)' 未找到，无法关联主题。"
        }
    }

    var errorDescription: String? {
        return description
    }
}


/// 主题仓储接口
/// 定义了对 `Topic` 实体进行持久化和检索的契约。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol TopicRepository: Sendable {

    /// 保存或更新一个 `Topic` 实体。
    /// 如果 `Topic` 已存在（通过其 ID 判断），则更新；否则，添加。
    /// - Parameter topic: 要保存或更新的 `Topic` 实体实例。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func save(_ topic: Topic) async throws

    /// 根据 ID 查找一个 `Topic` 实体。
    /// - Parameter id: 要查找的 `Topic` 的唯一标识符。
    /// - Returns: 找到的 `Topic` 实体实例，如果不存在则为 `nil`。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func find(by id: UUID) async throws -> Topic?

    /// 查找所有主题。
    /// - Returns: 所有 `Topic` 实体数组。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func findAll() async throws -> [Topic]

    /// 根据学科查找主题。
    /// - Parameter subject: 学科过滤。
    /// - Returns: 属于指定学科的所有 `Topic` 实体数组。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func find(by subject: Subject) async throws -> [Topic]

    /// 根据主题名称模糊查找主题。
    /// - Parameter name: 主题名称的模糊匹配字符串。
    /// - Returns: 名称包含指定字符串的所有 `Topic` 实体数组。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func find(byName name: String) async throws -> [Topic]

    /// 删除一个 `Topic` 实体。
    /// - Parameter topic: 要删除的 `Topic` 实体实例。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func delete(_ topic: Topic) async throws
}

