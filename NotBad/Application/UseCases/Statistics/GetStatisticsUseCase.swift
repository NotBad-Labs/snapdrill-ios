//
//  GetStatisticsUseCase.swift
//  NotBad
//
//  Application Layer - Use Case Implementation
//

import Foundation

// MARK: - GetStatisticsUseCase

/// 获取统计数据用例实现
///
/// 实现 `GetStatisticsUseCaseProtocol`，负责：
/// - 从仓库获取数据
/// - 计算各类统计指标
@MainActor
final class GetStatisticsUseCase: GetStatisticsUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let repository: ReviewItemRepositoryProtocol
    
    // MARK: - Initialization
    
    init(repository: ReviewItemRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - GetStatisticsUseCaseProtocol
    
    func executeOverview() async -> OverviewStatistics {
        let allItems = repository.fetchAll()
        let dueItems = repository.fetchForReview()
        let dueTodayItems = repository.fetchDueToday()
        let overdueItems = repository.fetchOverdue()
        
        // 计算掌握程度分布
        var masteryDistribution: [MasteryLevel: Int] = [:]
        for item in allItems {
            let level = MasteryLevel(rawValue: item.masteryLevel) ?? .notStarted
            masteryDistribution[level, default: 0] += 1
        }
        
        // 计算学科分布
        var subjectDistribution: [Subject: Int] = [:]
        for item in allItems {
            subjectDistribution[item.subject, default: 0] += 1
        }
        
        // 计算已掌握数
        let masteredCount = masteryDistribution[.mastered, default: 0]
        
        return OverviewStatistics(
            totalCount: allItems.count,
            dueCount: dueItems.count,
            dueTodayCount: dueTodayItems.count,
            overdueCount: overdueItems.count,
            masteredCount: masteredCount,
            masteryDistribution: masteryDistribution,
            subjectDistribution: subjectDistribution,
            weeklyReviewCount: 0, // TODO: 从复习记录计算
            monthlyReviewCount: 0, // TODO: 从复习记录计算
            averageCorrectRate: 0, // TODO: 从复习记录计算
            streakDays: 0 // TODO: 从复习记录计算
        )
    }
    
    func executeBySubject() async -> [SubjectStatistics] {
        let allItems = repository.fetchAll()
        
        // 按学科分组
        var itemsBySubject: [Subject: [ReviewItem]] = [:]
        for item in allItems {
            itemsBySubject[item.subject, default: []].append(item)
        }
        
        // 计算每个学科的统计
        return itemsBySubject.map { subject, items in
            calculateSubjectStatistics(subject: subject, items: items)
        }.sorted { $0.totalCount > $1.totalCount }
    }
    
    func execute(subject: Subject) async -> SubjectStatistics {
        let items = repository.fetch(subject: subject, mastery: nil)
        return calculateSubjectStatistics(subject: subject, items: items)
    }
    
    func executeTrend(days: Int) async -> [DailyStatistics] {
        // TODO: 实现复习趋势统计
        // 需要复习记录数据
        return []
    }
    
    func executeTodayProgress() async -> TodayProgress {
        let dueTodayItems = repository.fetchDueToday()
        
        // TODO: 从今日复习记录获取完成数据
        return TodayProgress(
            targetCount: dueTodayItems.count,
            completedCount: 0,
            remainingCount: dueTodayItems.count,
            correctCount: 0,
            totalDuration: 0
        )
    }
    
    // MARK: - Private Methods
    
    private func calculateSubjectStatistics(
        subject: Subject,
        items: [ReviewItem]
    ) -> SubjectStatistics {
        // 计算掌握程度分布
        var masteryDistribution: [MasteryLevel: Int] = [:]
        for item in items {
            let level = MasteryLevel(rawValue: item.masteryLevel) ?? .notStarted
            masteryDistribution[level, default: 0] += 1
        }
        
        // 计算难度分布
        var difficultyDistribution: [Difficulty: Int] = [:]
        for item in items {
            difficultyDistribution[item.difficulty, default: 0] += 1
        }
        
        // 计算需要复习的数量
        let now = Date()
        let dueCount = items.filter { $0.nextReviewDate <= now }.count
        
        // 计算已掌握数量
        let masteredCount = masteryDistribution[.mastered, default: 0]
        
        // 计算总复习次数
        let totalReviewCount = items.reduce(0) { $0 + $1.reviewCount }
        
        return SubjectStatistics(
            subject: subject,
            totalCount: items.count,
            dueCount: dueCount,
            masteredCount: masteredCount,
            masteryDistribution: masteryDistribution,
            difficultyDistribution: difficultyDistribution,
            averageCorrectRate: 0, // TODO: 从复习记录计算
            totalReviewCount: totalReviewCount
        )
    }
}
