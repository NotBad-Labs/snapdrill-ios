//
//  QuestionDomainError.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesContentTag // 包含 Tag
// import NotBadCoreDomainErrorsDomainError // 包含 DomainError

/// 题目领域错误
/// 定义了所有与题目相关的业务逻辑错误。
/// 遵循 `DomainError` 协议，以便提供统一的错误描述和本地化支持。
enum QuestionDomainError: DomainError {
    // MARK: - 题目内容与格式错误
    case emptyContent // 题目内容为空
    case contentTooLong // 题目内容过长
    case invalidContentFormat(String) // 题目内容格式无效，包含具体原因

    // MARK: - 答案相关错误
    case noAnswers // 题目必须有答案
    case noCorrectAnswers // 题目必须有正确答案
    case noAnswerOptions // 多选题必须提供选项
    case emptyAnswer // 答案内容为空
    case invalidAnswerFormat(String) // 答案格式无效，包含具体原因

    // MARK: - 标签相关错误
    case emptyTag // 标签内容为空
    case tooLongTag(Int) // 标签太长，包含实际长度
    case invalidTagCharacters // 标签包含无效字符
    case duplicateTag // 标签已存在（在集合中添加时）
    case conflictingTags(Tag, Tag) // 标签冲突，包含冲突的两个标签

    // MARK: - 学习状态与业务规则错误
    case cannotReduceDifficultyForMasteredQuestion // 已掌握的题目不能随意降低难度
    case cannotReviewUnatttemptedQuestion // 未曾尝试过的题目不能标记为已复习
    case tooManyAttemptsForMasteredQuestion // 已掌握的题目当天尝试次数过多
    case inconsistentSubjectAndTags(subject: Subject, tag: Tag) // 学科与标签不一致
    case invalidStateForOperation(String) // 当前题目状态不允许执行操作，包含具体操作描述

    // MARK: - 主题相关错误 (如果 Topic 被认为是 Question 领域的一部分)
    case emptyTopicName // 主题名称为空
    case topicNameTooLong(String) // 主题名称过长
    case topicAlreadyExists(String, Subject) // 主题在特定学科下已存在

    // MARK: - 通用题目相关错误
    case questionNotFound // 题目未找到
    case genericQuestionError(String) // 通用题目错误，包含具体消息

    // MARK: - CustomStringConvertible 协议实现
    /// 提供错误的字符串描述，用于日志或调试。
    var description: String {
        switch self {
        case .emptyContent:
            return "题目内容不能为空。"
        case .contentTooLong:
            return "题目内容过长，请精简。"
        case .invalidContentFormat(let reason):
            return "题目内容格式无效: \(reason)。"
        case .noAnswers:
            return "题目必须有答案。"
        case .noCorrectAnswers:
            return "题目必须有正确答案。"
        case .noAnswerOptions:
            return "多选题必须提供选项。"
        case .emptyAnswer:
            return "答案内容不能为空。"
        case .invalidAnswerFormat(let reason):
            return "答案格式无效: \(reason)。"
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
        case .emptyTopicName:
            return "主题名称不能为空。"
        case .topicNameTooLong(let name):
            return "主题名称太长: '\(name)'（最多50个字符）。"
        case .topicAlreadyExists(let name, let subject):
            return "主题 '\(name)' 在学科 '\(subject.displayName)' 下已存在。"
        case .questionNotFound:
            return "题目未找到。"
        case .genericQuestionError(let message):
            return "发生通用题目错误: \(message)。"
        }
    }

    // MARK: - LocalizedError 协议实现
    /// 提供错误的本地化描述，用于向用户展示。
    var errorDescription: String? {
        // 在实际应用中，这里会通过本地化字符串表获取对应的本地化消息。
        // 例如：NSLocalizedString("emptyContent", comment: "题目内容不能为空")
        return description // 暂时直接返回 description
    }
}

// MARK: - 辅助类型 (为了编译，实际应从其他文件导入)
// 这些类型在实际项目中应有自己的文件，这里仅为编译目的提供简化定义。

/// 学科枚举 (简化版)
enum Subject: String, CaseIterable, Codable, Sendable, Hashable {
    case mathematics = "数学"
    case physics = "物理"
    case general = "综合"
    var displayName: String { rawValue }
    static func findCoreSubject(byName name: String) -> Subject? { return Subject.allCases.first(where: { $0.rawValue == name }) }
}

/// 标签值对象 (简化版)
struct Tag: Codable, Hashable, Sendable {
    let value: String
    let type: TagType
    enum TagType: String, Codable, Sendable { case subject, custom, exam }
    init(_ value: String, type: TagType = .custom) throws { self.value = value; self.type = type }
    var displayName: String { value } // 简化
}

