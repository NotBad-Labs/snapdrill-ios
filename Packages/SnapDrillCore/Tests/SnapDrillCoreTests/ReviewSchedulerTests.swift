//
//  ReviewSchedulerTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SM-2 间隔重复算法的核心测试。
//

import Testing
import Foundation
@testable import SnapDrillCore

struct ReviewSchedulerTests {

    private func makeItem(
        repetitions: Int = 0,
        interval: Int = 0,
        easeFactor: Double = 2.5
    ) -> ReviewItem {
        var item = ReviewItem(
            id: UUID(),
            content: "Test",
            createdAt: Date(),
            subject: .math,
            source: .textbook,
            tags: []
        )
        item.repetitions = repetitions
        item.interval = interval
        item.easeFactor = easeFactor
        return item
    }

    // MARK: - 首次复习

    @Test
    func testFirstGoodReviewSetsIntervalToOneDay() {
        let scheduler = ReviewScheduler()
        let item = makeItem()

        let result = scheduler.scheduleNextReview(for: item, rating: .good)

        #expect(result.repetitions == 1)
        #expect(result.interval == 1)
        #expect(result.lastReviewedAt != nil)
        #expect(result.nextReviewAt != nil)
    }

    @Test
    func testSecondGoodReviewSetsIntervalToSixDays() {
        let scheduler = ReviewScheduler()
        let item = makeItem(repetitions: 1, interval: 1)

        let result = scheduler.scheduleNextReview(for: item, rating: .good)

        #expect(result.repetitions == 2)
        #expect(result.interval == 6)
    }

    @Test
    func testThirdGoodReviewUsesEaseFactor() {
        let scheduler = ReviewScheduler()
        let item = makeItem(repetitions: 2, interval: 6, easeFactor: 2.5)

        let result = scheduler.scheduleNextReview(for: item, rating: .good)

        #expect(result.repetitions == 3)
        // interval = ceil(6 * newEF)，newEF ≈ 2.36
        #expect(result.interval >= 14)
        #expect(result.interval <= 16)
    }

    // MARK: - 忘记 (Again)

    @Test
    func testAgainResetsProgress() {
        let scheduler = ReviewScheduler()
        let item = makeItem(repetitions: 5, interval: 30, easeFactor: 2.6)

        let result = scheduler.scheduleNextReview(for: item, rating: .again)

        #expect(result.repetitions == 0)
        #expect(result.interval == 0)
        // 10 分钟后复习
        #expect(result.nextReviewAt != nil)
    }

    @Test
    func testAgainReducesEaseFactor() {
        let scheduler = ReviewScheduler()
        let item = makeItem(easeFactor: 2.5)

        let result = scheduler.scheduleNextReview(for: item, rating: .again)

        #expect(result.easeFactor < 2.5)
    }

    // MARK: - Ease Factor 边界 (Parameterized Test)
    
    @Test(
        "验证算法在各种极端条件下的 Ease Factor 和 Interval 推演",
        arguments: [
            // (当前EF, 基础天数, 用户操作, 期望最短天数, 期望新EF下限)
            (1.2, 5, ReviewRating.again, 0, 1.3),     // 跌破下限防御
            (2.5, 10, ReviewRating.easy, 12, 2.6),    // 正常提升
            (100.0, 365, ReviewRating.good, 365, 99.0)// 极高数据（例如未来由于脏数据写入）不要导致天数溢出或者崩溃
        ]
    )
    func extremeStateTransitions(
        easeFactor: Double,
        interval: Int,
        rating: ReviewRating,
        expectedMinInterval: Int,
        expectedMinEF: Double
    ) {
        let scheduler = ReviewScheduler()
        let item = makeItem(repetitions: 5, interval: interval, easeFactor: easeFactor)
        
        let result = scheduler.scheduleNextReview(for: item, rating: rating)
        
        #expect(result.interval >= expectedMinInterval)
        #expect(result.easeFactor >= expectedMinEF)
        #expect(result.easeFactor >= 1.3, "绝对禁止系数掉穿 1.3")
    }

    // MARK: - intervalDescription

    @Test("验证展示文案对于用户反馈的正确性")
    func testIntervalDescription() {
        let scheduler = ReviewScheduler()
        let item = makeItem()

        #expect(scheduler.intervalDescription(for: .again, from: item) == "10分钟")
        #expect(scheduler.intervalDescription(for: .good, from: item) == "明天")
    }
}
