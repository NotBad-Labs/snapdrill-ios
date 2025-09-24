//
//  ReviewItemAggregate.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import Foundation

/// ReviewItem 聚合根
/// 遵循DDD原则，封装业务逻辑和不变性
struct ReviewItem {
    // MARK: - 标识
    let id: ReviewItemID
    
    // MARK: - 核心属性
    private(set) var question: String
    private(set) var answer: String
    private(set) var subject: Subject
    private(set) var difficulty: Difficulty
    private(set) var tags: Set<String>
    private(set) var notes: String?
    
    // MARK: - 学习状态
    private(set) var proficiencyLevel: ProficiencyLevel
    private(set) var reviewHistory: ReviewHistory
    private(set) var lastReviewedDate: Date?
    private(set) var nextReviewDate: Date?
    
    // MARK: - 元数据
    private(set) var source: Source
    let createdAt: Date
    private(set) var updatedAt: Date
    
    // MARK: - 初始化
    init(
        question: String,
        answer: String,
        subject: Subject,
        difficulty: Difficulty = .medium,
        tags: Set<String> = [],
        notes: String? = nil,
        source: Source = .manual
    ) throws {
        // 业务规则验证
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReviewItemError.emptyQuestion
        }
        guard !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReviewItemError.emptyAnswer
        }
        
        self.id = ReviewItemID()
        self.question = question
        self.answer = answer
        self.subject = subject
        self.difficulty = difficulty
        self.tags = tags
        self.notes = notes
        self.proficiencyLevel = .notProficient
        self.reviewHistory = ReviewHistory()
        self.lastReviewedDate = nil
        self.nextReviewDate = nil
        self.source = source
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - 业务方法
    
    /// 更新内容
    mutating func updateContent(
        question: String? = nil,
        answer: String? = nil,
        subject: Subject? = nil,
        difficulty: Difficulty? = nil,
        tags: Set<String>? = nil,
        notes: String? = nil
    ) throws {
        if let newQuestion = question {
            guard !newQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ReviewItemError.emptyQuestion
            }
            self.question = newQuestion
        }
        
        if let newAnswer = answer {
            guard !newAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ReviewItemError.emptyAnswer
            }
            self.answer = newAnswer
        }
        
        if let newSubject = subject {
            self.subject = newSubject
        }
        
        if let newDifficulty = difficulty {
            self.difficulty = newDifficulty
        }
        
        if let newTags = tags {
            self.tags = newTags
        }
        
        if let newNotes = notes {
            self.notes = newNotes.isEmpty ? nil : newNotes
        }
        
        self.updatedAt = Date()
    }
    
    /// 单独更新问题
    mutating func updateQuestion(_ newQuestion: String) throws {
        guard !newQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReviewItemError.emptyQuestion
        }
        self.question = newQuestion
        self.updatedAt = Date()
    }
    
    /// 单独更新答案
    mutating func updateAnswer(_ newAnswer: String) throws {
        guard !newAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReviewItemError.emptyAnswer
        }
        self.answer = newAnswer
        self.updatedAt = Date()
    }
    
    /// 单独更新科目
    mutating func updateSubject(_ newSubject: Subject) {
        self.subject = newSubject
        self.updatedAt = Date()
    }
    
    /// 单独更新难度
    mutating func updateDifficulty(_ newDifficulty: Difficulty) {
        self.difficulty = newDifficulty
        self.updatedAt = Date()
    }
    
    /// 单独更新标签
    mutating func updateTags(_ newTags: Set<String>) {
        self.tags = newTags
        self.updatedAt = Date()
    }
    
    /// 单独更新备注
    mutating func updateNotes(_ newNotes: String?) {
        self.notes = newNotes?.isEmpty == true ? nil : newNotes
        self.updatedAt = Date()
    }
    
    /// 添加复习会话（用于Repository实现）
    mutating func addReviewSession(_ session: ReviewSession) {
        reviewHistory.addSession(session)
        lastReviewedDate = session.date
        
        // 更新熟练度
        updateProficiencyLevel(basedOn: session.wasSuccessful)
        
        // 计算下次复习日期
        nextReviewDate = calculateNextReviewDate(wasSuccessful: session.wasSuccessful)
        
        updatedAt = Date()
    }
    
    /// 记录复习结果
    mutating func recordReviewResult(wasSuccessful: Bool) {
        let session = ReviewSession(
            date: Date(),
            wasSuccessful: wasSuccessful,
            difficulty: difficulty
        )
        
        reviewHistory.addSession(session)
        lastReviewedDate = session.date
        
        // 更新熟练度
        updateProficiencyLevel(basedOn: wasSuccessful)
        
        // 计算下次复习日期
        nextReviewDate = calculateNextReviewDate(wasSuccessful: wasSuccessful)
        
        updatedAt = Date()
    }
    
    /// 检查是否需要复习
    func needsReview(on date: Date = Date()) -> Bool {
        guard let nextReview = nextReviewDate else {
            return true // 从未复习过，需要复习
        }
        return nextReview <= date
    }
    
    /// 获取复习统计
    func getReviewStatistics() -> ReviewStatistics {
        return reviewHistory.getStatistics()
    }
}

// MARK: - 私有方法
private extension ReviewItem {
    /// 更新熟练度等级
    mutating func updateProficiencyLevel(basedOn wasSuccessful: Bool) {
        if wasSuccessful {
            switch proficiencyLevel {
            case .notProficient:
                proficiencyLevel = .learning
            case .learning:
                proficiencyLevel = .proficient
            case .proficient:
                break // 保持最高级别
            }
        } else {
            switch proficiencyLevel {
            case .notProficient:
                break // 保持最低级别
            case .learning:
                proficiencyLevel = .notProficient
            case .proficient:
                proficiencyLevel = .learning
            }
        }
    }
    
    /// 计算下次复习日期（间隔重复算法）
    func calculateNextReviewDate(wasSuccessful: Bool) -> Date {
        let _ = Calendar.current
        let now = Date()
        
        let baseInterval: TimeInterval
        
        if wasSuccessful {
            // 成功复习，延长间隔
            switch proficiencyLevel {
            case .notProficient:
                baseInterval = 1 * 24 * 60 * 60 // 1天
            case .learning:
                baseInterval = 3 * 24 * 60 * 60 // 3天
            case .proficient:
                baseInterval = 7 * 24 * 60 * 60 // 7天
            }
        } else {
            // 复习失败，缩短间隔
            baseInterval = 1 * 24 * 60 * 60 // 1天
        }
        
        // 根据难度调整间隔
        let difficultyMultiplier: Double
        switch difficulty {
        case .easy:
            difficultyMultiplier = 1.5
        case .medium:
            difficultyMultiplier = 1.0
        case .hard:
            difficultyMultiplier = 0.7
        }
        
        let adjustedInterval = baseInterval * difficultyMultiplier
        return now.addingTimeInterval(adjustedInterval)
    }
    // streak 计算放到公开扩展中，便于测试覆盖
}

// 将连续成功次数相关方法暴露为内部可见，便于单元测试直接断言
extension ReviewItem {
    /// 计算当前连续成功次数
    func calculateCurrentStreak() -> Int {
        return reviewHistory.getCurrentStreak()
    }
    
    /// 计算最长连续成功次数
    func calculateLongestStreak() -> Int {
        return reviewHistory.getLongestStreak()
    }
}

// MARK: - 值对象
extension ReviewItem {
    enum Subject: String, CaseIterable, Codable, Hashable {
        case math = "数学"
        case physics = "物理"
        case chemistry = "化学"
        case biology = "生物"
        case history = "历史"
        case geography = "地理"
        case literature = "语文"
        case english = "英语"
        case other = "其他"
    }
    
    enum Difficulty: String, CaseIterable, Codable, Hashable {
        case easy = "简单"
        case medium = "中等"
        case hard = "困难"
    }
    
    enum ProficiencyLevel: String, CaseIterable, Codable {
        case notProficient = "不熟练"
        case learning = "学习中"
        case proficient = "已熟练"
    }
    
    enum Source: String, CaseIterable, Codable {
        case manual = "手动输入"
        case ocr = "OCR识别"
        case imported = "导入文件"
    }
}

// MARK: - 相关值对象
struct ReviewSession: Codable, Hashable {
    let date: Date
    let wasSuccessful: Bool
    let difficulty: ReviewItem.Difficulty
}

/// 复习历史值对象
/// 封装复习会话的集合和相关业务逻辑
struct ReviewHistory: Codable, Hashable {
    private var sessions: [ReviewSession] = []
    
    init() {
        self.sessions = []
    }
    
    init(sessions: [ReviewSession]) {
        self.sessions = sessions.sorted { $0.date < $1.date }
    }
    
    // MARK: - 查询方法
    
    var count: Int { sessions.count }
    var isEmpty: Bool { sessions.isEmpty }
    var allSessions: [ReviewSession] { sessions }
    
    var lastSession: ReviewSession? { sessions.last }
    var firstSession: ReviewSession? { sessions.first }
    
    // MARK: - 修改方法
    
    mutating func addSession(_ session: ReviewSession) {
        sessions.append(session)
        // 保持时间排序
        sessions.sort { $0.date < $1.date }
    }
    
    // MARK: - 统计方法
    
    func getStatistics() -> ReviewStatistics {
        let totalReviews = sessions.count
        let successfulReviews = sessions.filter(\.wasSuccessful).count
        let successRate = totalReviews > 0 ? Double(successfulReviews) / Double(totalReviews) : 0.0
        
        return ReviewStatistics(
            totalReviews: totalReviews,
            successfulReviews: successfulReviews,
            successRate: successRate,
            currentStreak: getCurrentStreak(),
            longestStreak: getLongestStreak()
        )
    }
    
    func getCurrentStreak() -> Int {
        var streak = 0
        for session in sessions.reversed() {
            if session.wasSuccessful {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
    
    func getLongestStreak() -> Int {
        var longestStreak = 0
        var currentStreak = 0
        
        for session in sessions {
            if session.wasSuccessful {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return longestStreak
    }
    
    func getSessionsInDateRange(_ startDate: Date, _ endDate: Date) -> [ReviewSession] {
        return sessions.filter { session in
            session.date >= startDate && session.date <= endDate
        }
    }
    
    func getRecentSessions(count: Int) -> [ReviewSession] {
        return Array(sessions.suffix(count))
    }

    /// 计算最近 N 天内（含今天）有复习行为的天数比例。
    /// - Parameters:
    ///   - lastNDays: 回看天数窗口，包含今天；若小于等于 0 则返回 0。
    ///   - calendar: 日历（默认 `.current`），用于按天对齐计算。
    /// - Returns: 比例值，范围 [0, 1]。
    func completionRate(lastNDays: Int, calendar: Calendar = .current) -> Double {
        guard lastNDays > 0 else { return 0.0 }
        if sessions.isEmpty { return 0.0 }

        // 以当天 00:00 为窗口终点，向前包含 lastNDays 天。
        let todayStart = calendar.startOfDay(for: Date())
        guard let windowStart = calendar.date(byAdding: .day, value: -(lastNDays - 1), to: todayStart) else {
            return 0.0
        }

        // 过滤窗口内的 session，并按天去重。
        let inWindow = sessions.filter { $0.date >= windowStart && $0.date <= todayStart.addingTimeInterval(24*60*60 - 1) }
        let uniqueDays: Set<Date> = Set(inWindow.map { calendar.startOfDay(for: $0.date) })

        let daysWithSessions = uniqueDays.count
        let denominator = max(lastNDays, 1)
        return Double(daysWithSessions) / Double(denominator)
    }
}

struct ReviewStatistics {
    let totalReviews: Int
    let successfulReviews: Int
    let successRate: Double
    let currentStreak: Int
    let longestStreak: Int
}

// MARK: - 领域错误
enum ReviewItemError: Error, LocalizedError {
    case emptyQuestion
    case emptyAnswer
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .emptyQuestion:
            return "题目不能为空"
        case .emptyAnswer:
            return "答案不能为空"
        case .invalidData:
            return "数据无效"
        }
    }
}

// MARK: - Codable 支持
extension ReviewItem: Codable, Identifiable {}
extension ReviewItem: Hashable {}
extension ReviewItem: Sendable {}