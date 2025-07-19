//
//  AnswerCollection.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (假设这些类型已在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要添加具体的 import 语句。
// import NotBadCoreDomainErrors // 包含 QuestionDomainError
// import NotBadCoreDomainValueObjectsAnswer // 包含 Answer

/// 单个答案值对象
/// 代表一个题目的单个答案选项，包含答案文本、是否正确以及可选的解释。
/// 这是一个不可变的值对象，内部包含自验证逻辑。
// Note: In a real project, this would be in its own file: Core/Domain/ValueObjects/Answer.swift
struct Answer: Codable, Sendable, Hashable {
    let text: String // 答案的文本内容
    let isCorrect: Bool // 标识此答案是否为正确答案
    let explanation: String? // 对此答案的解释或解析，可选

    /// 初始化 Answer
    /// - Parameters:
    ///   - text: 答案的文本内容
    ///   - isCorrect: 布尔值，表示此答案是否为正确答案
    ///   - explanation: 对此答案的解释，可选
    /// - Throws: QuestionDomainError 如果答案文本为空
    init(text: String, isCorrect: Bool, explanation: String? = nil) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw QuestionDomainError.emptyAnswer // 验证：答案文本不能为空
        }

        self.text = trimmed
        self.isCorrect = isCorrect
        self.explanation = explanation
    }

    /// 检查用户输入是否与此答案匹配
    /// 执行不区分大小写和去除首尾空格的匹配。
    /// - Parameter userInput: 用户提供的答案字符串
    /// - Returns: 如果用户输入与此答案的文本匹配则为 true，否则为 false
    func matches(_ userInput: String) -> Bool {
        let normalizedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedInput = userInput.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return normalizedText == normalizedInput
    }
}

/// 题目领域错误
// Note: In a real project, this would be in its own file: Core/Domain/Errors/QuestionDomainError.swift
enum QuestionDomainError: Error, CustomStringConvertible, LocalizedError {
    case emptyContent
    case contentTooLong
    case noAnswers
    case noCorrectAnswers
    case noAnswerOptions
    case emptyAnswer
    case emptyTag
    case conflictingTags(Tag, Tag) // Assuming Tag is defined elsewhere
    case cannotReduceDifficultyForMasteredQuestion
    case cannotReviewUnatttemptedQuestion
    case tooManyAttemptsForMasteredQuestion
    case inconsistentSubjectAndTags(subject: Subject, tag: Tag) // Assuming Subject and Tag are defined elsewhere
    case invalidStateForOperation(String) // 更通用的状态错误

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
        }
    }

    var errorDescription: String? {
        return description
    }
}

/// 答案集合值对象
/// 封装了题目的所有答案选项，并提供对答案集合的验证和检查逻辑。
/// 这是一个不可变的值对象，确保答案集合的完整性和一致性。
struct AnswerCollection: Codable, Sendable, Hashable {
    private let answers: [Answer] // 内部存储的答案列表

    /// 初始化 AnswerCollection，用于只有正确答案的情况（如填空题）
    /// - Parameter correctAnswers: 正确答案的文本数组
    /// - Throws: QuestionDomainError 如果正确答案数组为空
    init(correctAnswers: [String]) throws {
        guard !correctAnswers.isEmpty else {
            throw QuestionDomainError.noCorrectAnswers // 验证：必须提供正确答案
        }

        self.answers = try correctAnswers.map { text in
            try Answer(text: text, isCorrect: true) // 创建正确的 Answer 实例
        }
    }

    /// 初始化 AnswerCollection，用于包含多个选项的情况（如选择题）
    /// - Parameter options: 包含答案文本和正确性标记的元组数组
    /// - Throws: QuestionDomainError 如果选项数组为空或没有正确答案
    init(options: [(text: String, isCorrect: Bool)]) throws {
        guard !options.isEmpty else {
            throw QuestionDomainError.noAnswerOptions // 验证：必须提供答案选项
        }

        let correctCount = options.filter { $0.isCorrect }.count
        guard correctCount > 0 else {
            throw QuestionDomainError.noCorrectAnswers // 验证：必须至少有一个正确答案
        }

        self.answers = try options.map { option in
            try Answer(text: option.text, isCorrect: option.isCorrect) // 创建 Answer 实例
        }
    }

    /// 判断答案集合是否包含任何正确答案
    var hasCorrectAnswers: Bool {
        answers.contains { $0.isCorrect }
    }

    /// 获取所有正确答案的列表
    var correctAnswers: [Answer] {
        answers.filter { $0.isCorrect }
    }

    /// 获取所有答案的列表（包括正确和错误选项）
    var allAnswers: [Answer] { answers }

    /// 检查用户答案是否与答案集合中的任何正确答案匹配
    /// - Parameter userAnswer: 用户提供的答案字符串
    /// - Returns: 包含检查结果的 AnswerResult 值对象
    func check(_ userAnswer: String) -> AnswerResult {
        let normalizedUserAnswer = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines)

        // 检查用户答案是否与任何一个正确答案匹配
        let isCorrect = correctAnswers.contains { answer in
            answer.matches(normalizedUserAnswer)
        }

        return AnswerResult(
            userAnswer: normalizedUserAnswer,
            isCorrect: isCorrect,
            correctAnswers: correctAnswers.map { $0.text },
            explanation: correctAnswers.first?.explanation // 假设只取第一个正确答案的解释作为总解释
        )
    }
}

