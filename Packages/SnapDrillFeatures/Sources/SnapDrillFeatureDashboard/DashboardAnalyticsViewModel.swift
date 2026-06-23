//
//  DashboardAnalyticsViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  高级统计 ViewModel — 按天聚合分类趋势与待回顾较多分类。
//

import Foundation
import Observation
import SnapDrillCore
import SnapDrillData

// MARK: - 数据模型

/// 分类趋势数据点（按天 × 分类）
nonisolated struct CategoryTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let category: String
    let count: Int
}

/// 待回顾较多分类排行项
nonisolated struct CategoryReviewLoadItem: Identifiable {
    let id = UUID()
    let category: String
    let dueCount: Int
    let totalCount: Int
}

// MARK: - ViewModel

/// 高级统计 ViewModel
///
/// 从 ReviewRepository 获取原始数据，在内存层按天/分类聚合。
/// 聚合在 ViewModel 而非 Repository，因为 SwiftData #Predicate 不支持 GROUP BY。
@MainActor
@Observable
final class DashboardAnalyticsViewModel {

    // MARK: - 输出状态

    /// 分类趋势（最近 30 天，按天 × 分类）
    private(set) var categoryTrend: [CategoryTrendPoint] = []

    /// 待回顾较多分类排行（Top 5）
    private(set) var categoriesNeedingReview: [CategoryReviewLoadItem] = []

    /// 是否有数据
    var hasData: Bool { !categoryTrend.isEmpty || !categoriesNeedingReview.isEmpty }

    // MARK: - 依赖

    private let repositories: RepositoryContainer
    private let proEntitlementProvider: any ProEntitlementProvider

    @ObservationIgnored
    private var dataChangeTask: Task<Void, Never>?
    @ObservationIgnored
    private var pendingRefreshTask: Task<Void, Never>?

    // MARK: - Pro 门控

    // TODO: #479 — 替换为 StoreKit 订阅状态检查
    var isProUser: Bool { proEntitlementProvider.isProUser }

    init(
        repositories: RepositoryContainer,
        proEntitlementProvider: any ProEntitlementProvider
    ) {
        self.repositories = repositories
        self.proEntitlementProvider = proEntitlementProvider
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

            // 分类趋势：最近 30 天按天 × 分类
            let recentItems = allItems.filter { $0.createdAt >= since }
            categoryTrend = aggregateCategoryTrend(recentItems)

            // 待回顾较多分类：按待回顾数排序
            categoriesNeedingReview = aggregateCategoriesNeedingReview(allItems, now: now)
        } catch {
            SnapDrillLogger.generic.error("统计数据加载失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Aggregation

    /// 资料的主分类名：category 维度的首个值名，无则「未分类」。
    private func categoryValueName(of item: ReviewItemModel) -> String {
        item.primaryCategoryName ?? L10n.Dashboard.uncategorized
    }

    /// 按天 × 分类聚合，只取 Top 3 分类，无数据天补零
    private func aggregateCategoryTrend(_ items: [ReviewItemModel]) -> [CategoryTrendPoint] {
        var grouped: [Date: [String: Int]] = [:]
        var categoryTotals: [String: Int] = [:]
        for item in items {
            let day = Calendar.current.startOfDay(for: item.createdAt)
            let category = categoryValueName(of: item)
            grouped[day, default: [:]][category, default: 0] += 1
            categoryTotals[category, default: 0] += 1
        }

        let topCategories = Array(
            categoryTotals.sorted { $0.value > $1.value }
                .prefix(3)
                .map(\.key)
        )

        // 补零：确保 30 天内每天每个 Top 分类都有数据点，避免 LineMark 跳过无数据日期
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var points: [CategoryTrendPoint] = []
        for dayOffset in (-29...0) {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            for category in topCategories {
                let count = grouped[day]?[category] ?? 0
                points.append(CategoryTrendPoint(date: day, category: category, count: count))
            }
        }
        return points
    }

    /// 按分类统计待回顾数，取 Top 5
    private func aggregateCategoriesNeedingReview(_ items: [ReviewItemModel], now: Date) -> [CategoryReviewLoadItem] {
        var categoryStats: [String: (total: Int, due: Int)] = [:]
        for item in items {
            let category = categoryValueName(of: item)
            var stat = categoryStats[category] ?? (total: 0, due: 0)
            stat.total += 1
            if item.nextReviewAt <= now {
                stat.due += 1
            }
            categoryStats[category] = stat
        }

        return categoryStats
            .map { CategoryReviewLoadItem(category: $0.key, dueCount: $0.value.due, totalCount: $0.value.total) }
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
