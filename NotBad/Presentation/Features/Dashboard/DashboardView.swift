//
//  DashboardView.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import SwiftData
import Charts

// MARK: - DashboardView

/// 数据看板视图
///
/// 展示学习数据统计和可视化图表。
///
/// ## 功能特性
///
/// - 欢迎卡片
/// - 统计数据展示
/// - 掌握度分布饼图
/// - 学科分布条形图
/// - 快捷操作入口
struct DashboardView: View {

    // MARK: - Environment

    @Query private var allModels: [ReviewItemModel]
    
    /// 将持久化模型转换为领域实体
    private var allItems: [ReviewItem] {
        allModels.map { ReviewItemMapper.toEntity(from: $0) }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    WelcomeCard()

                    StatisticsGrid(
                        totalCount: allItems.count,
                        masteredCount: masteredCount,
                        weeklyNewCount: weeklyNewCount,
                        totalReviewCount: totalReviewCount
                    )

                    MasteryDistributionChart(
                        data: masteryData,
                        isEmpty: allItems.isEmpty
                    )

                    SubjectDistributionChart(
                        data: subjectData,
                        isEmpty: allItems.isEmpty
                    )

                    quickActions
                }
                .padding()
            }
            .navigationTitle("dashboard_title")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("dashboard_quick_actions")
                .font(.headline)

            VStack(spacing: 12) {
                NavigationLink(destination: CaptureView()) {
                    QuickActionButton(
                        title: "action_quick_capture",
                        icon: "plus.circle.fill",
                        color: .blue
                    )
                }

                NavigationLink(destination: ReviewView()) {
                    QuickActionButton(
                        title: "action_start_review",
                        icon: "sparkles",
                        color: .orange
                    )
                }

                NavigationLink(destination: LibraryView()) {
                    QuickActionButton(
                        title: "action_view_library",
                        icon: "books.vertical.fill",
                        color: .green
                    )
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var masteredCount: Int {
        allItems.filter { $0.masteryLevel == MasteryLevel.mastered.rawValue }.count
    }

    private var weeklyNewCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allItems.filter { $0.createdAt >= weekAgo }.count
    }

    private var totalReviewCount: Int {
        allItems.reduce(0) { $0 + $1.reviewCount }
    }

    private var masteryData: [MasteryChartData] {
        MasteryLevel.allCases.compactMap { level in
            let count = allItems.filter { $0.masteryLevel == level.rawValue }.count
            guard count > 0 else { return nil }
            let total = max(1, allItems.count)
            return MasteryChartData(
                level: level,
                count: count,
                percentage: Double(count) / Double(total)
            )
        }
    }

    private var subjectData: [SubjectData] {
        Dictionary(grouping: allItems, by: { $0.subject })
            .map { SubjectData(subject: $0.key.displayName, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
