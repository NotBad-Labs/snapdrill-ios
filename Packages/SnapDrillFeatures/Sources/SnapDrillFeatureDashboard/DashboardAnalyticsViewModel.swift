//
//  DashboardAnalyticsViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/04/08.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  高级统计 ViewModel — 按天聚合学科趋势、难度分布、薄弱学科排行。
//

import Foundation
import Observation
import SnapDrillCore
import SnapDrillData

// MARK: - 数据模型

/// 学科趋势数据点（按天 × 学科）
nonisolated struct SubjectTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let subject: String
    let count: Int
}

/// 难度分布数据点
nonisolated struct DifficultyBucket: Identifiable {
    let id = UUID()
    let difficulty: Int
    let count: Int
}

/// 薄弱学科排行项
nonisolated struct WeakSubjectItem: Identifiable {
    let id = UUID()
    let subject: String
    let dueCount: Int
    let totalCount: Int
}

// MARK: - ViewModel

/// 高级统计 ViewModel
///
/// 从 ReviewRepository 获取原始数据，在内存层按天/学科/难度聚合。
/// 聚合在 ViewModel 而非 Repository，因为 SwiftData #Predicate 不支持 GROUP BY。
@Observable
final class DashboardAnalyticsViewModel {

    // MARK: - 输出状态

    /// 学科趋势（最近 30 天，按天 × 学科）
    private(set) var subjectTrend: [SubjectTrendPoint] = []

    /// 难度分布（全量）
    private(set) var difficultyDistribution: [DifficultyBucket] = []

    /// 薄弱学科排行（Top 5）
    private(set) var weakSubjects: [WeakSubjectItem] = []

    /// 是否有数据
    var hasData: Bool { !subjectTrend.isEmpty || !difficultyDistribution.isEmpty }

    // MARK: - 依赖

    private let repositories: RepositoryContainer

    @ObservationIgnored
    private var dataChangeTask: Task<Void, Never>?
    @ObservationIgnored
    private var pendingRefreshTask: Task<Void, Never>?

    // MARK: - Pro 门控

    // TODO: 替换为 StoreKit 订阅状态检查（#479 就绪后）
    var isProUser: Bool { true }

    init(repositories: RepositoryContainer) {
        self.repositories = repositories
        setupDataChangeObserver()
    }

    /// 取消所有进行中的异步任务
    func cancelTasks() {
        dataChangeTask?.cancel()
        dataChangeTask = nil
        pendingRefreshTask?.cancel()
        pendingRefreshTask = nil
    }

    // MARK: - Public API

    /// 加载全部统计数据（单次 fetch 全量数据，内存聚合三个维度）
    func loadAnalytics() {
        do {
            let allItems = try repositories.review.fetchAllModels()
            let now = Date.now
            // startOfDay 对齐，确保首日 00:00 起的数据不被遗漏
            let rawSince = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
            let since = Calendar.current.startOfDay(for: rawSince)

            // 学科趋势：最近 30 天按天 × 学科
            let recentItems = allItems.filter { $0.createdAt >= since }
            subjectTrend = aggregateSubjectTrend(recentItems)

            // 难度分布：全量
            difficultyDistribution = aggregateDifficultyDistribution(allItems)

            // 薄弱学科：按待复习数排序
            weakSubjects = aggregateWeakSubjects(allItems, now: now)
        } catch {
            SnapDrillLogger.generic.error("统计数据加载失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Aggregation

    /// 按天 × 学科聚合，只取 Top 3 学科，无数据天补零
    private func aggregateSubjectTrend(_ items: [ReviewItemModel]) -> [SubjectTrendPoint] {
        var grouped: [Date: [String: Int]] = [:]
        var subjectTotals: [String: Int] = [:]
        for item in items {
            let day = Calendar.current.startOfDay(for: item.createdAt)
            grouped[day, default: [:]][item.subjectRawValue, default: 0] += 1
            subjectTotals[item.subjectRawValue, default: 0] += 1
        }

        let topSubjects = Array(
            subjectTotals.sorted { $0.value > $1.value }
                .prefix(3)
                .map(\.key)
        )

        // 补零：确保 30 天内每天每个 Top 学科都有数据点，避免 LineMark 跳过无数据日期
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var points: [SubjectTrendPoint] = []
        for dayOffset in (-29...0) {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            for subject in topSubjects {
                let count = grouped[day]?[subject] ?? 0
                points.append(SubjectTrendPoint(date: day, subject: subject, count: count))
            }
        }
        return points
    }

    /// 按 difficulty 1-5 分组
    private func aggregateDifficultyDistribution(_ items: [ReviewItemModel]) -> [DifficultyBucket] {
        var buckets: [Int: Int] = [:]
        for item in items {
            buckets[item.difficulty, default: 0] += 1
        }
        return (1...5).map { DifficultyBucket(difficulty: $0, count: buckets[$0] ?? 0) }
    }

    /// 按学科统计待复习数，取 Top 5
    private func aggregateWeakSubjects(_ items: [ReviewItemModel], now: Date) -> [WeakSubjectItem] {
        var subjectStats: [String: (total: Int, due: Int)] = [:]
        for item in items {
            var stat = subjectStats[item.subjectRawValue] ?? (total: 0, due: 0)
            stat.total += 1
            if item.nextReviewAt <= now {
                stat.due += 1
            }
            subjectStats[item.subjectRawValue] = stat
        }

        return subjectStats
            .map { WeakSubjectItem(subject: $0.key, dueCount: $0.value.due, totalCount: $0.value.total) }
            .filter { $0.dueCount > 0 }
            .sorted { $0.dueCount > $1.dueCount }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Data Change Observer

    /// 监听 reviewDataDidChange 通知，防抖 200ms 后刷新统计
    private func setupDataChangeObserver() {
        dataChangeTask = Task {
            for await _ in NotificationCenter.default.notifications(named: .reviewDataDidChange) {
                guard !Task.isCancelled else { break }
                pendingRefreshTask?.cancel()
                pendingRefreshTask = Task {
                    // best-effort: 防抖延迟
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    guard !Task.isCancelled else { return }
                    loadAnalytics()
                }
            }
        }
    }
}
