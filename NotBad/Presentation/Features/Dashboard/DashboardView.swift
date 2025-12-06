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
///
/// ## 架构设计
///
/// 使用 ViewModel + Use Cases 获取数据，不直接访问 SwiftData
struct DashboardView: View {

    // MARK: - Environment

    @Environment(\.dependencyFactory) private var dependencyFactory
    
    // MARK: - State
    
    @State private var viewModel: DashboardViewModel?

    // MARK: - Computed Properties
    
    /// 从 ViewModel 获取的错题列表
    private var allItems: [ReviewItem] {
        viewModel?.items ?? []
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    dashboardContent(viewModel: viewModel)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("dashboard_title")
            .navigationBarTitleDisplayMode(.large)
            .task {
                // 初始化 ViewModel 并加载数据
                if viewModel == nil, let factory = dependencyFactory {
                    viewModel = factory.makeDashboardViewModel()
                }
                await viewModel?.loadData()
            }
        }
    }
    
    // MARK: - Dashboard Content
    
    @ViewBuilder
    private func dashboardContent(viewModel: DashboardViewModel) -> some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
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
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("dashboard_quick_actions")
                .font(.headline)

            VStack(spacing: DesignTokens.Spacing.md) {
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
}
