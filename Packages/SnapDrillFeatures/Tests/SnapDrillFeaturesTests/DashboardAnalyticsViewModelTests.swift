//
//  DashboardAnalyticsViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/04/16.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  DashboardAnalyticsViewModel 统计聚合逻辑测试：学科趋势、难度分布、薄弱学科。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillFeatureDashboard
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("DashboardAnalyticsViewModel 统计聚合测试", .serialized)
final class DashboardAnalyticsViewModelTests {

    // MARK: - 存储属性

    private let container: ModelContainer
    private let repos: RepositoryContainer

    init() throws {
        let schema = Schema([
            ReviewItemModel.self,
            TagModel.self,
            SubjectModel.self,
            SourceModel.self,
            GradeModel.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        repos = RepositoryContainer(modelContext: container.mainContext)
    }

    // MARK: - Helpers

    /// 创建测试题目并设置属性
    private func makeItem(
        content: String = "题目",
        subject: String = "数学",
        difficulty: Int = 1,
        createdAt: Date = .now,
        nextReviewAt: Date = Date.distantFuture
    ) -> ReviewItemModel {
        let item = ReviewItemModel(content: content)
        item.subjectRawValue = subject
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
        let vm = DashboardAnalyticsViewModel(repositories: repos)
        vm.loadAnalytics()

        #expect(vm.subjectTrend.isEmpty)
        // difficultyDistribution 始终有 5 个桶（1-5），空数据时全部 count=0
        #expect(!vm.difficultyDistribution.isEmpty)
        // swiftlint:disable:next empty_count
        #expect(vm.difficultyDistribution.allSatisfy { $0.count == 0 }) // DifficultyBucket.count 是 Int 属性
        #expect(vm.weakSubjects.isEmpty)
        // hasData 基于 !subjectTrend.isEmpty || !difficultyDistribution.isEmpty
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

        let vm = DashboardAnalyticsViewModel(repositories: repos)
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

    // MARK: - 薄弱学科

    @Test("薄弱学科 — 按待复习数排序取 Top 5")
    func weakSubjects_sortedByDueCount() throws {
        let now = Date.now
        let pastDue = Date(timeIntervalSinceNow: -3600) // 1小时前到期
        let future = Date.distantFuture

        // 数学: 3 道待复习
        for i in 0..<3 {
            repos.review.insert(makeItem(content: "数学\(i)", subject: "数学", nextReviewAt: pastDue))
        }
        // 英语: 2 道待复习
        for i in 0..<2 {
            repos.review.insert(makeItem(content: "英语\(i)", subject: "英语", nextReviewAt: pastDue))
        }
        // 物理: 1 道待复习 + 1 道未到期
        repos.review.insert(makeItem(content: "物理1", subject: "物理", nextReviewAt: pastDue))
        repos.review.insert(makeItem(content: "物理2", subject: "物理", nextReviewAt: future))
        // 化学: 0 道待复习（全部未到期）
        repos.review.insert(makeItem(content: "化学1", subject: "化学", nextReviewAt: future))

        try repos.review.saveContext()

        let vm = DashboardAnalyticsViewModel(repositories: repos)
        vm.loadAnalytics()

        #expect(vm.weakSubjects.count == 3) // 化学被过滤（dueCount=0）
        #expect(vm.weakSubjects[0].subject == "数学")
        #expect(vm.weakSubjects[0].dueCount == 3)
        #expect(vm.weakSubjects[1].subject == "英语")
        #expect(vm.weakSubjects[1].dueCount == 2)
        #expect(vm.weakSubjects[2].subject == "物理")
        #expect(vm.weakSubjects[2].dueCount == 1)
        #expect(vm.weakSubjects[2].totalCount == 2)
        vm.cancelTasks()
    }

    @Test("薄弱学科 — 超过 5 个学科时只取 Top 5")
    func weakSubjects_maxFive() throws {
        let pastDue = Date(timeIntervalSinceNow: -3600)
        let subjects = ["数学", "英语", "物理", "化学", "生物", "历史", "地理"]
        for (index, subject) in subjects.enumerated() {
            // 每个学科 (7-index) 道待复习，确保排序不同
            for j in 0..<(7 - index) {
                repos.review.insert(makeItem(content: "\(subject)\(j)", subject: subject, nextReviewAt: pastDue))
            }
        }
        try repos.review.saveContext()

        let vm = DashboardAnalyticsViewModel(repositories: repos)
        vm.loadAnalytics()

        #expect(vm.weakSubjects.count == 5)
        #expect(vm.weakSubjects[0].subject == "数学") // 7 道
        #expect(vm.weakSubjects[4].subject == "生物") // 3 道
        vm.cancelTasks()
    }

    // MARK: - 学科趋势

    @Test("学科趋势 — 只取 Top 3 学科")
    func subjectTrend_topThreeSubjects() throws {
        // 4 个学科，数量递减
        let subjects = [("数学", 10), ("英语", 5), ("物理", 3), ("化学", 1)]
        for (subject, count) in subjects {
            for i in 0..<count {
                repos.review.insert(makeItem(content: "\(subject)\(i)", subject: subject))
            }
        }
        try repos.review.saveContext()

        let vm = DashboardAnalyticsViewModel(repositories: repos)
        vm.loadAnalytics()

        let uniqueSubjects = Set(vm.subjectTrend.map(\.subject))
        #expect(uniqueSubjects.count == 3)
        #expect(uniqueSubjects.contains("数学"))
        #expect(uniqueSubjects.contains("英语"))
        #expect(uniqueSubjects.contains("物理"))
        #expect(!uniqueSubjects.contains("化学")) // 第 4 名被排除
        vm.cancelTasks()
    }

    @Test("学科趋势 — 30 天补零确保每天每学科都有数据点")
    func subjectTrend_zeroFilling() throws {
        // 只在今天创建 1 道数学题
        repos.review.insert(makeItem(subject: "数学"))
        try repos.review.saveContext()

        let vm = DashboardAnalyticsViewModel(repositories: repos)
        vm.loadAnalytics()

        // 1 个学科 x 30 天 = 30 个数据点
        #expect(vm.subjectTrend.count == 30)

        // 今天的数据点 count = 1
        let today = Calendar.current.startOfDay(for: .now)
        let todayPoint = vm.subjectTrend.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })
        #expect(todayPoint?.count == 1)

        // 昨天的数据点 count = 0（补零）
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) {
            let yesterdayPoint = vm.subjectTrend.first(where: { Calendar.current.isDate($0.date, inSameDayAs: yesterday) })
            // swiftlint:disable:next empty_count
            #expect(yesterdayPoint?.count == 0) // SubjectTrendPoint.count 是 Int 属性
        }
        vm.cancelTasks()
    }

    @Test("学科趋势 — 超过 30 天前的数据不纳入")
    func subjectTrend_excludesOldData() throws {
        // 40 天前的数据
        repos.review.insert(makeItem(subject: "数学", createdAt: daysAgo(40)))
        // 今天的数据
        repos.review.insert(makeItem(subject: "数学"))
        try repos.review.saveContext()

        let vm = DashboardAnalyticsViewModel(repositories: repos)
        vm.loadAnalytics()

        // 只有今天的那道题算入趋势
        let totalCount = vm.subjectTrend.reduce(0) { $0 + $1.count }
        #expect(totalCount == 1)
        vm.cancelTasks()
    }

    // MARK: - hasData

    @Test("hasData — 有学科趋势数据时为 true")
    func hasData_withTrend() throws {
        repos.review.insert(makeItem())
        try repos.review.saveContext()

        let vm = DashboardAnalyticsViewModel(repositories: repos)
        vm.loadAnalytics()

        #expect(vm.hasData)
        vm.cancelTasks()
    }

    // MARK: - cancelTasks

    @Test("cancelTasks — 调用后 Task 被取消")
    func cancelTasks_cleansUp() {
        let vm = DashboardAnalyticsViewModel(repositories: repos)
        vm.loadAnalytics()
        vm.cancelTasks()
        // 验证不崩溃，二次调用安全
        vm.cancelTasks()
    }

    // MARK: - 联合测试

    @Test("loadAnalytics — 三个维度同时正确聚合")
    func loadAnalytics_allDimensions() throws {
        let pastDue = Date(timeIntervalSinceNow: -3600)

        // 数学: 难度 1, 3 道, 2 道到期
        repos.review.insert(makeItem(content: "数学1", subject: "数学", difficulty: 1, nextReviewAt: pastDue))
        repos.review.insert(makeItem(content: "数学2", subject: "数学", difficulty: 1, nextReviewAt: pastDue))
        repos.review.insert(makeItem(content: "数学3", subject: "数学", difficulty: 1, nextReviewAt: .distantFuture))
        // 英语: 难度 3, 1 道, 1 道到期
        repos.review.insert(makeItem(content: "英语1", subject: "英语", difficulty: 3, nextReviewAt: pastDue))
        try repos.review.saveContext()

        let vm = DashboardAnalyticsViewModel(repositories: repos)
        vm.loadAnalytics()

        // 难度分布
        #expect(vm.difficultyDistribution.first(where: { $0.difficulty == 1 })?.count == 3)
        #expect(vm.difficultyDistribution.first(where: { $0.difficulty == 3 })?.count == 1)

        // 薄弱学科
        #expect(vm.weakSubjects.count == 2)
        #expect(vm.weakSubjects[0].subject == "数学")
        #expect(vm.weakSubjects[0].dueCount == 2)

        // 学科趋势
        let uniqueSubjects = Set(vm.subjectTrend.map(\.subject))
        #expect(uniqueSubjects.contains("数学"))
        #expect(uniqueSubjects.contains("英语"))

        #expect(vm.hasData)
        vm.cancelTasks()
    }
}
