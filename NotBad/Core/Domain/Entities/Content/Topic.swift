//
//  Topic.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainErrors // 包含 QuestionDomainError (或更通用的 DomainError)

/// 题目领域错误 (仅为编译目的包含，实际应从 Core/Domain/Errors 导入)
// Note: In a real project, this would be in its own file: Core/Domain/Errors/QuestionDomainError.swift
enum QuestionDomainError: Error, CustomStringConvertible, LocalizedError {
    case emptyContent
    case contentTooLong
    case noAnswers
    case noCorrectAnswers
    case noAnswerOptions
    case emptyAnswer
    case emptyTag
    case tooLongTag(Int)
    case invalidTagCharacters
    case duplicateTag
    case conflictingTags(Tag, Tag)

    case cannotReduceDifficultyForMasteredQuestion
    case cannotReviewUnatttemptedQuestion
    case tooManyAttemptsForMasteredQuestion
    case inconsistentSubjectAndTags(subject: Subject, tag: Tag)
    case invalidStateForOperation(String)

    case emptySubjectName
    case subjectNameTooLong(String)
    case duplicateCoreSubject(String)
    case unknownCoreSubject(String)

    // MARK: - Topic 相关的验证错误
    case emptyTopicName
    case topicNameTooLong(String)
    case topicAlreadyExists(String, Subject) // 主题在特定学科下已存在

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
        case .tooLongTag(let count):
            return "标签太长（\(count)个字符），最多20个字符。"
        case .invalidTagCharacters:
            return "标签包含无效字符。"
        case .duplicateTag:
            return "标签已存在。"
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
        case .emptySubjectName:
            return "学科名称不能为空。"
        case .subjectNameTooLong(let name):
            return "学科名称太长: '\(name)'（最多10个字符）。"
        case .duplicateCoreSubject(let name):
            return "不能创建与核心学科重复的自定义学科: '\(name)'。"
        case .unknownCoreSubject(let name):
            return "未知的核心学科名称: '\(name)'。"
        case .emptyTopicName:
            return "主题名称不能为空。"
        case .topicNameTooLong(let name):
            return "主题名称太长: '\(name)'（最多50个字符）。"
        case .topicAlreadyExists(let name, let subject):
            return "主题 '\(name)' 在学科 '\(subject.displayName)' 下已存在。"
        }
    }

    var errorDescription: String? {
        return description
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


/// 主题/章节领域实体
/// 代表学科下的一个具体学习主题或章节。
/// 这是一个实体，因为它具有唯一标识和生命周期，且其属性可以随时间变化。
struct Topic: Identifiable, Hashable, Codable, Sendable {
    let id: UUID // 主题的唯一标识符
    let name: String // 主题名称
    let subject: Subject // 所属学科
    let description: String? // 主题描述，可选
    let createdAt: Date // 创建时间
    let lastModifiedAt: Date // 最后修改时间

    /// 初始化 Topic 实体
    /// - Parameters:
    ///   - id: 主题的唯一标识符，默认为新的UUID
    ///   - name: 主题名称
    ///   - subject: 所属学科
    ///   - description: 主题描述，可选
    ///   - createdAt: 创建时间，默认为当前时间
    ///   - lastModifiedAt: 最后修改时间，默认为当前时间
    /// - Throws: QuestionDomainError 如果主题名称无效
    init(
        id: UUID = UUID(),
        name: String,
        subject: Subject,
        description: String? = nil,
        createdAt: Date = Date(),
        lastModifiedAt: Date = Date()
    ) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // 验证：主题名称不能为空
        guard !trimmedName.isEmpty else {
            throw QuestionDomainError.emptyTopicName
        }
        // 验证：主题名称长度限制
        guard trimmedName.count <= 50 else { // 示例：主题名称最多50个字符
            throw QuestionDomainError.topicNameTooLong(trimmedName)
        }

        self.id = id
        self.name = trimmedName
        self.subject = subject
        self.description = description
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
    }

    /// 更新主题名称
    /// - Parameter newName: 新的主题名称
    /// - Returns: 更新后的 Topic 实体新实例
    /// - Throws: QuestionDomainError 如果新名称无效
    func updateName(_ newName: String) throws -> Topic {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw QuestionDomainError.emptyTopicName
        }
        guard trimmedName.count <= 50 else {
            throw QuestionDomainError.topicNameTooLong(trimmedName)
        }

        // 返回新的实例，体现不可变性
        return Topic(
            id: id,
            name: trimmedName,
            subject: subject,
            description: description,
            createdAt: createdAt,
            lastModifiedAt: Date() // 更新修改时间
        )
    }

    /// 更新主题描述
    /// - Parameter newDescription: 新的主题描述，nil 表示清除
    /// - Returns: 更新后的 Topic 实体新实例
    func updateDescription(_ newDescription: String?) -> Topic {
        // 返回新的实例，体现不可变性
        return Topic(
            id: id,
            name: name,
            subject: subject,
            description: newDescription,
            createdAt: createdAt,
            lastModifiedAt: Date() // 更新修改时间
        )
    }

    // MARK: - 静态工厂方法 (用于从外部数据重建或创建)

    /// 从外部数据重建 Topic 实体（用于Repository）
    /// - Parameters:
    ///   - id: 主题ID
    ///   - name: 主题名称
    ///   - subject: 所属学科
    ///   - description: 描述
    ///   - createdAt: 创建时间
    ///   - lastModifiedAt: 最后修改时间
    /// - Returns: 重建的 Topic 实体实例
    static func reconstruct(
        id: UUID,
        name: String,
        subject: Subject,
        description: String?,
        createdAt: Date,
        lastModifiedAt: Date
    ) -> Topic {
        // 重建方法不进行业务验证，假设传入数据已是有效状态
        // 这里的 try! 是为了简化，实际应确保所有参数都是有效的
        return try! Topic(
            id: id,
            name: name,
            subject: subject,
            description: description,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
    }
}

