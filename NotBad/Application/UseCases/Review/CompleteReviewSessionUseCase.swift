//
//  CompleteReviewSessionUseCase.swift
//  NotBad
//
//  Application Layer - Use Case Implementation
//

import Foundation

// MARK: - CompleteReviewSessionUseCase

/// 完成复习会话用例实现
///
/// 实现 `CompleteReviewSessionUseCaseProtocol`，负责：
/// - 统计复习结果
/// - 生成复习报告
@MainActor
final class CompleteReviewSessionUseCase: CompleteReviewSessionUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let repository: ReviewItemRepositoryProtocol
    
    // MARK: - Initialization
    
    init(repository: ReviewItemRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - CompleteReviewSessionUseCaseProtocol
    
    func execute(session: ReviewSession) async throws -> ReviewReport {
        let completedAt = Date()
        let totalDuration = completedAt.timeIntervalSince(session.startedAt)
        
        // 统计正确数
        let correctCount = session.results.filter { $0.isCorrect }.count
        
        // 统计掌握程度分布
        var masteryDistribution: [MasteryLevel: Int] = [:]
        for result in session.results {
            masteryDistribution[result.newMasteryLevel, default: 0] += 1
        }
        
        // 统计学科分布
        var subjectDistribution: [Subject: Int] = [:]
        for item in session.items {
            subjectDistribution[item.subject, default: 0] += 1
        }
        
        return ReviewReport(
            sessionId: session.id,
            mode: session.mode,
            totalCount: session.items.count,
            correctCount: correctCount,
            totalDuration: totalDuration,
            startedAt: session.startedAt,
            completedAt: completedAt,
            masteryDistribution: masteryDistribution,
            subjectDistribution: subjectDistribution
        )
    }
}
