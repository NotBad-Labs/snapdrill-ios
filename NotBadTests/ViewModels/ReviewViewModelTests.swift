//
//  ReviewViewModelTests.swift
//  NotBadTests
//
//  ReviewViewModel 单元测试
//

import Testing
import Foundation
@testable import NotBad

@Suite("ReviewViewModel 测试")
@MainActor
struct ReviewViewModelTests {

    // MARK: - 测试辅助方法

    private func createTestItems() -> [ReviewItem] {
        let now = Date()
        let pastDate = Calendar.current.date(byAdding: .day, value: -10, to: now)!

        return [
            createItem(title: "逾期题1", mastery: .none, createdAt: pastDate, isOverdue: true),
            createItem(title: "今日题1", mastery: .partial, createdAt: now, needsReview: true),
            createItem(title: "今日题2", mastery: .glimpse, createdAt: now, needsReview: true),
            createItem(title: "已掌握", mastery: .mastered, createdAt: now, needsReview: false),
            createItem(title: "良好", mastery: .good, createdAt: now, needsReview: false)
        ]
    }

    private func createItem(
        title: String,
        mastery: MasteryLevel,
        createdAt: Date,
        needsReview: Bool = false,
        isOverdue: Bool = false
    ) -> ReviewItem {
        let item = ReviewItem(title: title, mastery: mastery)
        item.createdAt = createdAt

        if isOverdue {
            item.nextReviewDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        } else if needsReview {
            item.nextReviewDate = Date()
        } else {
            item.nextReviewDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        }

        return item
    }

    // MARK: - 初始化测试

    @Test("初始状态正确")
    func initialState() {
        let viewModel = ReviewViewModel()

        #expect(viewModel.currentIndex == 0)
        #expect(viewModel.sessionState == .idle)
        #expect(viewModel.showCompletionAlert == false)
        #expect(viewModel.showExitConfirmation == false)
        #expect(viewModel.reviewedCount == 0)
        #expect(viewModel.reviewMode == .smart)
        #expect(viewModel.filterSubject == nil)
        #expect(viewModel.batchSize == 20)
    }

    // MARK: - 队列生成测试

    @Test("智能模式生成正确队列")
    func smartModeQueueGeneration() {
        let viewModel = ReviewViewModel()
        viewModel.reviewMode = .smart

        let items = createTestItems()
        let queue = viewModel.generateReviewQueue(from: items)

        // 智能模式只返回需要复习的（nextReviewDate <= now）
        for item in queue {
            #expect(item.needsReview == true)
        }

        // 验证队列非空（应该有需要复习的项）
        // 测试数据中有 3 个需要复习的项
        #expect(!queue.isEmpty)
    }

    @Test("薄弱项模式按掌握程度排序")
    func weakestModeQueueGeneration() {
        let viewModel = ReviewViewModel()
        viewModel.reviewMode = .weakest

        let items = createTestItems()
        let queue = viewModel.generateReviewQueue(from: items)

        // 按掌握程度从低到高排序
        for i in 1..<queue.count {
            #expect(queue[i-1].masteryLevel <= queue[i].masteryLevel)
        }
    }

    @Test("最新添加模式按创建时间排序")
    func newestModeQueueGeneration() {
        let viewModel = ReviewViewModel()
        viewModel.reviewMode = .newest

        let items = createTestItems()
        let queue = viewModel.generateReviewQueue(from: items)

        // 按创建时间从新到旧排序
        for i in 1..<queue.count {
            #expect(queue[i-1].createdAt >= queue[i].createdAt)
        }
    }

    @Test("仅逾期模式只返回逾期项")
    func overdueModeQueueGeneration() {
        let viewModel = ReviewViewModel()
        viewModel.reviewMode = .overdue

        let items = createTestItems()
        let queue = viewModel.generateReviewQueue(from: items)

        // 只返回逾期的
        for item in queue {
            #expect(item.isOverdue == true)
        }
    }

    @Test("学科筛选正确")
    func subjectFilterQueueGeneration() {
        let viewModel = ReviewViewModel()
        viewModel.filterSubject = .math

        let item1 = ReviewItem(title: "数学题", subject: .math)
        item1.nextReviewDate = Date()
        let item2 = ReviewItem(title: "物理题", subject: .physics)
        item2.nextReviewDate = Date()

        let queue = viewModel.generateReviewQueue(from: [item1, item2])

        // 只返回数学题
        for item in queue {
            #expect(item.subject == .math)
        }
    }

    @Test("batchSize 限制队列数量")
    func batchSizeLimitsQueue() {
        let viewModel = ReviewViewModel()
        viewModel.batchSize = 3
        viewModel.reviewMode = .weakest

        let items = (0..<10).map { _ in
            let item = ReviewItem()
            item.nextReviewDate = Date()
            return item
        }

        let queue = viewModel.generateReviewQueue(from: items)

        #expect(queue.count <= 3)
    }

    // MARK: - 当前项目测试

    @Test("currentItem 返回正确项目")
    func currentItemReturnsCorrectItem() {
        let viewModel = ReviewViewModel()
        let items = createTestItems()
        viewModel.currentIndex = 1

        let current = viewModel.currentItem(from: items)

        #expect(current === items[1])
    }

    @Test("currentItem 越界返回nil")
    func currentItemOutOfBoundsReturnsNil() {
        let viewModel = ReviewViewModel()
        let items = createTestItems()
        viewModel.currentIndex = 100

        let current = viewModel.currentItem(from: items)

        #expect(current == nil)
    }

    // MARK: - 进度计算测试

    @Test("progress 计算正确")
    func progressCalculation() {
        let viewModel = ReviewViewModel()
        viewModel.currentIndex = 2

        let progress = viewModel.progress(totalCount: 10)

        #expect(progress == 0.2)
    }

    @Test("空队列 progress 返回0")
    func progressEmptyQueue() {
        let viewModel = ReviewViewModel()

        let progress = viewModel.progress(totalCount: 0)

        #expect(progress == 0)
    }

    @Test("progressDescription 格式正确")
    func progressDescriptionFormat() {
        let viewModel = ReviewViewModel()
        viewModel.currentIndex = 2

        let desc = viewModel.progressDescription(totalCount: 10)

        #expect(desc == "3 / 10")
    }

    // MARK: - 会话控制测试

    @Test("startSession 正确初始化")
    func startSessionInitialization() {
        let viewModel = ReviewViewModel()

        viewModel.startSession()

        #expect(viewModel.sessionState == .inProgress)
        #expect(viewModel.sessionStartTime != nil)
        #expect(viewModel.currentIndex == 0)
        #expect(viewModel.reviewedCount == 0)
        #expect(viewModel.masteryResults.isEmpty)
    }

    @Test("pauseSession 更新状态")
    func pauseSessionState() {
        let viewModel = ReviewViewModel()
        viewModel.startSession()

        viewModel.pauseSession()

        #expect(viewModel.sessionState == .paused)
    }

    @Test("resumeSession 更新状态")
    func resumeSessionState() {
        let viewModel = ReviewViewModel()
        viewModel.startSession()
        viewModel.pauseSession()

        viewModel.resumeSession()

        #expect(viewModel.sessionState == .inProgress)
    }

    @Test("endSession 更新状态")
    func endSessionState() {
        let viewModel = ReviewViewModel()
        viewModel.startSession()

        viewModel.endSession()

        #expect(viewModel.sessionState == .completed)
        #expect(viewModel.showCompletionAlert == true)
    }

    @Test("reset 重置所有状态")
    func resetState() {
        let viewModel = ReviewViewModel()
        viewModel.startSession()
        viewModel.reviewedCount = 5
        viewModel.currentIndex = 3

        viewModel.reset()

        #expect(viewModel.currentIndex == 0)
        #expect(viewModel.reviewedCount == 0)
        #expect(viewModel.sessionState == .idle)
        #expect(viewModel.sessionStartTime == nil)
        #expect(viewModel.showCompletionAlert == false)
    }

    // MARK: - 导航测试

    @Test("moveToNext 递增索引")
    func moveToNextIncrementsIndex() {
        let viewModel = ReviewViewModel()
        viewModel.currentIndex = 2

        viewModel.moveToNext(totalCount: 10)

        #expect(viewModel.currentIndex == 3)
    }

    @Test("moveToNext 最后一题结束会话")
    func moveToNextEndsSession() {
        let viewModel = ReviewViewModel()
        viewModel.startSession()
        viewModel.currentIndex = 9

        viewModel.moveToNext(totalCount: 10)

        #expect(viewModel.sessionState == .completed)
    }

    @Test("moveToPrevious 递减索引")
    func moveToPreviousDecrementsIndex() {
        let viewModel = ReviewViewModel()
        viewModel.currentIndex = 3

        viewModel.moveToPrevious()

        #expect(viewModel.currentIndex == 2)
    }

    @Test("moveToPrevious 首题不变")
    func moveToPreviousAtStart() {
        let viewModel = ReviewViewModel()
        viewModel.currentIndex = 0

        viewModel.moveToPrevious()

        #expect(viewModel.currentIndex == 0)
    }

    @Test("skipCurrent 移动到下一题")
    func skipCurrentMovesToNext() {
        let viewModel = ReviewViewModel()
        viewModel.currentIndex = 2

        viewModel.skipCurrent(totalCount: 10)

        #expect(viewModel.currentIndex == 3)
    }

    // MARK: - 统计测试

    @Test("elapsedSeconds 计算正确")
    func elapsedSecondsCalculation() {
        let viewModel = ReviewViewModel()
        viewModel.sessionStartTime = Date().addingTimeInterval(-60) // 1分钟前

        #expect(viewModel.elapsedSeconds >= 59)
        #expect(viewModel.elapsedSeconds <= 62)
    }

    @Test("未开始时 elapsedSeconds 为0")
    func elapsedSecondsNotStarted() {
        let viewModel = ReviewViewModel()

        #expect(viewModel.elapsedSeconds == 0)
    }

    @Test("averageTimePerItem 计算正确")
    func averageTimePerItemCalculation() {
        let viewModel = ReviewViewModel()
        viewModel.sessionStartTime = Date().addingTimeInterval(-120)
        viewModel.reviewedCount = 4

        #expect(viewModel.averageTimePerItem >= 29)
        #expect(viewModel.averageTimePerItem <= 31)
    }

    @Test("sessionMasteryRate 计算正确")
    func sessionMasteryRateCalculation() {
        let viewModel = ReviewViewModel()
        viewModel.reviewedCount = 4
        viewModel.masteryResults = [
            .mastered: 1,
            .good: 1,
            .partial: 1,
            .none: 1
        ]

        // (1 + 1) / 4 = 0.5
        #expect(viewModel.sessionMasteryRate == 0.5)
    }

    @Test("generateSessionStatistics 生成正确统计")
    func generateSessionStatisticsGeneration() {
        let viewModel = ReviewViewModel()
        viewModel.sessionStartTime = Date().addingTimeInterval(-120)
        viewModel.reviewedCount = 5
        viewModel.masteryResults = [.mastered: 2, .good: 2, .partial: 1]

        let stats = viewModel.generateSessionStatistics()

        #expect(stats.totalReviewed == 5)
        #expect(stats.masteryRate == 0.8) // 4/5
    }

    // MARK: - ReviewMode 测试

    @Test("ReviewMode 所有选项都有属性")
    func reviewModeProperties() {
        for mode in ReviewMode.allCases {
            #expect(!mode.displayName.isEmpty)
            #expect(!mode.icon.isEmpty)
            #expect(!mode.description.isEmpty)
        }
    }

    // MARK: - ReviewSessionState 测试

    @Test("isActive 正确判断")
    func sessionStateIsActive() {
        #expect(ReviewSessionState.idle.isActive == false)
        #expect(ReviewSessionState.inProgress.isActive == true)
        #expect(ReviewSessionState.paused.isActive == true)
        #expect(ReviewSessionState.completed.isActive == false)
    }

    // MARK: - ReviewSessionStatistics 测试

    @Test("formattedDuration 格式正确")
    func formattedDurationFormat() {
        let stats1 = ReviewSessionStatistics(
            totalReviewed: 5,
            elapsedSeconds: 125,
            masteryResults: [:]
        )
        #expect(stats1.formattedDuration == "2 分 5 秒")

        let stats2 = ReviewSessionStatistics(
            totalReviewed: 5,
            elapsedSeconds: 45,
            masteryResults: [:]
        )
        #expect(stats2.formattedDuration == "45 秒")
    }

    @Test("masteryRateDescription 格式正确")
    func masteryRateDescriptionFormat() {
        let stats = ReviewSessionStatistics(
            totalReviewed: 10,
            elapsedSeconds: 60,
            masteryResults: [.mastered: 5, .good: 3, .partial: 2]
        )

        #expect(stats.masteryRateDescription == "80%")
    }

    @Test("isGoodPerformance 正确判断")
    func isGoodPerformanceCheck() {
        let goodStats = ReviewSessionStatistics(
            totalReviewed: 10,
            elapsedSeconds: 60,
            masteryResults: [.mastered: 4, .good: 3]
        )
        #expect(goodStats.isGoodPerformance == true)

        let badStats = ReviewSessionStatistics(
            totalReviewed: 10,
            elapsedSeconds: 60,
            masteryResults: [.partial: 5, .none: 5]
        )
        #expect(badStats.isGoodPerformance == false)
    }

    @Test("encouragement 返回非空字符串")
    func encouragementNotEmpty() {
        let stats = ReviewSessionStatistics(
            totalReviewed: 10,
            elapsedSeconds: 60,
            masteryResults: [.mastered: 5]
        )

        #expect(!stats.encouragement.isEmpty)
    }
}
