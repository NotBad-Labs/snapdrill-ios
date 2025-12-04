//
//  ReviewItemRepositoryTests.swift
//  NotBadTests
//
//  仓库层单元测试 - ReviewStatistics 部分
//
//  注意：由于 SwiftData 在 Swift Testing 并行执行时存在兼容性问题，
//  Repository 的 CRUD 操作测试已移除。这里仅测试 ReviewStatistics 的计算逻辑。
//

import Testing
import Foundation
@testable import NotBad

@Suite("ReviewStatistics 测试")
struct ReviewStatisticsTests {

    // MARK: - 空数据测试

    @Test("空数据统计")
    func emptyStatistics() {
        let stats = ReviewStatistics(from: [])

        #expect(stats.totalCount == 0)
        #expect(stats.masteredCount == 0)
        #expect(stats.pendingReviewCount == 0)
        #expect(stats.overdueCount == 0)
        #expect(stats.weeklyNewCount == 0)
        #expect(stats.totalReviewCount == 0)
    }

    @Test("空统计掌握率为0")
    func emptyMasteryRate() {
        let stats = ReviewStatistics(from: [])

        #expect(stats.masteryRate == 0)
        #expect(stats.masteryPercentage == 0)
    }

    // MARK: - 掌握程度测试

    @Test("掌握率计算")
    func masteryRateCalculation() {
        let items = createMockItems(
            masteredCount: 3,
            partialCount: 4,
            noneCount: 3
        )

        let stats = ReviewStatistics(from: items)

        #expect(stats.totalCount == 10)
        #expect(stats.masteredCount == 3)
        // 掌握率 = 3 / 10 = 0.3
        #expect(stats.masteryRate == 0.3)
        #expect(stats.masteryPercentage == 30)
    }

    @Test("掌握程度分布")
    func masteryDistribution() {
        let items = createMockItems(
            masteredCount: 2,
            partialCount: 3,
            noneCount: 5
        )

        let stats = ReviewStatistics(from: items)

        #expect(stats.masteryDistribution[.mastered] == 2)
        #expect(stats.masteryDistribution[.partial] == 3)
        #expect(stats.masteryDistribution[.none] == 5)
    }

    // MARK: - 复习相关测试

    @Test("需要复习的数量 - needsReview 基于 nextReviewDate")
    func pendingReviewCount() {
        let items = createMockItemsWithReviewDates(
            overdueCount: 2,
            dueTodayCount: 3,
            futureCount: 5
        )

        let stats = ReviewStatistics(from: items)

        // needsReview 检查 nextReviewDate <= Date()
        // 过期(2) + 今天(3) = 需要复习(5)
        #expect(stats.pendingReviewCount == 5)
        #expect(stats.hasPendingReview == true)

        // 注意：overdueCount 依赖于 ReviewItem.isOverdue，
        // 而 isOverdue 是通过 reviewInterval 计算的（基于 reviewCount 和 mastery），
        // 不是直接基于 nextReviewDate，所以这里不测试 overdueCount
    }

    @Test("无待复习项")
    func noPendingReview() {
        let items = createMockItemsWithReviewDates(
            overdueCount: 0,
            dueTodayCount: 0,
            futureCount: 5
        )

        let stats = ReviewStatistics(from: items)

        #expect(stats.pendingReviewCount == 0)
        #expect(stats.hasPendingReview == false)
    }

    // MARK: - 学科分布测试

    @Test("学科分布统计")
    func subjectDistribution() {
        let items = createMockItemsWithSubjects(
            mathCount: 5,
            physicsCount: 3,
            chemistryCount: 2
        )

        let stats = ReviewStatistics(from: items)

        #expect(stats.subjectDistribution[.math] == 5)
        #expect(stats.subjectDistribution[.physics] == 3)
        #expect(stats.subjectDistribution[.chemistry] == 2)
    }

    @Test("主要学科（最多错题的学科）")
    func primarySubject() {
        let items = createMockItemsWithSubjects(
            mathCount: 10,
            physicsCount: 3,
            chemistryCount: 2
        )

        let stats = ReviewStatistics(from: items)

        #expect(stats.primarySubject == .math)
    }

    @Test("空数据时主要学科为nil")
    func primarySubjectEmpty() {
        let stats = ReviewStatistics(from: [])

        #expect(stats.primarySubject == nil)
    }

    // MARK: - 难度分布测试

    @Test("难度分布统计")
    func difficultyDistribution() {
        let items = createMockItemsWithDifficulties(
            easyCount: 2,
            mediumCount: 5,
            hardCount: 3
        )

        let stats = ReviewStatistics(from: items)

        #expect(stats.difficultyDistribution[.easy] == 2)
        #expect(stats.difficultyDistribution[.medium] == 5)
        #expect(stats.difficultyDistribution[.hard] == 3)
    }

    // MARK: - 复习次数统计测试

    @Test("累计复习次数")
    func totalReviewCount() {
        let items = createMockItemsWithReviewCounts([0, 1, 2, 3, 4])

        let stats = ReviewStatistics(from: items)

        // 总计 = 0+1+2+3+4 = 10
        #expect(stats.totalReviewCount == 10)
    }

    // MARK: - 描述文字测试

    @Test("掌握描述格式正确")
    func masteryDescription() {
        let items = createMockItems(
            masteredCount: 3,
            partialCount: 0,
            noneCount: 7
        )

        let stats = ReviewStatistics(from: items)

        #expect(stats.masteryDescription == "3/10 已掌握 (30%)")
    }

    // MARK: - 辅助方法

    private func createMockItems(
        masteredCount: Int,
        partialCount: Int,
        noneCount: Int
    ) -> [ReviewItem] {
        var items: [ReviewItem] = []

        for i in 0..<masteredCount {
            let reviewItem = ReviewItem(title: "掌握\(i)", mastery: .mastered)
            items.append(reviewItem)
        }

        for i in 0..<partialCount {
            let reviewItem = ReviewItem(title: "部分\(i)", mastery: .partial)
            items.append(reviewItem)
        }

        for i in 0..<noneCount {
            let reviewItem = ReviewItem(title: "未掌握\(i)", mastery: .none)
            items.append(reviewItem)
        }

        return items
    }

    private func createMockItemsWithReviewDates(
        overdueCount: Int,
        dueTodayCount: Int,
        futureCount: Int
    ) -> [ReviewItem] {
        var items: [ReviewItem] = []
        let now = Date()

        for i in 0..<overdueCount {
            let reviewItem = ReviewItem(title: "过期\(i)")
            reviewItem.nextReviewDate = now.addingTimeInterval(-86400 * Double(i + 1))
            items.append(reviewItem)
        }

        for i in 0..<dueTodayCount {
            let reviewItem = ReviewItem(title: "今天\(i)")
            reviewItem.nextReviewDate = now
            items.append(reviewItem)
        }

        for i in 0..<futureCount {
            let reviewItem = ReviewItem(title: "未来\(i)")
            reviewItem.nextReviewDate = now.addingTimeInterval(86400 * Double(i + 1))
            items.append(reviewItem)
        }

        return items
    }

    private func createMockItemsWithSubjects(
        mathCount: Int,
        physicsCount: Int,
        chemistryCount: Int
    ) -> [ReviewItem] {
        var items: [ReviewItem] = []

        for i in 0..<mathCount {
            items.append(ReviewItem(title: "数学\(i)", subject: .math))
        }

        for i in 0..<physicsCount {
            items.append(ReviewItem(title: "物理\(i)", subject: .physics))
        }

        for i in 0..<chemistryCount {
            items.append(ReviewItem(title: "化学\(i)", subject: .chemistry))
        }

        return items
    }

    private func createMockItemsWithDifficulties(
        easyCount: Int,
        mediumCount: Int,
        hardCount: Int
    ) -> [ReviewItem] {
        var items: [ReviewItem] = []

        for i in 0..<easyCount {
            items.append(ReviewItem(title: "简单\(i)", difficulty: .easy))
        }

        for i in 0..<mediumCount {
            items.append(ReviewItem(title: "中等\(i)", difficulty: .medium))
        }

        for i in 0..<hardCount {
            items.append(ReviewItem(title: "困难\(i)", difficulty: .hard))
        }

        return items
    }

    private func createMockItemsWithReviewCounts(_ counts: [Int]) -> [ReviewItem] {
        counts.enumerated().map { index, count in
            let reviewItem = ReviewItem(title: "题目\(index)")
            reviewItem.reviewCount = count
            return reviewItem
        }
    }
}
