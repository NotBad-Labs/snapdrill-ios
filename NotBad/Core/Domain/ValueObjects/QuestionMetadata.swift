//
//  QuestionMetadata.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesContentSubject
// import NotBadCoreDomainEntitiesContentDifficulty
// import NotBadCoreDomainEntitiesContentTag
// import NotBadCoreDomainErrors

/// 题目元数据值对象
/// 封装了题目的非核心业务数据，如学科、难度、标签、来源和创建时间。
/// 这是一个不可变的值对象，其修改方法返回新的实例。
struct QuestionMetadata: Codable, Sendable, Hashable {
    let subject: Subject // 题目所属的学科
    let difficulty: Difficulty // 题目的难度级别
    let tags: Set<Tag> // 题目的标签集合
    let source: String? // 题目来源（例如：教材、年份、出处）
    let createdAt: Date // 题目创建时间
    let explanation: String? // 题目级别的总解释或解析，可选

    /// 初始化 QuestionMetadata
    /// - Parameters:
    ///   - subject: 题目所属学科，默认为数学
    ///   - difficulty: 题目难度，默认为中等
    ///   - tags: 标签集合，默认为空
    ///   - source: 题目来源，可选
    ///   - createdAt: 创建时间，默认为当前时间
    ///   - explanation: 题目解释，可选
    init(
        subject: Subject = .mathematics,
        difficulty: Difficulty = .medium,
        tags: Set<Tag> = [],
        source: String? = nil,
        createdAt: Date = Date(),
        explanation: String? = nil
    ) {
        self.subject = subject
        self.difficulty = difficulty
        self.tags = tags
        self.source = source
        self.createdAt = createdAt
        self.explanation = explanation
    }

    /// 返回一个带有新难度的新 QuestionMetadata 实例
    /// - Parameter newDifficulty: 新的难度级别
    /// - Returns: 更新后的 QuestionMetadata 实例
    func withDifficulty(_ newDifficulty: Difficulty) -> QuestionMetadata {
        return QuestionMetadata(
            subject: subject,
            difficulty: newDifficulty,
            tags: tags,
            source: source,
            createdAt: createdAt,
            explanation: explanation
        )
    }

    /// 返回一个带有新标签的新 QuestionMetadata 实例
    /// - Parameter tag: 要添加的标签
    /// - Returns: 更新后的 QuestionMetadata 实例
    /// - Throws: QuestionDomainError 如果标签添加违反业务规则（例如标签冲突）
    func addTag(_ tag: Tag) throws -> QuestionMetadata {
        // 检查标签冲突：确保新标签不会与现有标签产生业务冲突
        for existingTag in tags {
            if existingTag.conflicts(with: tag) {
                throw QuestionDomainError.conflictingTags(existingTag, tag)
            }
        }

        var newTags = tags
        newTags.insert(tag) // 添加新标签

        return QuestionMetadata(
            subject: subject,
            difficulty: difficulty,
            tags: newTags,
            source: source,
            createdAt: createdAt,
            explanation: explanation
        )
    }

    /// 返回一个移除标签的新 QuestionMetadata 实例
    /// - Parameter tag: 要移除的标签
    /// - Returns: 更新后的 QuestionMetadata 实例
    func removeTag(_ tag: Tag) -> QuestionMetadata {
        var newTags = tags
        newTags.remove(tag) // 移除标签

        return QuestionMetadata(
            subject: subject,
            difficulty: difficulty,
            tags: newTags,
            source: source,
            createdAt: createdAt,
            explanation: explanation
        )
    }

    /// 检查是否包含特定标签
    /// - Parameter tag: 要检查的标签
    /// - Returns: 如果包含该标签则为 true，否则为 false
    func hasTag(_ tag: Tag) -> Bool {
        tags.contains(tag)
    }
}

