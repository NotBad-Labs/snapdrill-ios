//
//  Answer.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//


//
//  Answer.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (假设这些类型已在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要添加具体的 import 语句。
// import NotBadCoreDomainErrors // 包含 QuestionDomainError

/// 单个答案值对象
/// 代表一个题目的单个答案选项，包含答案文本、是否正确以及可选的解释。
/// 这是一个不可变的值对象，内部包含自验证逻辑。
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
