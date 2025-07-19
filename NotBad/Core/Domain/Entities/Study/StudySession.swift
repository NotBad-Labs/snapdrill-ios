//
//  StudySession.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainValueObjectsIdentityQuestionID // 包含 QuestionID
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainErrors // 包含 QuestionDomainError (或更通用的 DomainError)

/// 用户ID强类型 (仅为编译目的包含，实际应从 UserID.swift 导入)
struct UserID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
    init() { self.rawValue = UUID().uuidString }
}

/// 题目ID强类型 (仅为编译目的包含，实际应从 QuestionID.swift 导入)
struct QuestionID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: UUID
    init() { self.rawValue = UUID() }
    init(rawValue: UUID) { self.rawValue = rawValue }
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

/// 题目领域错误 (仅为编译目的包含，实际应从 QuestionDomainError.swift 导入)
enum QuestionDomainError: Error, CustomStringConvertible, LocalizedError {
    case invalidStateForOperation(String)
    // Simplified for compilation
    var description: String {
        switch self {
        case .invalidStateForOperation(let op): return "Invalid state for operation: \(op)"
        }
    }
    var errorDescription: String? { return description }
}

/// 学习会话中的题目尝试记录
/// 记录用户在特定学习会话中对某个题目的答题尝试。
/// 这是一个值对象，用于跟踪会话内部的详细答题情况。
struct StudySessionQuestionAttempt: Codable, Hashable, Sendable {
    let questionId: QuestionID // 尝试的题目ID
    let userAnswer: String // 用户提交的答案
    let isCorrect: Bool // 答题是否正确
    let responseTime: TimeInterval // 答题响应时间（秒）
    let timestamp: Date // 尝试发生的时间

    /// 初始化 StudySessionQuestionAttempt
    /// - Parameters:
    ///   - questionId: 尝试的题目ID
    ///   - userAnswer: 用户提交的答案
    ///   - isCorrect: 答题是否正确
    ///   - responseTime: 答题响应时间
    ///   - timestamp: 尝试发生的时间，默认为当前时间
    init(questionId: QuestionID, userAnswer: String, isCorrect: Bool, responseTime: TimeInterval, timestamp: Date = Date()) {
        self.questionId = questionId
        self.userAnswer = userAnswer
        self.isCorrect = isCorrect
        self.responseTime = responseTime
        self.timestamp = timestamp
    }
}

/// 学习会话领域实体
/// 代表用户进行的一次完整的学习会话，例如一次练习、一次复习或一次模拟考试。
/// 这是一个聚合根，它封装了会话的开始/结束时间、参与的题目、答题记录等，
/// 并维护会话内部数据的一致性。
struct StudySession: Identifiable, Hashable, Codable, Sendable {
    let id: UUID // 学习会话的唯一标识符
    let userId: UserID // 学习会话所属的用户ID
    let startTime: Date // 会话开始时间
    private(set) var endTime: Date? // 会话结束时间，可选（如果会话正在进行）
    let subject: Subject? // 会话所属的学科，可选（如果会话不限定学科）
    let sessionType: String // 会话类型，例如 "练习", "复习", "模拟考试"
    let questionIds: Set<QuestionID> // 本次会话中包含的所有题目ID
    private(set) var answeredQuestions: [QuestionID: StudySessionQuestionAttempt] // 会话中已答题目的尝试记录
    private(set) var isCompleted: Bool // 会话是否已完成

    /// 初始化 StudySession
    /// - Parameters:
    ///   - id: 会话ID，默认为新的UUID
    ///   - userId: 用户ID
    ///   - startTime: 会话开始时间，默认为当前时间
    ///   - endTime: 会话结束时间，可选
    ///   - subject: 会话学科，可选
    ///   - sessionType: 会话类型
    ///   - questionIds: 包含的题目ID集合
    ///   - answeredQuestions: 已答题目记录，默认为空
    ///   - isCompleted: 会话是否完成，默认为false
    init(
        id: UUID = UUID(),
        userId: UserID,
        startTime: Date = Date(),
        endTime: Date? = nil,
        subject: Subject? = nil,
        sessionType: String,
        questionIds: Set<QuestionID>,
        answeredQuestions: [QuestionID: StudySessionQuestionAttempt] = [:],
        isCompleted: Bool = false
    ) {
        // 聚合不变量验证
        guard !questionIds.isEmpty else {
            // 示例：会话必须包含题目
            fatalError("StudySession must contain at least one question ID.") // 或抛出领域错误
        }

        self.id = id
        self.userId = userId
        self.startTime = startTime
        self.endTime = endTime
        self.subject = subject
        self.sessionType = sessionType
        self.questionIds = questionIds
        self.answeredQuestions = answeredQuestions
        self.isCompleted = isCompleted
    }

    /// 重建 StudySession 聚合根（用于从存储恢复）
    /// 这是一个私有初始化方法，仅供仓储层使用，不进行业务验证。
    static func reconstruct(
        id: UUID,
        userId: UserID,
        startTime: Date,
        endTime: Date?,
        subject: Subject?,
        sessionType: String,
        questionIds: Set<QuestionID>,
        answeredQuestions: [QuestionID: StudySessionQuestionAttempt],
        isCompleted: Bool
    ) -> StudySession {
        return StudySession(
            id: id,
            userId: userId,
            startTime: startTime,
            endTime: endTime,
            subject: subject,
            sessionType: sessionType,
            questionIds: questionIds,
            answeredQuestions: answeredQuestions,
            isCompleted: isCompleted
        )
    }

    // MARK: - 业务行为 (返回新的 StudySession 实例)

    /// 记录用户对某个题目的答题尝试。
    /// - Parameters:
    ///   - questionId: 尝试的题目ID。
    ///   - userAnswer: 用户提交的答案。
    ///   - isCorrect: 答题是否正确。
    ///   - responseTime: 答题响应时间。
    /// - Returns: 更新后的 StudySession 新实例。
    /// - Throws: QuestionDomainError 如果题目不属于当前会话。
    func recordQuestionAttempt(questionId: QuestionID, userAnswer: String, isCorrect: Bool, responseTime: TimeInterval) throws -> StudySession {
        guard questionIds.contains(questionId) else {
            throw QuestionDomainError.invalidStateForOperation("题目ID \(questionId.rawValue) 不属于当前学习会话。")
        }

        var newAnsweredQuestions = answeredQuestions
        let attempt = StudySessionQuestionAttempt(
            questionId: questionId,
            userAnswer: userAnswer,
            isCorrect: isCorrect,
            responseTime: responseTime,
            timestamp: Date()
        )
        newAnsweredQuestions[questionId] = attempt // 覆盖或添加新的尝试记录

        return StudySession(
            id: id,
            userId: userId,
            startTime: startTime,
            endTime: endTime,
            subject: subject,
            sessionType: sessionType,
            questionIds: questionIds,
            answeredQuestions: newAnsweredQuestions,
            isCompleted: isCompleted
        )
    }

    /// 结束学习会话。
    /// - Parameters:
    ///   - endTime: 会话结束时间。
    ///   - isCompleted: 标记会话是否正常完成。
    /// - Returns: 更新后的 StudySession 新实例。
    /// - Throws: QuestionDomainError 如果会话已经结束。
    func endSession(at endTime: Date, isCompleted: Bool) throws -> StudySession {
        guard self.endTime == nil else {
            throw QuestionDomainError.invalidStateForOperation("学习会话 \(id.uuidString) 已经结束。")
        }

        return StudySession(
            id: id,
            userId: userId,
            startTime: startTime,
            endTime: endTime, // 设置结束时间
            subject: subject,
            sessionType: sessionType,
            questionIds: questionIds,
            answeredQuestions: answeredQuestions,
            isCompleted: isCompleted // 设置完成状态
        )
    }

    // MARK: - 业务查询 (读取封装)

    /// 计算会话持续时间。
    var duration: TimeInterval {
        guard let end = endTime else {
            return Date().timeIntervalSince(startTime) // 如果未结束，计算到当前时间
        }
        return end.timeIntervalSince(startTime)
    }

    /// 获取会话中已答题目的数量。
    var answeredQuestionCount: Int {
        answeredQuestions.count
    }

    /// 获取会话中正确答题的数量。
    var correctQuestionCount: Int {
        answeredQuestions.values.filter { $0.isCorrect }.count
    }

    /// 计算会话的准确率。
    var sessionAccuracy: Double {
        guard answeredQuestionCount > 0 else { return 0.0 }
        return Double(correctQuestionCount) / Double(answeredQuestionCount)
    }

    /// 获取会话中所有题目的平均响应时间。
    var averageResponseTime: TimeInterval {
        guard !answeredQuestions.isEmpty else { return 0.0 }
        let totalResponseTime = answeredQuestions.values.reduce(0) { $0 + $1.responseTime }
        return totalResponseTime / Double(answeredQuestions.count)
    }

    /// 获取会话中所有题目ID的数组。
    var allQuestionIDs: [QuestionID] {
        Array(questionIds)
    }

    /// 获取会话中所有已答题目的尝试记录。
    var allAnsweredAttempts: [StudySessionQuestionAttempt] {
        Array(answeredQuestions.values)
    }
}

