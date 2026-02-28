//
//  ReviewViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ReviewViewModel 单元测试，验证复习会话流程管理逻辑。
//

import Testing
import Foundation
import SnapDrillDomain
import SnapDrillCore
@testable import SnapDrillFeatures

// MARK: - Mock

@MainActor
final class MockReviewSessionManager: ReviewSessionManagerProtocol {
    var dueItems: [ReviewItem] = []
    var todayReviewedCount: Int = 0
    var totalItemsCount: Int = 0

    var processSwipeResultCalls: [(item: ReviewItem, rating: ReviewRating)] = []
    var loadDueItemsError: Error?
    var processSwipeError: Error?

    func loadDueItems() throws -> [ReviewItem] {
        if let error = loadDueItemsError { throw error }
        return dueItems
    }

    func loadTodayReviewedCount() throws -> Int { todayReviewedCount }

    func loadTotalItemsCount() throws -> Int { totalItemsCount }

    func processSwipeResult(for item: ReviewItem, rating: ReviewRating) throws {
        if let error = processSwipeError { throw error }
        processSwipeResultCalls.append((item: item, rating: rating))
    }
}

// MARK: - Tests

@MainActor
@Suite("ReviewViewModel 复习会话流程测试")
struct ReviewViewModelTests {

    private func makeItem(content: String = "Test") -> ReviewItem {
        ReviewItem(content: content, subject: "Math", source: "Manual", difficulty: .one)
    }

    private func makeViewModel(
        sessionManager: MockReviewSessionManager = MockReviewSessionManager()
    ) -> ReviewViewModel {
        ReviewViewModel(sessionManager: sessionManager)
    }

    @Test("loadDataAsync 正确填充 reviewQueue 和统计数字，并将 phase 切换为 idle")
    func loadDataAsyncPopulatesQueueAndStats() async {
        let manager = MockReviewSessionManager()
        manager.dueItems = [makeItem(content: "A"), makeItem(content: "B")]
        manager.todayReviewedCount = 3
        manager.totalItemsCount = 10

        let vm = makeViewModel(sessionManager: manager)
        await vm.loadDataAsync()

        #expect(vm.reviewQueue.count == 2)
        #expect(vm.reviewedTodayCount == 3)
        #expect(vm.totalItemsCount == 10)
        #expect(vm.phase == .idle)
    }

    @Test("loadDataAsync 出错时 phase 回退到 idle，不崩溃")
    func loadDataAsyncErrorFallsBackToIdle() async {
        let manager = MockReviewSessionManager()
        manager.loadDueItemsError = NSError(domain: "test", code: -1)

        let vm = makeViewModel(sessionManager: manager)
        await vm.loadDataAsync()

        #expect(vm.phase == .idle)
    }

    @Test("startSession 将 reviewQueue 设置到 workingItems，并切换到 reviewing 状态")
    func startSessionConfiguresWorkingItems() async {
        let manager = MockReviewSessionManager()
        manager.dueItems = [makeItem(), makeItem(), makeItem()]

        let vm = makeViewModel(sessionManager: manager)
        await vm.loadDataAsync()
        vm.startSession()

        #expect(vm.workingItems.count == 3)
        #expect(vm.finishedItems == 0)
        #expect(vm.undoStack.isEmpty)
        #expect(vm.isAnswerShown == false)
        #expect(vm.phase == .reviewing)
    }

    @Test("向右滑动以 .good 评分提交，队列清空后进入 finished 阶段")
    func handleSwipeGoodRatingSubmittedQueueClearsFinished() async {
        let manager = MockReviewSessionManager()
        manager.dueItems = [makeItem(content: "单道题")]

        let vm = makeViewModel(sessionManager: manager)
        await vm.loadDataAsync()
        vm.startSession()

        vm.handleSwipeCompletion(direction: 1)

        #expect(manager.processSwipeResultCalls.count == 1)
        #expect(manager.processSwipeResultCalls[0].rating == .good)
        #expect(vm.workingItems.isEmpty)
        #expect(vm.finishedItems == 1)
        #expect(vm.undoStack.count == 1)
        #expect(vm.phase == .finished)
    }

    @Test("向左滑动以 .again 评分提交")
    func handleSwipeAgainRatingSubmitted() async {
        let manager = MockReviewSessionManager()
        manager.dueItems = [makeItem()]

        let vm = makeViewModel(sessionManager: manager)
        await vm.loadDataAsync()
        vm.startSession()

        vm.handleSwipeCompletion(direction: -1)

        #expect(manager.processSwipeResultCalls.count == 1)
        #expect(manager.processSwipeResultCalls[0].rating == .again)
    }

    @Test("undoLastSwipe 恢复 workingItems，从 finished 回到 reviewing")
    func undoLastSwipeRestoresWorkingItems() async {
        let manager = MockReviewSessionManager()
        manager.dueItems = [makeItem()]

        let vm = makeViewModel(sessionManager: manager)
        await vm.loadDataAsync()
        vm.startSession()
        vm.handleSwipeCompletion(direction: 1)

        #expect(vm.phase == .finished)

        vm.undoLastSwipe()

        #expect(vm.workingItems.count == 1)
        #expect(vm.finishedItems == 0)
        #expect(vm.undoStack.isEmpty)
        #expect(vm.phase == .reviewing)
    }

    @Test("undoLastSwipe 在 undoStack 为空时不改变状态")
    func undoLastSwipeNoopWhenEmpty() async {
        let vm = makeViewModel()
        vm.handleSwipeCompletion(direction: 1) // workingItems 为空，不产生 undo

        vm.undoLastSwipe() // 应无副作用

        #expect(vm.workingItems.isEmpty)
        #expect(vm.undoStack.isEmpty)
    }

    @Test("toggleAnswer 正确切换答案显示状态")
    func toggleAnswerFlipsState() {
        let vm = makeViewModel()
        #expect(vm.isAnswerShown == false)

        vm.toggleAnswer()
        #expect(vm.isAnswerShown == true)

        vm.toggleAnswer()
        #expect(vm.isAnswerShown == false)
    }
}
