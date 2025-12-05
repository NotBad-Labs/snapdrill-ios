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
/// 实现 `GetStatisticsUseCaseProtocol`，负责计算各类统计数据
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
        for level in MasteryLevel.allCases {
            masteryDistribution[level] = allItems.filter { 
                MasteryLevel(rawValue: $0.masteryLevel) == level 
            }.count
        }
        
        // 计算学科分布
        var subjectDistribution: [Subject: Int] = [:]
        for subject in Subject.allCases {
            subjectDistribution[subject] = allItems.filter { $0.subject == subject }.count
        }
        
        // 已掌握数量
        let masteredCount = allItems.filter { 
            let mastery = MasteryLevel(rawValue: $0.masteryLevel) ?? .none
            return mastery == .mastered || mastery == .good
        }.count
        
        // 本周/本月复习次数 - 基于 updatedAt（作为最近复习时间的近似）
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        
        // 只统计有复习记录的项目
        let reviewedItems = allItems.filter { $0.reviewCount > 0 }
        
        let weeklyReviewCount = reviewedItems.filter { item in
            return item.updatedAt >= weekAgo
        }.count
        
        let monthlyReviewCount = reviewedItems.filter { item in
            return item.updatedAt >= monthAgo
        }.count
        
        // 平均正确率（简化计算：基于掌握程度）
        let averageCorrectRate = calculateAverageCorrectRate(items: allItems)
        
        // 连续复习天数
        let streakDays = calculateStreakDays(items: allItems)
        
        return OverviewStatistics(
            totalCount: allItems.count,
            dueCount: dueItems.count,
            dueTodayCount: dueTodayItems.count,
            overdueCount: overdueItems.count,
            masteredCount: masteredCount,
            masteryDistribution: masteryDistribution,
            subjectDistribution: subjectDistribution,
            weeklyReviewCount: weeklyReviewCount,
            monthlyReviewCount: monthlyReviewCount,
            averageCorrectRate: averageCorrectRate,
            streakDays: streakDays
        )
    }
    
    func executeBySubject() async -> [SubjectStatistics] {
        var results: [SubjectStatistics] = []
        
        for subject in Subject.allCases {
            let stats = await execute(subject: subject)
            if stats.totalCount > 0 {
                results.append(stats)
            }
        }
        
        return results.sorted { $0.totalCount > $1.totalCount }
    }
    
    func execute(subject: Subject) async -> SubjectStatistics {
        let items = repository.fetch(subject: subject, mastery: nil)
        let dueItems = items.filter { $0.needsReview }
        
        // 计算掌握程度分布
        var masteryDistribution: [MasteryLevel: Int] = [:]
        for level in MasteryLevel.allCases {
            masteryDistribution[level] = items.filter { 
                MasteryLevel(rawValue: $0.masteryLevel) == level 
            }.count
        }
        
        // 计算难度分布
        var difficultyDistribution: [Difficulty: Int] = [:]
        for difficulty in Difficulty.allCases {
            difficultyDistribution[difficulty] = items.filter { $0.difficulty == difficulty }.count
        }
        
        // 已掌握数量
        let masteredCount = items.filter { 
            let mastery = MasteryLevel(rawValue: $0.masteryLevel) ?? .none
            return mastery == .mastered || mastery == .good
        }.count
        
        // 总复习次数
        let totalReviewCount = items.reduce(0) { $0 + $1.reviewCount }
        
        return SubjectStatistics(
            subject: subject,
            totalCount: items.count,
            dueCount: dueItems.count,
            masteredCount: masteredCount,
            masteryDistribution: masteryDistribution,
            difficultyDistribution: difficultyDistribution,
            averageCorrectRate: calculateAverageCorrectRate(items: items),
            totalReviewCount: totalReviewCount
        )
    }
    
    func executeTrend(days: Int) async -> [DailyStatistics] {
        let calendar = Calendar.current
        let now = Date()
        var results: [DailyStatistics] = []
        
        let allItems = repository.fetchAll()
        
        for dayOffset in (0..<days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else {
                continue
            }
            
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
            
            // 当日复习的题目（使用 updatedAt 作为近似，且 reviewCount > 0）
            let reviewedItems = allItems.filter { item in
                guard item.reviewCount > 0 else { return false }
                return item.updatedAt >= startOfDay && item.updatedAt < endOfDay
            }
            
            // 当日新增的题目
            let addedItems = allItems.filter { item in
                return item.createdAt >= startOfDay && item.createdAt < endOfDay
            }
            
            // 正确数（简化：掌握程度为 good 或 mastered 的算正确）
            let correctCount = reviewedItems.filter { item in
                let mastery = MasteryLevel(rawValue: item.masteryLevel) ?? .none
                return mastery == .good || mastery == .mastered
            }.count
            
            results.append(DailyStatistics(
                date: startOfDay,
                reviewedCount: reviewedItems.count,
                correctCount: correctCount,
                addedCount: addedItems.count
            ))
        }
        
        return results
    }
    
    func executeTodayProgress() async -> TodayProgress {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        let allItems = repository.fetchAll()
        let dueToday = repository.fetchDueToday()
        
        // 今日已完成的复习（使用 updatedAt 作为近似）
        let completedToday = allItems.filter { item in
            guard item.reviewCount > 0 else { return false }
            return item.updatedAt >= startOfToday
        }
        
        // 正确数
        let correctCount = completedToday.filter { item in
            let mastery = MasteryLevel(rawValue: item.masteryLevel) ?? .none
            return mastery == .good || mastery == .mastered
        }.count
        
        // 目标数 = 今日到期数 + 已完成数（去重）
        let targetCount = max(dueToday.count + completedToday.count, 1)
        let remainingCount = max(0, dueToday.count)
        
        return TodayProgress(
            targetCount: targetCount,
            completedCount: completedToday.count,
            remainingCount: remainingCount,
            correctCount: correctCount,
            totalDuration: 0 // 暂不追踪时长
        )
    }
    
    // MARK: - Private Methods
    
    /// 计算平均正确率（基于掌握程度估算）
    private func calculateAverageCorrectRate(items: [ReviewItem]) -> Double {
        guard !items.isEmpty else { return 0 }
        
        let totalScore = items.reduce(0.0) { total, item in
            let mastery = MasteryLevel(rawValue: item.masteryLevel) ?? .none
            switch mastery {
            case .none: return total + 0.0
            case .glimpse: return total + 0.3
            case .partial: return total + 0.6
            case .good: return total + 0.8
            case .mastered: return total + 1.0
            }
        }
        
        return totalScore / Double(items.count)
    }
    
    /// 计算连续复习天数
    private func calculateStreakDays(items: [ReviewItem]) -> Int {
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: Date())
        var streakDays = 0
        
        // 只考虑有复习记录的项目
        let reviewedItems = items.filter { $0.reviewCount > 0 }
        
        // 检查最近的连续天数
        while streakDays < 365 {
            let hasReviewOnDate = reviewedItems.contains { item in
                return calendar.isDate(item.updatedAt, inSameDayAs: currentDate)
            }
            
            if hasReviewOnDate {
                streakDays += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if streakDays == 0 {
                // 今天还没复习，检查昨天
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streakDays
    }
}
