//
//  CompleteReviewSessionUseCaseProtocol.swift
//  NotBad
//
//  Domain Layer - Use Case Protocol
//

import Foundation

// MARK: - CompleteReviewSessionUseCaseProtocol

/// 完成复习会话用例协议
///
/// 负责结束复习会话并生成复习报告：
/// - 统计正确率
/// - 计算总用时
/// - 生成复习报告
/// - 更新统计数据
///
/// ## 使用示例
///
/// ```swift
/// let useCase = dependencies.makeCompleteReviewSessionUseCase()
/// let report = try await useCase.execute(session: session)
/// print("正确率: \(report.correctRate * 100)%")
/// ```
@MainActor
protocol CompleteReviewSessionUseCaseProtocol: Sendable {
    
    /// 完成复习会话
    ///
    /// - Parameter session: 复习会话
    /// - Returns: 复习报告
    /// - Throws: 完成失败时抛出错误
    func execute(session: ReviewSession) async throws -> ReviewReport
}

// MARK: - ReviewReport

/// 复习报告
///
/// 一次复习会话结束后的统计报告。
struct ReviewReport: Identifiable, Sendable {
    
    /// 报告 ID
    let id: UUID
    
    /// 对应的会话 ID
    let sessionId: UUID
    
    /// 复习模式
    let mode: SessionReviewMode
    
    /// 总题目数
    let totalCount: Int
    
    /// 正确数
    let correctCount: Int
    
    /// 错误数
    let incorrectCount: Int
    
    /// 总用时（秒）
    let totalDuration: TimeInterval
    
    /// 平均每题用时（秒）
    let averageDuration: TimeInterval
    
    /// 开始时间
    let startedAt: Date
    
    /// 结束时间
    let completedAt: Date
    
    /// 各掌握程度分布
    let masteryDistribution: [MasteryLevel: Int]
    
    /// 各学科分布
    let subjectDistribution: [Subject: Int]
    
    // MARK: - Computed Properties
    
    /// 正确率
    var correctRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(correctCount) / Double(totalCount)
    }
    
    /// 复习时长（分钟）
    var durationMinutes: Int {
        Int(totalDuration / 60)
    }
    
    /// 是否优秀（正确率 >= 80%）
    var isExcellent: Bool {
        correctRate >= 0.8
    }
    
    /// 是否及格（正确率 >= 60%）
    var isPassing: Bool {
        correctRate >= 0.6
    }
    
    /// 评价等级
    var grade: ReviewGrade {
        switch correctRate {
        case 0.9...: return .excellent
        case 0.8..<0.9: return .good
        case 0.6..<0.8: return .fair
        default: return .needsImprovement
        }
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        sessionId: UUID,
        mode: SessionReviewMode,
        totalCount: Int,
        correctCount: Int,
        totalDuration: TimeInterval,
        startedAt: Date,
        completedAt: Date = Date(),
        masteryDistribution: [MasteryLevel: Int] = [:],
        subjectDistribution: [Subject: Int] = [:]
    ) {
        self.id = id
        self.sessionId = sessionId
        self.mode = mode
        self.totalCount = totalCount
        self.correctCount = correctCount
        self.incorrectCount = totalCount - correctCount
        self.totalDuration = totalDuration
        self.averageDuration = totalCount > 0 ? totalDuration / Double(totalCount) : 0
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.masteryDistribution = masteryDistribution
        self.subjectDistribution = subjectDistribution
    }
}

// MARK: - ReviewGrade

/// 复习评价等级
enum ReviewGrade: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    case excellent      // 优秀 (90%+)
    case good           // 良好 (80-89%)
    case fair           // 及格 (60-79%)
    case needsImprovement  // 需努力 (<60%)
    
    nonisolated var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .excellent: return String(localized: "优秀")
        case .good: return String(localized: "良好")
        case .fair: return String(localized: "及格")
        case .needsImprovement: return String(localized: "需努力")
        }
    }
    
    var emoji: String {
        switch self {
        case .excellent: return "🌟"
        case .good: return "👍"
        case .fair: return "✅"
        case .needsImprovement: return "💪"
        }
    }
    
    var icon: String {
        switch self {
        case .excellent: return "star.fill"
        case .good: return "hand.thumbsup.fill"
        case .fair: return "checkmark.circle"
        case .needsImprovement: return "arrow.up.heart"
        }
    }
}
