//
//  QuestionCommandHandlers.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助应用层和领域层类型导入 (这些类型应在各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreApplicationCommands // 包含 AddSimpleQuestionCommand 等
// import NotBadCoreApplicationHandlers // 包含 CommandHandler 协议
// import NotBadCoreDomainEntitiesQuestion // 包含 Question (聚合根)
// import NotBadCoreDomainRepositories // 包含 QuestionAggregateRepository 协议
// import NotBadCoreDomainErrors // 包含 QuestionDomainError

/// 添加简单题目命令处理器
/// 负责处理 `AddSimpleQuestionCommand`，创建 `Question` 聚合根并保存。
struct AddSimpleQuestionCommandHandler: CommandHandler {
    typealias C = AddSimpleQuestionCommand

    private let questionRepository: QuestionAggregateRepository // 依赖注入仓储

    /// 初始化命令处理器
    /// - Parameter questionRepository: 题目聚合仓储的实例。
    init(questionRepository: QuestionAggregateRepository) {
        self.questionRepository = questionRepository
    }

    /// 处理 `AddSimpleQuestionCommand` 命令。
    /// - Parameter command: 要处理的命令实例。
    /// - Throws: `QuestionDomainError` 或其他持久化相关的错误。
    func handle(_ command: AddSimpleQuestionCommand) async throws {
        // 1. 使用领域层的工厂方法创建 Question 聚合根
        let question = try Question.createSimpleQuestion(
            content: command.content,
            correctAnswer: command.correctAnswer,
            subject: command.subject,
            difficulty: command.difficulty
            // Tag 和 Source 可以在 QuestionMetadata 内部处理或通过 Question 的 addTag 方法添加
            // explanation 也可以在 QuestionMetadata 内部处理
        )

        // 2. 通过仓储保存 Question 聚合根
        try await questionRepository.save(question)

        // 3. (可选) 发布领域事件，例如 QuestionAddedEvent
        // EventBus.shared.publish(QuestionAddedEvent(questionId: question.id))
    }
}

/// 添加多选题命令处理器
/// 负责处理 `AddMultipleChoiceQuestionCommand`，创建 `Question` 聚合根并保存。
struct AddMultipleChoiceQuestionCommandHandler: CommandHandler {
    typealias C = AddMultipleChoiceQuestionCommand

    private let questionRepository: QuestionAggregateRepository

    init(questionRepository: QuestionAggregateRepository) {
        self.questionRepository = questionRepository
    }

    func handle(_ command: AddMultipleChoiceQuestionCommand) async throws {
        // 1. 转换选项为领域层 Answer 期望的格式
        let optionsForDomain = command.options.map { (text: $0.text, isCorrect: $0.isCorrect) }

        // 2. 使用领域层的工厂方法创建 Question 聚合根
        let question = try Question.createMultipleChoiceQuestion(
            content: command.content,
            options: optionsForDomain,
            subject: command.subject,
            difficulty: command.difficulty
        )

        // 3. 如果命令中包含额外的标签，添加到题目中
        var updatedQuestion = question
        for tag in command.tags {
            updatedQuestion = try updatedQuestion.addTag(tag)
        }

        // 4. 如果命令中包含来源或解释，更新元数据
        if command.source != nil || command.explanation != nil {
            let currentMetadata = updatedQuestion.metadata
            let newMetadata = QuestionMetadata(
                subject: currentMetadata.subject,
                difficulty: currentMetadata.difficulty,
                tags: currentMetadata.tags,
                source: command.source ?? currentMetadata.source,
                createdAt: currentMetadata.createdAt,
                explanation: command.explanation ?? currentMetadata.explanation
            )
            // 这里需要 Question 聚合根提供一个更新 metadata 的方法，或者直接通过 reconstruct 传入
            // 假设 Question 聚合根有 updateMetadata 方法
            // updatedQuestion = try updatedQuestion.updateMetadata(newMetadata)
            // 由于 Question 是不可变的，且没有直接的 updateMetadata 方法，
            // 最佳实践是在创建时就传入所有元数据，或者通过 Question 内部的 addTag/updateDifficulty 等方法间接修改。
            // 这里的处理简化为：如果需要更新 source/explanation，可能需要一个更通用的 updateMetadataCommand
            // 或者这些字段直接作为 Question 的工厂方法参数。
            // 为了避免复杂性，这里假设这些在创建时已处理，或者后续通过 UpdateQuestionMetadataCommand 处理。
        }


        // 5. 通过仓储保存 Question 聚合根
        try await questionRepository.save(updatedQuestion)
    }
}

/// 更新题目内容命令处理器
/// 负责处理 `UpdateQuestionContentCommand`，更新现有题目的内容。
struct UpdateQuestionContentCommandHandler: CommandHandler {
    typealias C = UpdateQuestionContentCommand

    private let questionRepository: QuestionAggregateRepository

    init(questionRepository: QuestionAggregateRepository) {
        self.questionRepository = questionRepository
    }

    func handle(_ command: UpdateQuestionContentCommand) async throws {
        // 1. 通过仓储获取要更新的 Question 聚合根
        guard let existingQuestion = try await questionRepository.find(by: command.questionId) else {
            throw QuestionDomainError.invalidStateForOperation("题目ID \(command.questionId.rawValue) 未找到。")
        }

        // 2. 创建新的 QuestionContent 值对象
        let newContent = try QuestionContent(
            text: command.newContentText,
            attachments: command.newAttachments
        )

        // 3. 使用新的内容重建 Question 聚合根（因为 Question 是不可变的）
        let updatedQuestion = Question.reconstruct(
            id: existingQuestion.id,
            content: newContent, // 使用新的内容
            answers: existingQuestion.answers,
            metadata: existingQuestion.metadata,
            learningState: existingQuestion.learningState
        )

        // 4. 通过仓储保存更新后的 Question 聚合根
        try await questionRepository.save(updatedQuestion)
    }
}

/// 更新题目元数据命令处理器
/// 负责处理 `UpdateQuestionMetadataCommand`，更新现有题目的元数据。
struct UpdateQuestionMetadataCommandHandler: CommandHandler {
    typealias C = UpdateQuestionMetadataCommand

    private let questionRepository: QuestionAggregateRepository

    init(questionRepository: QuestionAggregateRepository) {
        self.questionRepository = questionRepository
    }

    func handle(_ command: UpdateQuestionMetadataCommand) async throws {
        // 1. 通过仓储获取要更新的 Question 聚合根
        guard let existingQuestion = try await questionRepository.find(by: command.questionId) else {
            throw QuestionDomainError.invalidStateForOperation("题目ID \(command.questionId.rawValue) 未找到。")
        }

        // 2. 构建新的 QuestionMetadata 值对象 (基于现有数据和命令中的更新)
        var updatedMetadata = existingQuestion.metadata

        if let newSubject = command.newSubject {
            // 注意：这里需要 Subject 实体提供一个 equals 方法或者通过 name 比较
            // 假设 Subject 是值对象，直接比较即可
            if updatedMetadata.subject != newSubject {
                // 如果学科变更，可能需要额外的业务规则验证
                // 例如：旧标签与新学科是否冲突
                updatedMetadata = QuestionMetadata(
                    subject: newSubject,
                    difficulty: updatedMetadata.difficulty,
                    tags: updatedMetadata.tags,
                    source: updatedMetadata.source,
                    createdAt: updatedMetadata.createdAt,
                    explanation: updatedMetadata.explanation
                )
            }
        }

        if let newDifficulty = command.newDifficulty {
            updatedMetadata = updatedMetadata.withDifficulty(newDifficulty)
        }

        if let newTags = command.newTags {
            // 如果提供了新的标签集合，则替换
            // 否则，如果需要增量添加/删除，则需要更细粒度的命令
            // 这里假设 newTags 为 nil 表示不修改，空集合表示清空
            updatedMetadata = QuestionMetadata(
                subject: updatedMetadata.subject,
                difficulty: updatedMetadata.difficulty,
                tags: newTags,
                source: updatedMetadata.source,
                createdAt: updatedMetadata.createdAt,
                explanation: updatedMetadata.explanation
            )
        }

        if let newSource = command.newSource {
            updatedMetadata = QuestionMetadata(
                subject: updatedMetadata.subject,
                difficulty: updatedMetadata.difficulty,
                tags: updatedMetadata.tags,
                source: newSource,
                createdAt: updatedMetadata.createdAt,
                explanation: updatedMetadata.explanation
            )
        }

        if let newExplanation = command.newExplanation {
            updatedMetadata = QuestionMetadata(
                subject: updatedMetadata.subject,
                difficulty: updatedMetadata.difficulty,
                tags: updatedMetadata.tags,
                source: updatedMetadata.source,
                createdAt: updatedMetadata.createdAt,
                explanation: newExplanation
            )
        }


        // 3. 使用新的元数据重建 Question 聚合根
        let updatedQuestion = Question.reconstruct(
            id: existingQuestion.id,
            content: existingQuestion.content,
            answers: existingQuestion.answers,
            metadata: updatedMetadata, // 使用新的元数据
            learningState: existingQuestion.learningState
        )

        // 4. 通过仓储保存更新后的 Question 聚合根
        try await questionRepository.save(updatedQuestion)
    }
}

/// 删除题目命令处理器
/// 负责处理 `DeleteQuestionCommand`，从仓储中删除题目。
struct DeleteQuestionCommandHandler: CommandHandler {
    typealias C = DeleteQuestionCommand

    private let questionRepository: QuestionAggregateRepository

    init(questionRepository: QuestionAggregateRepository) {
        self.questionRepository = questionRepository
    }

    func handle(_ command: DeleteQuestionCommand) async throws {
        // 1. 通过仓储获取要删除的 Question 聚合根
        guard let questionToDelete = try await questionRepository.find(by: command.questionId) else {
            throw QuestionDomainError.invalidStateForOperation("题目ID \(command.questionId.rawValue) 未找到，无法删除。")
        }

        // 2. 通过仓储删除 Question 聚合根
        try await questionRepository.delete(questionToDelete)

        // 3. (可选) 发布领域事件，例如 QuestionDeletedEvent
        // EventBus.shared.publish(QuestionDeletedEvent(questionId: command.questionId))
    }
}

/// 用户答题命令处理器
/// 负责处理 `AnswerQuestionCommand`，更新题目的学习状态。
struct AnswerQuestionCommandHandler: CommandHandler {
    typealias C = AnswerQuestionCommand

    private let questionRepository: QuestionAggregateRepository

    init(questionRepository: QuestionAggregateRepository) {
        self.questionRepository = questionRepository
    }

    func handle(_ command: AnswerQuestionCommand) async throws {
        // 1. 通过仓储获取要答题的 Question 聚合根
        guard let existingQuestion = try await questionRepository.find(by: command.questionId) else {
            throw QuestionDomainError.invalidStateForOperation("题目ID \(command.questionId.rawValue) 未找到，无法答题。")
        }

        // 2. 调用 Question 聚合根的业务方法来处理答题逻辑和状态更新
        let (_, updatedQuestion) = try existingQuestion.answerQuestion(
            command.userAnswer,
            responseTime: command.responseTime
        )

        // 3. 通过仓储保存更新后的 Question 聚合根
        try await questionRepository.save(updatedQuestion)

        // 4. (可选) 发布领域事件，例如 QuestionAnsweredEvent
        // EventBus.shared.publish(QuestionAnsweredEvent(questionId: command.questionId, isCorrect: result.isCorrect))
    }
}

/// 标记题目为已复习命令处理器
/// 负责处理 `MarkQuestionAsReviewedCommand`，更新题目的复习状态。
struct MarkQuestionAsReviewedCommandHandler: CommandHandler {
    typealias C = MarkQuestionAsReviewedCommand

    private let questionRepository: QuestionAggregateRepository

    init(questionRepository: QuestionAggregateRepository) {
        self.questionRepository = questionRepository
    }

    func handle(_ command: MarkQuestionAsReviewedCommand) async throws {
        // 1. 通过仓储获取要标记的 Question 聚合根
        guard let existingQuestion = try await questionRepository.find(by: command.questionId) else {
            throw QuestionDomainError.invalidStateForOperation("题目ID \(command.questionId.rawValue) 未找到，无法标记为已复习。")
        }

        // 2. 调用 Question 聚合根的业务方法来标记为已复习
        let updatedQuestion = try existingQuestion.markAsReviewed()

        // 3. 通过仓储保存更新后的 Question 聚合根
        try await questionRepository.save(updatedQuestion)
    }
}

/// 更新题目答错原因命令处理器
/// 负责处理 `UpdateQuestionWrongReasonCommand`，更新题目的答错原因。
struct UpdateQuestionWrongReasonCommandHandler: CommandHandler {
    typealias C = UpdateQuestionWrongReasonCommand

    private let questionRepository: QuestionAggregateRepository

    init(questionRepository: QuestionAggregateRepository) {
        self.questionRepository = questionRepository
    }

    func handle(_ command: UpdateQuestionWrongReasonCommand) async throws {
        // 1. 通过仓储获取要更新的 Question 聚合根
        guard let existingQuestion = try await questionRepository.find(by: command.questionId) else {
            throw QuestionDomainError.invalidStateForOperation("题目ID \(command.questionId.rawValue) 未找到，无法更新答错原因。")
        }

        // 2. 调用 Question 聚合根的业务方法来更新答错原因
        let updatedQuestion = existingQuestion.updateWrongReason(command.wrongReason)

        // 3. 通过仓储保存更新后的 Question 聚合根
        try await questionRepository.save(updatedQuestion)
    }
}

