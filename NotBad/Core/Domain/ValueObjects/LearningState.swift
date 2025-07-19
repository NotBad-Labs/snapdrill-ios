//
//  LearningState.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesContentDifficulty // 包含 Difficulty
// import NotBadCoreDomainEntitiesLearningMasteryLevel // 包含 MasteryLevel
// import NotBadCoreDomainEntitiesLearningReviewPriority // 包含 ReviewPriority
// import NotBadCoreDomainErrors // 包含 QuestionDomainError

/// 掌握程度枚举
// Note: In a real project, this would be in its own file: Core/Domain/ValueObjects/MasteryLevel.swift
enum MasteryLevel: String, CaseIterable, Codable, Sendable, Hashable {
    case unknown = "未知" // 尚未尝试
    case struggling = "困难" // 准确率低，需要大量练习
    case learning = "学习中" // 正在进步，但尚未掌握
    case improving = "进步中" // 准确率较高，接近掌握
    case mastered = "已掌握" // 准确率高，可以减少练习频率

    var displayName: String { rawValue }

    var progressValue: Double {
        switch self {
        case .unknown: return 0.0
        case .struggling: return 0.2
        case .learning: return 0.4
        case .improving: return 0.7
        case .mastered: return 1.0
        }
    }
}

/// 复习优先级枚举
// Note: In a real project, this would be in its own file: Core/Domain/ValueObjects/ReviewPriority.swift
enum ReviewPriority: Int, Comparable, Codable, Sendable, Hashable {
    case low = 1
    case medium = 2
    case high = 3

    static func < (lhs: ReviewPriority, rhs: ReviewPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        }
    }

    var color: String { // 用于UI展示的颜色，实际UI层会映射
        switch self {
        case .low: return "#34C759"    // 绿色
        case .medium: return "#FF9500" // 橙色
        case .high: return "#FF3B30"   // 红色
        }
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

/// 难度级别枚举
// Note: In a real project, this would be in its own file: Core/Domain/Entities/Content/Difficulty.swift
enum Difficulty: String, CaseIterable, Codable, Comparable, Sendable, Hashable {
    case easy = "简单"
    case medium = "中等"
    case hard = "困难"

    var displayName: String { rawValue }

    var coefficient: Double { // 用于复习间隔计算的难度系数
        switch self {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.0
        }
    }

    func isHard() -> Bool {
        self == .hard
    }

    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        // 简单的比较方式，实际可能用 Int 关联值或更复杂的逻辑
        // 例如，如果 .easy = 1, .medium = 2, .hard = 3
        switch (lhs, rhs) {
        case (.easy, .medium), (.easy, .hard), (.medium, .hard):
            return true
        default:
            return false
        }
    }
}

/// 学习状态值对象（聚合内核心状态）
/// 封装了题目在学习过程中的所有相关统计数据和业务逻辑，
/// 如答题次数、正确率、复习信息、掌握程度等。
/// 这是一个不可变的值对象，其修改方法返回新的实例。
struct LearningState: Codable, Sendable, Hashable {
    let totalAttempts: Int // 总答题尝试次数
    let correctAttempts: Int // 正确答题次数
    let reviewCount: Int // 复习次数
    let lastReviewedAt: Date? // 上次复习时间
    let lastAttemptAt: Date? // 上次答题尝试时间
    let wrongReason: String? // 答错原因（用户记录）
    let responseTimeHistory: [TimeInterval] // 最近的答题响应时间历史记录
    let masteryLevel: MasteryLevel // 当前掌握程度
    // 每日尝试次数历史，用于更精确地计算当天尝试次数，Key: 日期 (YYYY-MM-DD), Value: 当天尝试次数
    private let dailyAttempts: [Date: Int]

    /// 初始化 LearningState
    /// - Parameters:
    ///   - totalAttempts: 总答题尝试次数
    ///   - correctAttempts: 正确答题次数
    ///   - reviewCount: 复习次数
    ///   - lastReviewedAt: 上次复习时间
    ///   - lastAttemptAt: 上次答题尝试时间
    ///   - wrongReason: 答错原因
    ///   - responseTimeHistory: 答题响应时间历史
    ///   - masteryLevel: 掌握程度
    ///   - dailyAttempts: 每日尝试次数历史
    init(
        totalAttempts: Int = 0,
        correctAttempts: Int = 0,
        reviewCount: Int = 0,
        lastReviewedAt: Date? = nil,
        lastAttemptAt: Date? = nil,
        wrongReason: String? = nil,
        responseTimeHistory: [TimeInterval] = [],
        masteryLevel: MasteryLevel = .unknown,
        dailyAttempts: [Date: Int] = [:]
    ) {
        self.totalAttempts = totalAttempts
        self.correctAttempts = correctAttempts
        self.reviewCount = reviewCount
        self.lastReviewedAt = lastReviewedAt
        self.lastAttemptAt = lastAttemptAt
        self.wrongReason = wrongReason
        self.responseTimeHistory = responseTimeHistory
        self.masteryLevel = masteryLevel
        self.dailyAttempts = dailyAttempts
    }

    /// 准确率
    var accuracy: Double {
        guard totalAttempts > 0 else { return 0.0 }
        return Double(correctAttempts) / Double(totalAttempts)
    }

    /// 平均响应时间
    var averageResponseTime: TimeInterval {
        guard !responseTimeHistory.isEmpty else { return 0.0 }
        return responseTimeHistory.reduce(0, +) / Double(responseTimeHistory.count)
    }

    /// 记录答题尝试
    /// 此方法更新学习状态，包括尝试次数、正确次数、响应时间等。
    /// - Parameters:
    ///   - isCorrect: 本次尝试是否正确
    ///   - difficulty: 题目的难度
    ///   - timestamp: 本次尝试的时间戳
    ///   - responseTime: 本次尝试的响应时间（秒），默认为0
    /// - Returns: 更新后的 LearningState 新实例
    func recordAttempt(
        isCorrect: Bool,
        difficulty: Difficulty,
        timestamp: Date,
        responseTime: TimeInterval = 0
    ) -> LearningState {
        let newTotalAttempts = totalAttempts + 1
        let newCorrectAttempts = correctAttempts + (isCorrect ? 1 : 0)
        var newResponseTimeHistory = responseTimeHistory

        // 保持响应时间历史记录最多50条，防止内存无限增长
        if responseTime > 0 {
            newResponseTimeHistory.append(responseTime)
            if newResponseTimeHistory.count > 50 {
                newResponseTimeHistory.removeFirst()
            }
        }

        // 更新每日尝试次数，确保日期是当天的开始
        var updatedDailyAttempts = dailyAttempts
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: timestamp)
        updatedDailyAttempts[today, default: 0] += 1

        // 重新计算掌握程度
        let newMasteryLevel = calculateMasteryLevel(
            totalAttempts: newTotalAttempts,
            correctAttempts: newCorrectAttempts,
            difficulty: difficulty
        )

        return LearningState(
            totalAttempts: newTotalAttempts,
            correctAttempts: newCorrectAttempts,
            reviewCount: reviewCount,
            lastReviewedAt: lastReviewedAt,
            lastAttemptAt: timestamp,
            wrongReason: wrongReason,
            responseTimeHistory: newResponseTimeHistory,
            masteryLevel: newMasteryLevel,
            dailyAttempts: updatedDailyAttempts
        )
    }

    /// 标记为已复习
    /// 此方法更新复习次数和上次复习时间。
    /// - Parameter date: 标记为已复习的时间
    /// - Returns: 更新后的 LearningState 新实例
    /// - Throws: QuestionDomainError 如果未曾尝试过的题目被标记为已复习
    func markReviewed(at date: Date) throws -> LearningState {
        guard totalAttempts > 0 else {
            throw QuestionDomainError.cannotReviewUnatttemptedQuestion
        }

        return LearningState(
            totalAttempts: totalAttempts,
            correctAttempts: correctAttempts,
            reviewCount: reviewCount + 1,
            lastReviewedAt: date,
            lastAttemptAt: lastAttemptAt,
            wrongReason: wrongReason,
            responseTimeHistory: responseTimeHistory,
            masteryLevel: masteryLevel,
            dailyAttempts: dailyAttempts
        )
    }

    /// 更新错误原因
    /// - Parameter reason: 错误原因描述，nil 表示清除
    /// - Returns: 更新后的 LearningState 新实例
    func updateWrongReason(_ reason: String?) -> LearningState {
        return LearningState(
            totalAttempts: totalAttempts,
            correctAttempts: correctAttempts,
            reviewCount: reviewCount,
            lastReviewedAt: lastReviewedAt,
            lastAttemptAt: lastAttemptAt,
            wrongReason: reason,
            responseTimeHistory: responseTimeHistory,
            masteryLevel: masteryLevel,
            dailyAttempts: dailyAttempts
        )
    }

    /// 验证是否可以答题
    /// 此方法包含答题前的业务规则验证。
    /// - Throws: QuestionDomainError 如果当前状态不允许答题
    func validateCanAnswer() throws {
        // 业务规则：已掌握的题目一天内最多答题3次
        if masteryLevel == .mastered {
            let today = Calendar.current.startOfDay(for: Date())
            let attemptsToday = dailyAttempts[today] ?? 0
            if attemptsToday >= 3 {
                throw QuestionDomainError.tooManyAttemptsForMasteredQuestion
            }
        }
    }

    /// 判断题目是否需要复习
    /// 基于复习策略、难度和当前时间判断。
    /// - Parameters:
    ///   - difficulty: 题目的难度
    ///   - currentDate: 当前时间
    /// - Returns: true 如果需要复习，否则为 false
    func needsReview(basedOn difficulty: Difficulty, at currentDate: Date) -> Bool {
        guard let lastReview = lastReviewedAt else {
            // 如果从未复习过，但有尝试记录，则认为需要复习
            return totalAttempts > 0
        }

        let interval = calculateReviewInterval(
            reviewCount: reviewCount,
            difficulty: difficulty,
            accuracy: accuracy
        )

        return currentDate.timeIntervalSince(lastReview) >= interval
    }

    /// 计算下次复习的建议时间
    /// - Parameter difficulty: 题目的难度
    /// - Returns: 建议的下次复习时间
    func calculateNextReviewDate(difficulty: Difficulty) -> Date {
        let baseDate = lastReviewedAt ?? Date() // 如果从未复习，则从现在开始计算
        let interval = calculateReviewInterval(
            reviewCount: reviewCount,
            difficulty: difficulty,
            accuracy: accuracy
        )
        return baseDate.addingTimeInterval(interval)
    }

    /// 计算题目的复习优先级
    /// 基于掌握程度、准确率、创建时间等因素。
    /// - Parameters:
    ///   - difficulty: 题目的难度
    ///   - createdAt: 题目的创建时间
    /// - Returns: 复习优先级枚举值
    func calculateReviewPriority(difficulty: Difficulty, createdAt: Date) -> ReviewPriority {
        let daysSinceCreation = abs(createdAt.timeIntervalSinceNow) / (24 * 60 * 60) // 题目创建至今的天数

        // 基于多个因素计算优先级，优先级越高表示越需要立即复习
        switch (masteryLevel, accuracy, daysSinceCreation) {
        case (.struggling, _, _), (_, 0.0..<0.5, _):
            return .high // 困难或准确率极低，优先级最高
        case (.learning, 0.5..<0.8, 0..<7):
            return .high // 学习中且近期，优先级高
        case (.learning, 0.5..<0.8, _), (.improving, _, 0..<14):
            return .medium // 学习中或进步中，优先级中等
        case (.mastered, _, 30...):
            return .low // 已掌握且长时间未复习，优先级低，仅需偶尔巩固
        default:
            return .medium // 默认情况
        }
    }

    /// 计算学习进度百分比
    /// - Returns: 学习进度百分比 (0.0 - 100.0)
    func calculateProgressPercentage() -> Double {
        return masteryLevel.progressValue * 100.0
    }

    /// 识别学习优势领域
    /// - Returns: 描述学习优势的字符串数组
    func identifyStrengths() -> [String] {
        var strengths: [String] = []

        if accuracy >= 0.8 {
            strengths.append("答题准确率高")
        }

        if averageResponseTime > 0 && averageResponseTime < 30 { // 假设30秒内为快
            strengths.append("反应速度快")
        }

        if reviewCount >= 3 && masteryLevel == .mastered {
            strengths.append("学习持续性好")
        }

        return strengths
    }

    /// 识别学习待改进领域
    /// - Returns: 描述学习弱点的字符串数组
    func identifyWeaknesses() -> [String] {
        var weaknesses: [String] = []

        if accuracy < 0.6 {
            weaknesses.append("准确率需要提高")
        }

        if totalAttempts > 5 && masteryLevel == .struggling {
            weaknesses.append("理解程度需要加强")
        }

        if reviewCount == 0 && totalAttempts > 0 {
            weaknesses.append("缺乏复习巩固")
        }

        return weaknesses
    }

    // MARK: - 私有计算方法

    /// 根据答题数据和难度计算掌握程度
    private func calculateMasteryLevel(
        totalAttempts: Int,
        correctAttempts: Int,
        difficulty: Difficulty
    ) -> MasteryLevel {
        guard totalAttempts > 0 else { return .unknown }

        let accuracy = Double(correctAttempts) / Double(totalAttempts)
        let requiredAttempts = difficulty.isHard() ? 5 : 3 // 困难题需要更多尝试才能掌握

        switch (totalAttempts, accuracy) {
        case (_, 0.0..<0.4):
            return .struggling // 准确率极低
        case (1..<requiredAttempts, 0.4..<0.7):
            return .learning // 尝试次数不足或准确率中等
        case (requiredAttempts..., 0.7..<0.9):
            return .improving // 尝试次数足够，准确率较高
        case (requiredAttempts..., 0.9...1.0):
            return .mastered // 尝试次数足够，准确率高
        default:
            return .learning // 默认情况，例如不满足上述所有条件
        }
    }

    /// 计算复习间隔时间
    /// 采用间隔重复算法：基础间隔 * 重复系数 * 难度系数 * 准确率系数
    private func calculateReviewInterval(
        reviewCount: Int,
        difficulty: Difficulty,
        accuracy: Double
    ) -> TimeInterval {
        let baseInterval: TimeInterval = 24 * 60 * 60 // 基础间隔：1天
        let repetitionFactor = pow(2.0, Double(reviewCount)) // 复习次数越多，间隔越长
        let difficultyFactor = difficulty.coefficient // 题目难度越高，间隔越短
        let accuracyFactor = accuracy > 0.8 ? 1.5 : 0.7 // 准确率高增加间隔，低减少间隔

        return baseInterval * repetitionFactor * difficultyFactor * accuracyFactor
    }
}

