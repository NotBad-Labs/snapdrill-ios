//
//  DashboardAnalyticsView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  高级统计卡片区 — 分类趋势、难度分布与待回顾分类排行。
//

import SwiftUI
import Charts
import SnapDrillCore

/// 高级统计卡片区
///
/// 嵌入 Dashboard 的 ScrollView 内，展示分类趋势、难度分布和待回顾较多的分类。
/// Pro 用户看真实图表，非 Pro 用户看克制的稍后推出占位。
struct DashboardAnalyticsView: View {

    let viewModel: DashboardAnalyticsViewModel

    var body: some View {
        if viewModel.isProUser {
            analyticsContent
        } else {
            proGateOverlay
        }
    }

    // MARK: - Pro 内容

    @ViewBuilder
    private var analyticsContent: some View {
        VStack(spacing: 16) {
            if viewModel.hasData {
                categoryTrendCard
                difficultyCard
                categoriesNeedingReviewCard
            } else {
                emptyState
            }
        }
        .padding(.horizontal)
    }

    // MARK: - 分类趋势图

    @ViewBuilder
    private var categoryTrendCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Statistics.categoryTrend)
                .font(.headline)
            Text(L10n.Statistics.last30Days)
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(viewModel.categoryTrend) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Count", point.count)
                )
                .foregroundStyle(by: .value("Category", point.category))
                .symbol(by: .value("Category", point.category))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) {
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.Statistics.categoryTrend + " " + L10n.Statistics.last30Days)
    }

    // MARK: - 难度分布

    @ViewBuilder
    private var difficultyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Statistics.difficultyDistribution)
                .font(.headline)

            Chart(viewModel.difficultyDistribution) { bucket in
                BarMark(
                    x: .value("Difficulty", bucket.difficulty),
                    y: .value("Count", bucket.count)
                )
                .foregroundStyle(difficultyColor(bucket.difficulty))
                .cornerRadius(4)
            }
            .frame(height: 160)
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.Statistics.difficultyDistribution)
    }

    // MARK: - 待回顾分类排行

    @ViewBuilder
    private var categoriesNeedingReviewCard: some View {
        if !viewModel.categoriesNeedingReview.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.Statistics.categoriesNeedingReview)
                    .font(.headline)
                Text(L10n.Statistics.categoriesNeedingReviewHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(viewModel.categoriesNeedingReview) { item in
                    HStack {
                        Text(item.category)
                            .font(.subheadline)
                        Spacer()
                        Text(L10n.Statistics.dueCount(item.dueCount))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
        }
    }

    // MARK: - 空状态

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(L10n.Statistics.noData)
                .font(.headline)
            Text(L10n.Statistics.noDataHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    // MARK: - Pro 门控

    @ViewBuilder
    private var proGateOverlay: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.tertiarySystemBackground))
                .frame(height: 200)
                .accessibilityIdentifier("dashboard.analytics.proGate")
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text(L10n.Statistics.proRequired)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func difficultyColor(_ level: Int) -> Color {
        switch level {
        case 1: .green
        case 2: .blue
        case 3: .orange
        case 4: .red
        case 5: .purple
        default: .gray
        }
    }
}
