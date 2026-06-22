//
//  DashboardAnalyticsViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  DashboardAnalyticsViewModel 统计聚合逻辑测试：分类趋势、难度分布、薄弱分类。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillFeatureDashboard
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("DashboardAnalyticsViewModel 统计聚合测试", .serialized)
@MainActor
final class DashboardAnalyticsViewModelTests {

    // MARK: - 存储属性

    private let container: ModelContainer
    private let repos: RepositoryContainer

    init() throws {
        // L3：用 SnapDrillSchemaV1.models 并 seed 维度，makeItem 才能挂分类维度值
        let schema = Schema(SnapDrillSchemaV1.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        repos = RepositoryContainer(modelContext: container.mainContext)
        repos.dimension.seedDefaultsIfNeeded()
    }

    // MARK: - Helpers

    /// 创建测试题目并设置属性（分类经动态维度值，统计 helper categoryValueName 据此聚合）
    private func makeItem(
        content: String = "题目",
        category: String = "数学",
        difficulty: Int = 1,
        createdAt: Date = .now,
        nextReviewAt: Date = Date.distantFuture
    ) -> ReviewItemModel {
        let item = ReviewItemModel(content: content)
        if let categoryDim = try? repos.dimension.fetchDimension(bySystemKey: CategorySystemKey.category) {
            item.categoryValues = [repos.categoryValue.fetchOrCreate(name: category, in: categoryDim)]
        }
        item.difficulty = difficulty
        item.createdAt = createdAt
        item.nextReviewAt = nextReviewAt
        return item
    }

    /// 获取 N 天前的日期
    private func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
    }

    // MARK: - loadAnalytics 空数据

    @Test("loadAnalytics 空数据库 — 所有统计为空")
    func loadAnalytics_empty() {
        let vm = DashboardAnalyticsViewModel(repositories: repos, proEntitlementProvider: MockProEntitlementProvider(isProUser: false))
        vm.loadAnalytics()

        #expect(vm.categoryTrend.isEmpty)
        // difficultyDistribution 始终有 5 个桶（1-5），空数据时全部 count=0
        #expect(!vm.difficultyDistribution.isEmpty)
        // swiftlint:disable:next empty_count
        #expect(vm.difficultyDistribution.allSatisfy { $0.count == 0 }) // DifficultyBucket.count 是 Int 属性
        #expect(vm.categoriesNeedingReview.isEmpty)
        // hasData 基于 !categoryTrend.isEmpty || !difficultyDistribution.isEmpty
        // 空数据时 difficultyDistribution 仍有 5 个零桶，所以 hasData = true
        #expect(vm.hasData)
        vm.cancelTasks()
    }

    // MARK: - 难度分布

    @Test("难度分布 — 正确按 1-5 分桶")
    func difficultyDistribution_correctBuckets() throws {
        // 难度 1 x2, 难度 3 x1, 难度 5 x1
        let items = [
            makeItem(difficulty: 1),
            makeItem(difficulty: 1),
            makeItem(difficulty: 3),
            makeItem(difficulty: 5)
        ]
        for item in items { repos.review.insert(item) }
        try repos.review.saveContext()

        let vm = DashboardAnalyticsViewModel(repositories: repos, proEntitlementProvider: MockProEntitlementProvider(isProUser: false))
        vm.loadAnalytics()

        // swiftlint:disable empty_count
        #expect(vm.difficultyDistribution.count == 5)
        #expect(vm.difficultyDistribution.first(where: { $0.difficulty == 1 })?.count == 2)
        #expect(vm.difficultyDistribution.first(where: { $0.difficulty == 2 })?.count == 0)
        #expect(vm.difficultyDistribution.first(where: { $0.difficulty == 3 })?.count == 1)
        #expect(vm.difficultyDistribution.first(where: { $0.difficulty == 4 })?.count == 0)
        #expect(vm.difficultyDistribution.first(where: { $0.difficulty == 5 })?.count == 1)
        // swiftlint:enable empty_count
        #expect(vm.hasData)
        vm.cancelTasks()
    }

    // MARK: - 薄弱分类

    @Test("薄弱分类 — 按待复习数排序取 Top 5")
    func categoriesNeedingReview_sortedByDueCount() throws {
        let now = Date.now
        let pastDue = Date(timeIntervalSinceNow: -3600) // 1小时前到期
        let future = Date.distantFuture

        // 数学: 3 道待复习
        for i in 0..<3 {
            repos.review.insert(makeItem(content: "数学\(i)", category: "数学", nextReviewAt: pastDue))
        }
        // 英语: 2 道待复习
        for i in 0..<2 {
            repos.review.insert(makeItem(content: "英语\(i)", category: "英语", nextReviewAt: pastDue))
        }
        // 物理: 1 道待复习 + 1 道未到期
        repos.review.insert(makeItem(content: "物理1", category: "物理", nextReviewAt: pastDue))
        repos.review.insert(makeItem(content: "物理2", category: "物理", nextReviewAt: future))
        // 化学: 0 道待复习（全部未到期）
        repos.review.insert(makeItem(content: "化学1", category: "化学", nextReviewAt: future))

        try repos.review.saveContext()

        let vm = DashboardAnalyticsViewModel(repositories: repos, proEntitlementProvider: MockProEntitlementProvider(isProUser: false))
        vm.loadAnalytics()

        #expect(vm.categoriesNeedingReview.count == 3) // 化学被过滤（dueCount=0）
        #expect(vm.categoriesNeedingReview[0].category == "数学")
        #expect(vm.categoriesNeedingReview[0].dueCount == 3)
        #expect(vm.categoriesNeedingReview[1].category == "英语")
        #expect(vm.categoriesNeedingReview[1].dueCount == 2)
        #expect(vm.categoriesNeedingReview[2].category == "物理")
        #expect(vm.categoriesNeedingReview[2].dueCount == 1)
        #expect(vm.categoriesNeedingReview[2].totalCount == 2)
        vm.cancelTasks()
    }

    @Test("薄弱分类 — 超过 5 个分类时只取 Top 5")
    func categoriesNeedingReview_maxFive() throws {
        let pastDue = Date(timeIntervalSinceNow: -3600)
        let categories = ["数学", "英语", "物理", "化学", "生物", "历史", "地理"]
        for (index, category) in categories.enumerated() {
            // 每个分类 (7-index) 道待复习，确保排序不同
            for j in 0..<(7 - index) {
                repos.review.insert(makeItem(content: "\(category)\(j)", category: category, nextReviewAt: pastDue))
            }
        }
        try repos.review.saveContext()

        let vm = DashboardAnalyticsViewModel(repositories: repos, proEntitlementProvider: MockProEntitlementProvider(isProUser: false))
        vm.loadAnalytics()

        #expect(vm.categoriesNeedingReview.count == 5)
        #expect(vm.categoriesNeedingReview[0].category == "数学") // 7 道
        #expect(vm.categoriesNeedingReview[4].category == "生物") // 3 道
        vm.cancelTasks()
    }

    // MARK: - 分类趋势

    @Test("分类趋势 — 只取 Top 3 分类")
    func categoryTrend_topThreeCategories() throws {
        // 4 个分类，数量递减
        let categories = [("数学", 10), ("英语", 5), ("物理", 3), ("化学", 1)]
        for (category, count) in categories {
            for i in 0..<count {
                repos.review.insert(makeItem(content: "\(category)\(i)", category: category))
            }
        }
        try repos.review.saveContext()

        let vm = DashboardAnalyticsViewModel(repositories: repos, proEntitlementProvider: MockProEntitlementProvider(isProUser: false))
        vm.loadAnalytics()

        let uniqueCategories = Set(vm.categoryTrend.map(\.category))
        #expect(uniqueCategories.count == 3)
        #expect(uniqueCategories.contains("数学"))
        #expect(uniqueCategories.contains("英语"))
        #expect(uniqueCategories.contains("物理"))
        #expect(!uniqueCategories.contains("化学")) // 第 4 名被排除
        vm.cancelTasks()
    }

    @Test("分类趋势 — 30 天补零确保每天每分类都有数据点")
    func categoryTrend_zeroFilling() throws {
        // 只在今天创建 1 道数学题
        repos.review.insert(makeItem(category: "数学"))
        try repos.review.saveContext()

        let vm = DashboardAnalyticsViewModel(repositories: repos, proEntitlementProvider: MockProEntitlementProvider(isProUser: false))
        vm.loadAnalytics()

        // 1 个分类 x 30 天 = 30 个数据点
        #expect(vm.categoryTrend.count == 30)

        // 今天的数据点 count = 1
        let today = Calendar.current.startOfDay(for: .now)
        let todayPoint = vm.categoryTrend.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })
        #expect(todayPoint?.count == 1)

        // 昨天的数据点 count = 0（补零）
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) {
            let yesterdayPoint = vm.categoryTrend.first(where: { Calendar.current.isDate($0.date, inSameDayAs: yesterday) })
            // swiftlint:disable:next empty_count
            #expect(yesterdayPoint?.count == 0) // CategoryTrendPoint.count 是 Int 属性
        }
        vm.cancelTasks()
    }

    @Test("分类趋势 — 超过 30 天前的数据不纳入")
    func categoryTrend_excludesOldData() throws {
        // 40 天前的数据
        repos.review.insert(makeItem(category: "数学", createdAt: daysAgo(40)))
        // 今天的数据
        repos.review.insert(makeItem(category: "数学"))
        try repos.review.saveContext()

        let vm = DashboardAnalyticsViewModel(repositories: repos, proEntitlementProvider: MockProEntitlementProvider(isProUser: false))
        vm.loadAnalytics()

        // 只有今天的那道题算入趋势
        let totalCount = vm.categoryTrend.reduce(0) { $0 + $1.count }
        #expect(totalCount == 1)
        vm.cancelTasks()
    }

    @Test("分类趋势 — 恰好 30 天前的数据纳入 recentItems 但不在趋势点中")
    func categoryTrend_boundaryDay30() throws {
        // 恰好 30 天前的数据（在 since 范围内，但 -29...0 不包含 day -30）
        repos.review.insert(makeItem(category: "数学", createdAt: daysAgo(30)))
        // 恰好 29 天前的数据（在趋势点范围内）
        repos.review.insert(makeItem(category: "数学", createdAt: daysAgo(29)))
        try repos.review.saveContext()

        let vm = DashboardAnalyticsViewModel(repositories: repos, proEntitlementProvider: MockProEntitlementProvider(isProUser: false))
        vm.loadAnalytics()

        // 30 天前的数据被 recentItems 包含（since = startOfDay(now-30)），
        // 但补零循环只生成 -29...0 共 30 天的数据点，所以 day -30 不会出现在趋势图中。
        // 两条数据都算入 categoryTotals 用于 Top 3 选择，但趋势点只含 day -29 的那条。
        let totalCount = vm.categoryTrend.reduce(0) { $0 + $1.count }
        #expect(totalCount == 1) // 只有 day -29 的题在趋势点中
        vm.cancelTasks()
    }

    // MARK: - hasData

    @Test("hasData — 有分类趋势数据时为 true")
    func hasData_withTrend() throws {
        repos.review.insert(makeItem())
        try repos.review.saveContext()

        let vm = DashboardAnalyticsViewModel(repositories: repos, proEntitlementProvider: MockProEntitlementProvider(isProUser: false))
        vm.loadAnalytics()

        #expect(vm.hasData)
        vm.cancelTasks()
    }

    // MARK: - cancelTasks

    @Test("cancelTasks — 调用后状态安全，二次调用不崩溃")
    func cancelTasks_cleansUp() throws {
        repos.review.insert(makeItem())
        try repos.review.saveContext()

        let vm = DashboardAnalyticsViewModel(repositories: repos, proEntitlementProvider: MockProEntitlementProvider(isProUser: false))
        vm.loadAnalytics()
        #expect(vm.hasData)

        vm.cancelTasks()
        // 二次调用不崩溃
        vm.cancelTasks()
        // 取消后数据仍保留（cancelTasks 只取消后台任务，不清空已加载的数据）
        #expect(vm.hasData)
    }

    // MARK: - isProUser

    @Test("isProUser — 当前硬编码为 false")
    func isProUser_defaultFalse() {
        let vm = DashboardAnalyticsViewModel(repositories: repos, proEntitlementProvider: MockProEntitlementProvider(isProUser: false))
        #expect(!vm.isProUser)
        vm.cancelTasks()
    }

    // MARK: - 联合测试

    @Test("loadAnalytics — 三个维度同时正确聚合")
    func loadAnalytics_allDimensions() throws {
        let pastDue = Date(timeIntervalSinceNow: -3600)

        // 数学: 难度 1, 3 道, 2 道到期
        repos.review.insert(makeItem(content: "数学1", category: "数学", difficulty: 1, nextReviewAt: pastDue))
        repos.review.insert(makeItem(content: "数学2", category: "数学", difficulty: 1, nextReviewAt: pastDue))
        repos.review.insert(makeItem(content: "数学3", category: "数学", difficulty: 1, nextReviewAt: .distantFuture))
        // 英语: 难度 3, 1 道, 1 道到期
        repos.review.insert(makeItem(content: "英语1", category: "英语", difficulty: 3, nextReviewAt: pastDue))
        try repos.review.saveContext()

        let vm = DashboardAnalyticsViewModel(repositories: repos, proEntitlementProvider: MockProEntitlementProvider(isProUser: false))
        vm.loadAnalytics()

        // 难度分布
        #expect(vm.difficultyDistribution.first(where: { $0.difficulty == 1 })?.count == 3)
        #expect(vm.difficultyDistribution.first(where: { $0.difficulty == 3 })?.count == 1)

        // 薄弱分类
        #expect(vm.categoriesNeedingReview.count == 2)
        #expect(vm.categoriesNeedingReview[0].category == "数学")
        #expect(vm.categoriesNeedingReview[0].dueCount == 2)

        // 分类趋势
        let uniqueCategories = Set(vm.categoryTrend.map(\.category))
        #expect(uniqueCategories.contains("数学"))
        #expect(uniqueCategories.contains("英语"))

        #expect(vm.hasData)
        vm.cancelTasks()
    }
}
