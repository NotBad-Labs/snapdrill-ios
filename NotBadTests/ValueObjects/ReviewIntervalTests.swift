//
//  ReviewIntervalTests.swift
//  NotBadTests
//
//  复习间隔值对象单元测试
//

import Testing
import Foundation
@testable import NotBad

@Suite("ReviewInterval 值对象测试")
struct ReviewIntervalTests {

    // MARK: - 标准间隔序列测试

    @Test("标准间隔序列包含10个值")
    func standardIntervalsCount() {
        #expect(ReviewInterval.standardIntervals.count == 10)
    }

    @Test("标准间隔序列递增")
    func standardIntervalsAreIncreasing() {
        let intervals = ReviewInterval.standardIntervals
        for i in 1..<intervals.count {
            #expect(intervals[i] > intervals[i-1])
        }
    }

    @Test("标准间隔序列从1天开始")
    func standardIntervalsStartWithOne() {
        #expect(ReviewInterval.standardIntervals.first == 1)
    }

    @Test("标准间隔序列以365天结束")
    func standardIntervalsEndWith365() {
        #expect(ReviewInterval.standardIntervals.last == 365)
    }

    // MARK: - 工厂方法测试

    @Test("firstReview 创建正确")
    func firstReviewFactory() {
        let interval = ReviewInterval.firstReview(mastery: .none)

        #expect(interval.reviewCount == 0)
        #expect(interval.mastery == .none)
    }

    @Test("calculate 创建正确")
    func calculateFactory() {
        let interval = ReviewInterval.calculate(reviewCount: 3, mastery: .partial)

        #expect(interval.reviewCount == 3)
        #expect(interval.mastery == .partial)
    }

    @Test("next 递增复习次数")
    func nextFactoryIncrementsCount() {
        let first = ReviewInterval.firstReview(mastery: .none)
        let second = ReviewInterval.next(from: first, newMastery: .partial)

        #expect(second.reviewCount == first.reviewCount + 1)
        #expect(second.mastery == .partial)
    }

    // MARK: - 间隔计算测试

    @Test("intervalDays 根据掌握程度调整")
    func intervalDaysAdjustedByMastery() {
        // 相同复习次数，不同掌握程度
        let none = ReviewInterval.calculate(reviewCount: 1, mastery: .none)
        let partial = ReviewInterval.calculate(reviewCount: 1, mastery: .partial)
        let mastered = ReviewInterval.calculate(reviewCount: 1, mastery: .mastered)

        // 掌握程度越高，间隔越长
        #expect(none.intervalDays < partial.intervalDays)
        #expect(partial.intervalDays < mastered.intervalDays)
    }

    @Test("intervalDays 最小为1天")
    func intervalDaysMinimumIsOne() {
        let interval = ReviewInterval.calculate(reviewCount: 0, mastery: .none)
        #expect(interval.intervalDays >= 1)
    }

    @Test("nextReviewDate 在未来")
    func nextReviewDateIsInFuture() {
        let interval = ReviewInterval.firstReview(mastery: .partial)
        #expect(interval.nextReviewDate > interval.baseDate)
    }

    // MARK: - 时间状态测试

    @Test("daysUntilReview 计算正确")
    func daysUntilReviewCalculation() {
        // 创建一个基于过去日期的间隔
        let pastDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let interval = ReviewInterval.calculate(
            reviewCount: 0,
            mastery: .partial,
            from: pastDate
        )

        // 1天间隔 × 1.0（partial）= 1天，10天前创建，所以应该已逾期
        #expect(interval.daysUntilReview < 0)
    }

    @Test("isOverdue 正确判断")
    func isOverdueProperty() {
        // 过去创建的间隔应该逾期
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let overdueInterval = ReviewInterval.calculate(
            reviewCount: 0,
            mastery: .none,
            from: pastDate
        )

        #expect(overdueInterval.isOverdue == true)
    }

    @Test("overdueByDays 返回正值或零")
    func overdueByDaysProperty() {
        let interval = ReviewInterval.firstReview(mastery: .mastered)
        #expect(interval.overdueByDays >= 0)
    }

    @Test("isDueToday 包含逾期情况")
    func isDueTodayProperty() {
        // 逾期的间隔也应该返回 true
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let overdueInterval = ReviewInterval.calculate(
            reviewCount: 0,
            mastery: .none,
            from: pastDate
        )

        #expect(overdueInterval.isDueToday == true)
    }

    @Test("isDueThisWeek 正确判断")
    func isDueThisWeekProperty() {
        // 新创建的短间隔应该在本周内
        let interval = ReviewInterval.firstReview(mastery: .none)
        #expect(interval.isDueThisWeek == true)
    }

    // MARK: - 记忆保持率测试

    @Test("estimatedRetention 在0-1范围内")
    func estimatedRetentionRange() {
        let interval = ReviewInterval.firstReview(mastery: .partial)

        #expect(interval.estimatedRetention >= 0.0)
        #expect(interval.estimatedRetention <= 1.0)
    }

    @Test("retentionPercentage 在0-100范围内")
    func retentionPercentageRange() {
        let interval = ReviewInterval.firstReview(mastery: .partial)

        #expect(interval.retentionPercentage >= 0)
        #expect(interval.retentionPercentage <= 100)
    }

    @Test("retentionDescription 返回非空字符串")
    func retentionDescriptionNotEmpty() {
        for mastery in MasteryLevel.allCases {
            let interval = ReviewInterval.calculate(reviewCount: 0, mastery: mastery)
            #expect(!interval.retentionDescription.isEmpty)
        }
    }

    // MARK: - 紧迫程度测试

    @Test("urgencyLevel 在1-5范围内")
    func urgencyLevelRange() {
        // 测试不同情况
        let intervals = [
            ReviewInterval.firstReview(mastery: .mastered),
            ReviewInterval.firstReview(mastery: .none)
        ]

        for interval in intervals {
            #expect(interval.urgencyLevel >= 1)
            #expect(interval.urgencyLevel <= 5)
        }
    }

    @Test("逾期项目 urgencyLevel 为 5")
    func overdueUrgencyLevel() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let overdueInterval = ReviewInterval.calculate(
            reviewCount: 0,
            mastery: .none,
            from: pastDate
        )

        #expect(overdueInterval.urgencyLevel == 5)
    }

    @Test("urgencyDescription 返回非空字符串")
    func urgencyDescriptionNotEmpty() {
        let interval = ReviewInterval.firstReview(mastery: .partial)
        #expect(!interval.urgencyDescription.isEmpty)
    }

    @Test("urgencyShortDescription 返回非空字符串")
    func urgencyShortDescriptionNotEmpty() {
        let interval = ReviewInterval.firstReview(mastery: .partial)
        #expect(!interval.urgencyShortDescription.isEmpty)
    }

    @Test("isUrgent 正确判断")
    func isUrgentProperty() {
        // 逾期应该紧急
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let overdueInterval = ReviewInterval.calculate(
            reviewCount: 0,
            mastery: .none,
            from: pastDate
        )

        #expect(overdueInterval.isUrgent == true)
    }

    // MARK: - Comparable 测试

    @Test("Comparable 按紧迫程度排序")
    func comparableByUrgency() {
        let urgent = ReviewInterval.calculate(
            reviewCount: 0,
            mastery: .none,
            from: Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        )
        let relaxed = ReviewInterval.calculate(reviewCount: 5, mastery: .mastered)

        // 更紧急的（daysUntilReview更小）排在前面
        #expect(urgent < relaxed)
    }

    // MARK: - Identifiable 测试

    @Test("id 唯一")
    func identifiableId() {
        let interval1 = ReviewInterval.calculate(reviewCount: 1, mastery: .partial)
        let interval2 = ReviewInterval.calculate(reviewCount: 2, mastery: .good)

        #expect(interval1.id != interval2.id)
    }

    // MARK: - Codable 测试

    @Test("Codable 正确编解码")
    func codableRoundTrip() throws {
        let original = ReviewInterval.calculate(reviewCount: 3, mastery: .good)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(ReviewInterval.self, from: data)

        #expect(decoded.reviewCount == original.reviewCount)
        #expect(decoded.mastery == original.mastery)
    }

    // MARK: - 描述测试

    @Test("description 格式正确")
    func descriptionFormat() {
        let interval = ReviewInterval.firstReview(mastery: .partial)
        let desc = interval.description

        #expect(desc.contains("保持率"))
        #expect(desc.contains("%"))
    }
}
