//
//  TopicManagementUseCase.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesContentTopic // 包含 Topic
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainErrorsQuestionDomainError // 包含 QuestionDomainError

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
    case invalidStateForOperation(String) // For Topic use case errors
    // ... other cases for compilation
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


/// 主题管理用例接口
/// 定义了与学习主题（Topic）的创建、修改、删除和查询相关的所有应用层功能。
/// 表现层将通过此接口与应用层进行交互，而无需了解底层命令和查询的实现细节。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol TopicManagementUseCase: Sendable {

    /// 创建一个新的学习主题。
    /// - Parameters:
    ///   - name: 主题名称。
    ///   - subject: 主题所属的学科。
    ///   - description: 主题描述，可选。
    /// - Returns: 新创建的主题的 ID。
    /// - Throws: `QuestionDomainError.topicAlreadyExists`, `QuestionDomainError.emptyTopicName`,
    ///           `QuestionDomainError.topicNameTooLong` 或其他相关错误。
    func createTopic(name: String, subject: Subject, description: String?) async throws -> UUID

    /// 更新现有主题的名称。
    /// - Parameters:
    ///   - topicId: 要更新的主题 ID。
    ///   - newName: 新的主题名称。
    /// - Throws: `QuestionDomainError.invalidStateForOperation` (如果主题未找到),
    ///           `QuestionDomainError.emptyTopicName`, `QuestionDomainError.topicNameTooLong`,
    ///           `QuestionDomainError.topicAlreadyExists` (如果新名称在同等学科下冲突)
    ///           或其他相关错误。
    func updateTopicName(topicId: UUID, newName: String) async throws

    /// 更新现有主题的描述。
    /// - Parameters:
    ///   - topicId: 要更新的主题 ID。
    ///   - newDescription: 新的主题描述，nil 表示清除。
    /// - Throws: `QuestionDomainError.invalidStateForOperation` (如果主题未找到)
    ///           或其他相关错误。
    func updateTopicDescription(topicId: UUID, newDescription: String?) async throws

    /// 删除一个学习主题。
    /// - Parameter topicId: 要删除的主题 ID。
    /// - Throws: `QuestionDomainError.invalidStateForOperation` (如果主题未找到)
    ///           或其他相关错误。
    func deleteTopic(topicId: UUID) async throws

    /// 根据 ID 获取一个学习主题的详情。
    /// - Parameter topicId: 要获取的主题 ID。
    /// - Returns: `Topic` 实体实例，如果不存在则为 `nil`。
    /// - Throws: 任何查询过程中可能发生的错误。
    func getTopic(by topicId: UUID) async throws -> Topic?

    /// 获取系统中所有学习主题的列表。
    /// - Returns: `Topic` 实体数组。
    /// - Throws: 任何查询过程中可能发生的错误。
    func getAllTopics() async throws -> [Topic]

    /// 获取特定学科下的学习主题列表。
    /// - Parameter subject: 要查询的学科。
    /// - Returns: `Topic` 实体数组。
    /// - Throws: 任何查询过程中可能发生的错误。
    func getTopics(by subject: Subject) async throws -> [Topic]

    /// 根据关键词搜索学习主题。
    /// - Parameters:
    ///   - searchTerm: 搜索关键词。
    ///   - subject: 可选的学科过滤。
    /// - Returns: 匹配的 `Topic` 实体数组。
    /// - Throws: 任何搜索过程中可能发生的错误。
    func searchTopics(searchTerm: String, subject: Subject?) async throws -> [Topic]
}

