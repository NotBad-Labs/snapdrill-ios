//
//  QuestionCommands.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesContentDifficulty // 包含 Difficulty
// import NotBadCoreDomainEntitiesContentTag // 包含 Tag
// import NotBadCoreDomainValueObjectsQuestionAttachment // 包含 QuestionAttachment
// import NotBadCoreDomainValueObjectsAnswer // 包含 Answer
// import NotBadCoreDomainValueObjectsIdentityQuestionID // 包含 QuestionID
// import NotBadCoreApplicationCommands // 包含 Command 协议

/// 题目命令：添加简单题目
/// 用于向系统添加一个只包含文本内容和单个正确答案的题目。
/// 遵循 `Command` 协议。
struct AddSimpleQuestionCommand: Command {
    let content: String // 题目文本内容
    let correctAnswer: String // 正确答案文本
    let subject: Subject // 所属学科
    let difficulty: Difficulty // 难度级别
    let tags: Set<Tag> // 标签集合，可选
    let source: String? // 题目来源，可选
    let explanation: String? // 题目级别的总解释，可选

    // Hashable 和 Equatable 协议的自动实现，因为所有属性都遵循这些协议
}

/// 题目命令：添加多选题
/// 用于向系统添加一个包含多个选项和多个正确答案的题目。
/// 遵循 `Command` 协议。
struct AddMultipleChoiceQuestionCommand: Command {
    let content: String // 题目文本内容
    let options: [(text: String, isCorrect: Bool, explanation: String?)] // 选项列表 (文本, 是否正确, 解释)
    let subject: Subject // 所属学科
    let difficulty: Difficulty // 难度级别
    let tags: Set<Tag> // 标签集合，可选
    let source: String? // 题目来源，可选
    let explanation: String? // 题目级别的总解释，可选

    // Hashable 和 Equatable 协议的自动实现
}

/// 题目命令：更新题目内容
/// 用于修改现有题目的文本内容和附件。
/// 遵循 `Command` 协议。
struct UpdateQuestionContentCommand: Command {
    let questionId: QuestionID // 要更新的题目ID
    let newContentText: String // 新的题目文本内容
    let newAttachments: [QuestionAttachment] // 新的附件列表

    // Hashable 和 Equatable 协议的自动实现
}

/// 题目命令：更新题目元数据
/// 用于修改现有题目的学科、难度、标签、来源和总解释。
/// 遵循 `Command` 协议。
struct UpdateQuestionMetadataCommand: Command {
    let questionId: QuestionID // 要更新的题目ID
    let newSubject: Subject? // 新的学科，可选
    let newDifficulty: Difficulty? // 新的难度，可选
    let newTags: Set<Tag>? // 新的标签集合，可选 (nil 表示不修改，空集合表示清空)
    let newSource: String? // 新的来源，可选
    let newExplanation: String? // 新的题目总解释，可选

    // Hashable 和 Equatable 协议的自动实现
}

/// 题目命令：删除题目
/// 用于从系统中删除一个题目。
/// 遵循 `Command` 协议。
struct DeleteQuestionCommand: Command {
    let questionId: QuestionID // 要删除的题目ID

    // Hashable 和 Equatable 协议的自动实现
}

/// 题目命令：用户答题
/// 用于记录用户对某个题目的答题尝试。
/// 遵循 `Command` 协议。
struct AnswerQuestionCommand: Command {
    let questionId: QuestionID // 答题的题目ID
    let userAnswer: String // 用户提交的答案
    let responseTime: TimeInterval // 答题响应时间（秒）

    // Hashable 和 Equatable 协议的自动实现
}

/// 题目命令：标记题目为已复习
/// 用于将某个题目标记为已复习，更新其学习状态。
/// 遵循 `Command` 协议。
struct MarkQuestionAsReviewedCommand: Command {
    let questionId: QuestionID // 要标记的题目ID

    // Hashable 和 Equatable 协议的自动实现
}

/// 题目命令：更新题目答错原因
/// 用于记录用户答错某个题目的具体原因。
/// 遵循 `Command` 协议。
struct UpdateQuestionWrongReasonCommand: Command {
    let questionId: QuestionID // 要更新的题目ID
    let wrongReason: String? // 答错原因描述，nil 表示清除

    // Hashable 和 Equatable 协议的自动实现
}

