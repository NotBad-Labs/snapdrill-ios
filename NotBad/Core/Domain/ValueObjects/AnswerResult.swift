//
//  AnswerResult.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

/// 答题结果值对象
/// 封装了学习者一次答题尝试的结果，包括用户的答案、是否正确、正确答案列表和可选的解释。
/// 这是一个不可变的值对象，用于清晰地表示答题的即时反馈。
struct AnswerResult: Codable, Sendable, Hashable {
    let userAnswer: String // 学习者提交的答案
    let isCorrect: Bool // 答题是否正确
    let correctAnswers: [String] // 所有正确的答案文本列表
    let explanation: String? // 对此题目的解释或解析，可选
    let timestamp: Date // 记录答题结果的时间

    /// 初始化 AnswerResult
    /// - Parameters:
    ///   - userAnswer: 学习者提交的答案
    ///   - isCorrect: 答题是否正确
    ///   - correctAnswers: 正确答案的文本数组
    ///   - explanation: 解释或解析，可选
    init(
        userAnswer: String,
        isCorrect: Bool,
        correctAnswers: [String],
        explanation: String? = nil
    ) {
        self.userAnswer = userAnswer
        self.isCorrect = isCorrect
        self.correctAnswers = correctAnswers
        self.explanation = explanation
        self.timestamp = Date() // 自动记录当前时间
    }
}
