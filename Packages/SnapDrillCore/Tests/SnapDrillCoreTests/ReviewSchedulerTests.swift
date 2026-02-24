//
//  ReviewSchedulerTests.swift
//  SnapDrillCoreTests
//
//  Created by SnapDrill Labs on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
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

    // MARK: - Ease Factor 边界

    @Test
    func testEaseFactorNeverBelowMinimum() {
        let scheduler = ReviewScheduler()
        // 设置一个接近最低值的 easeFactor
        let item = makeItem(easeFactor: 1.3)

        let result = scheduler.scheduleNextReview(for: item, rating: .again)

        #expect(result.easeFactor >= 1.3)
    }

    @Test
    func testEasyRatingIncreasesEaseFactor() {
        let scheduler = ReviewScheduler()
        let item = makeItem(easeFactor: 2.5)

        let result = scheduler.scheduleNextReview(for: item, rating: .easy)

        #expect(result.easeFactor > 2.5)
    }

    // MARK: - intervalDescription

    @Test
    func testIntervalDescriptionAgain() {
        let scheduler = ReviewScheduler()
        let item = makeItem()

        let desc = scheduler.intervalDescription(for: .again, from: item)

        #expect(desc == "10分钟")
    }

    @Test
    func testIntervalDescriptionFirstGood() {
        let scheduler = ReviewScheduler()
        let item = makeItem()

        let desc = scheduler.intervalDescription(for: .good, from: item)

        #expect(desc == "明天")
    }
}
