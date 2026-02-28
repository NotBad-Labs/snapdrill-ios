//
//  ReviewUseCaseTests.swift
//  SnapDrillDomainTests
//
//  Created by NotBad Labs on 2026/02/28.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ReviewUseCase 业务逻辑单元测试。
//

import Testing
import Foundation
@testable import SnapDrillDomain

@MainActor
struct ReviewUseCaseTests {

    // MARK: - Helpers

    private func makeUseCase() -> (ReviewUseCase, MockReviewRepository) {
        let repo = MockReviewRepository()
        let useCase = ReviewUseCase(repository: repo)
        return (useCase, repo)
    }

    private func makeItem(
        content: String = "测试题目",
        nextReviewAt: Date? = nil,
        lastReviewedAt: Date? = nil,
        createdAt: Date = Date()
    ) -> ReviewItem {
        ReviewItem(
            content: content,
            createdAt: createdAt,
            lastReviewedAt: lastReviewedAt,
            nextReviewAt: nextReviewAt
        )
    }

    // MARK: - getDueItems

    @Test("getDueItems 返回 nextReviewAt 为 nil 的条目")
    func getDueItemsIncludesNilNextReview() throws {
        let (useCase, _) = makeUseCase()
        let item = makeItem(nextReviewAt: nil)
        try useCase.captureNewItem(item)

        let dueItems = try useCase.getDueItems()
        #expect(dueItems.contains { $0.id == item.id })
    }

    @Test("getDueItems 返回已到期条目")
    func getDueItemsIncludesOverdueItems() throws {
        let (useCase, _) = makeUseCase()
        let pastDate = Date(timeIntervalSinceNow: -86400) // 昨天
        let item = makeItem(nextReviewAt: pastDate)
        try useCase.captureNewItem(item)

        let dueItems = try useCase.getDueItems()
        #expect(dueItems.contains { $0.id == item.id })
    }

    @Test("getDueItems 不返回未来的条目")
    func getDueItemsExcludesFutureItems() throws {
        let (useCase, _) = makeUseCase()
        let futureDate = Date(timeIntervalSinceNow: 86400) // 明天
        let item = makeItem(nextReviewAt: futureDate)
        try useCase.captureNewItem(item)

        let dueItems = try useCase.getDueItems()
        #expect(!dueItems.contains { $0.id == item.id })
    }

    // MARK: - captureNewItem

    @Test("captureNewItem — content 和 imagePath 同时为空时 throw invalidContent")
    func captureNewItemThrowsWhenBothContentAndImageNil() throws {
        let (useCase, _) = makeUseCase()
        let item = ReviewItem(content: nil, imagePath: nil)
        #expect(throws: DomainError.self) {
            try useCase.captureNewItem(item)
        }
    }

    @Test("captureNewItem — 仅有 imagePath 时允许保存")
    func captureNewItemAllowsImageOnlyItem() throws {
        let (useCase, _) = makeUseCase()
        let item = ReviewItem(content: nil, imagePath: "some/path.jpg")
        try useCase.captureNewItem(item)
    }

    @Test("captureNewItem 保存条目到仓库")
    func captureNewItemPersists() throws {
        let (useCase, repo) = makeUseCase()
        let item = makeItem(content: "新题目")
        try useCase.captureNewItem(item)

        #expect(repo.saveCallCount == 1)
        let fetched = try repo.fetchById(item.id)
        #expect(fetched?.content == "新题目")
    }

    // MARK: - submitReviewResult

    @Test("submitReviewResult — 评分 Easy (4) 应增加 interval")
    func submitReviewResultEasyIncreasesInterval() throws {
        let (useCase, repo) = makeUseCase()
        var item = makeItem()
        item = ReviewItem(
            id: item.id,
            content: item.content,
            easeFactor: 2.5,
            interval: 1,
            repetitions: 1
        )
        try repo.save(item)

        try useCase.submitReviewResult(id: item.id, rating: .easy)

        let updated = try repo.fetchById(item.id)
        #expect((updated?.interval ?? 0) > 1)
    }

    @Test("submitReviewResult — 评分 Again (0) 重置 repetitions")
    func submitReviewResultAgainResetsRepetitions() throws {
        let (useCase, repo) = makeUseCase()
        var item = ReviewItem(
            content: "题目",
            easeFactor: 2.5,
            interval: 5,
            repetitions: 3
        )
        try repo.save(item)

        try useCase.submitReviewResult(id: item.id, rating: .again)

        let updated = try repo.fetchById(item.id)
        #expect(updated?.repetitions == 0)
    }

    @Test("submitReviewResult — 不存在的 ID 不崩溃")
    func submitReviewResultForMissingIDSilentlyReturns() throws {
        let (useCase, _) = makeUseCase()
        // 不应 throw，静默返回
        try useCase.submitReviewResult(id: UUID(), rating: .good)
    }

    // MARK: - deleteItem

    @Test("deleteItem 从仓库中删除条目")
    func deleteItemRemovesFromRepository() throws {
        let (useCase, repo) = makeUseCase()
        let item = makeItem()
        try repo.save(item)

        try useCase.deleteItem(id: item.id)

        #expect(repo.deleteCallCount == 1)
        let fetched = try repo.fetchById(item.id)
        #expect(fetched == nil)
    }

    // MARK: - getTotalItemCount

    @Test("getTotalItemCount 返回正确数量")
    func getTotalItemCountReturnsCorrectCount() throws {
        let (useCase, _) = makeUseCase()
        try useCase.captureNewItem(makeItem(content: "A"))
        try useCase.captureNewItem(makeItem(content: "B"))
        try useCase.captureNewItem(makeItem(content: "C"))

        #expect(try useCase.getTotalItemCount() == 3)
    }
}
