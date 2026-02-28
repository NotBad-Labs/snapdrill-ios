//
//  ReviewSchedulerTests.swift
//  SnapDrillDomainTests
//
//  Created by SnapDrill Labs on 2026/02/28.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  ReviewScheduler SM-2 算法单元测试。
//

import Testing
import Foundation
@testable import SnapDrillDomain

@Suite("ReviewScheduler SM-2 算法测试")
@MainActor
struct ReviewSchedulerTests {

    // MARK: - Helpers

    private let scheduler = ReviewScheduler()

    private func makeItem(easeFactor: Double = 2.5, interval: Int = 0, repetitions: Int = 0) -> ReviewItem {
        ReviewItem(
            content: "测试题目",
            easeFactor: easeFactor,
            interval: interval,
            repetitions: repetitions
        )
    }

    // MARK: - 间隔进阶

    @Test("第 1 次答对后 interval = 1 天")
    func firstCorrectIntervalIsOne() throws {
        let item = makeItem(repetitions: 0)
        let result = scheduler.scheduleNextReview(for: item, rating: .good)
        #expect(result.interval == 1)
        #expect(result.repetitions == 1)
    }

    @Test("第 2 次答对后 interval = 6 天")
    func secondCorrectIntervalIsSix() throws {
        let item = makeItem(repetitions: 1, interval: 1)
        let result = scheduler.scheduleNextReview(for: item, rating: .good)
        #expect(result.interval == 6)
        #expect(result.repetitions == 2)
    }

    @Test("第 3 次及以后间隔 = ceil(interval × EF)")
    func thirdCorrectIntervalUsesFormula() throws {
        // interval = 6, EF = 2.5 → ceil(6 × 2.5) = 15
        let item = makeItem(easeFactor: 2.5, interval: 6, repetitions: 2)
        let result = scheduler.scheduleNextReview(for: item, rating: .good)
        #expect(result.interval == 15)
        #expect(result.repetitions == 3)
    }

    // MARK: - again 重置

    @Test("again 评分重置 repetitions 和 interval")
    func againResetsRepetitionsAndInterval() throws {
        let item = makeItem(easeFactor: 2.5, interval: 6, repetitions: 3)
        let result = scheduler.scheduleNextReview(for: item, rating: .again)
        #expect(result.repetitions == 0)
        #expect(result.interval == 0)
    }

    @Test("again 评分后 nextReviewAt 约为 10 分钟内")
    func againSetsNextReviewToTenMinutes() throws {
        let item = makeItem()
        let before = Date()
        let result = scheduler.scheduleNextReview(for: item, rating: .again)
        let after = Date()

        let tenMinutes: TimeInterval = 10 * 60
        guard let nextReview = result.nextReviewAt else {
            Issue.record("nextReviewAt 不应为 nil")
            return
        }
        #expect(nextReview >= before.addingTimeInterval(tenMinutes - 1))
        #expect(nextReview <= after.addingTimeInterval(tenMinutes + 1))
    }

    // MARK: - EF 计算

    @Test("easy 评分使 EF 增加 0.1")
    func easyRatingIncreasesEF() throws {
        let item = makeItem(easeFactor: 2.5, repetitions: 1, interval: 1)
        let result = scheduler.scheduleNextReview(for: item, rating: .easy)
        #expect(abs(result.easeFactor - 2.6) < 0.001)
    }

    @Test("good 评分使 EF 减少 0.14")
    func goodRatingDecreasesEF() throws {
        let item = makeItem(easeFactor: 2.5, repetitions: 1, interval: 1)
        let result = scheduler.scheduleNextReview(for: item, rating: .good)
        #expect(abs(result.easeFactor - 2.36) < 0.001)
    }

    @Test("hard 评分使 EF 减少 0.32")
    func hardRatingDecreasesEF() throws {
        let item = makeItem(easeFactor: 2.5, repetitions: 1, interval: 1)
        let result = scheduler.scheduleNextReview(for: item, rating: .hard)
        #expect(abs(result.easeFactor - 2.18) < 0.001)
    }

    // MARK: - EF 下界保护

    @Test("EF 不会低于最小值 1.3")
    func efNeverDropsBelowMinimum() throws {
        // 从最小值 EF=1.3 再次 again 评分，应保持 1.3
        let item = makeItem(easeFactor: 1.3, repetitions: 1, interval: 1)
        let result = scheduler.scheduleNextReview(for: item, rating: .again)
        #expect(result.easeFactor >= 1.3)
    }

    @Test("EF 在多次 hard 评分后不低于 1.3")
    func efStaysAboveMinimumAfterRepeatedHard() throws {
        var item = makeItem(easeFactor: 1.4, repetitions: 2, interval: 6)
        for _ in 0..<10 {
            item = scheduler.scheduleNextReview(for: item, rating: .hard)
        }
        #expect(item.easeFactor >= 1.3)
    }

    // MARK: - lastReviewedAt 更新

    @Test("复习后 lastReviewedAt 被更新")
    func reviewUpdatesLastReviewedAt() throws {
        let item = makeItem(repetitions: 0)
        let before = Date()
        let result = scheduler.scheduleNextReview(for: item, rating: .good)
        let after = Date()

        guard let last = result.lastReviewedAt else {
            Issue.record("lastReviewedAt 不应为 nil")
            return
        }
        #expect(last >= before)
        #expect(last <= after)
    }

    // MARK: - intervalDescription

    @Test("again 的 intervalDescription 为 10分钟")
    func againIntervalDescriptionIsTenMinutes() throws {
        let item = makeItem()
        let desc = scheduler.intervalDescription(for: .again, from: item)
        #expect(desc == "10分钟")
    }

    @Test("1 天间隔的 intervalDescription 为 明天")
    func oneDayIntervalDescriptionIsTomorrow() throws {
        let item = makeItem(repetitions: 0)
        let desc = scheduler.intervalDescription(for: .good, from: item)
        #expect(desc == "明天")
    }
}
