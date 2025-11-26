//
//  DashboardCharts.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import Charts

// MARK: - StatisticsGrid

/// 统计数据网格
struct StatisticsGrid: View {
    let totalCount: Int
    let masteredCount: Int
    let weeklyNewCount: Int
    let totalReviewCount: Int
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignTokens.Spacing.lg) {
            StatCard(
                title: "总错题",
                value: "\(totalCount)",
                icon: "books.vertical.fill",
                color: Color.brand.primary
            )
            
            StatCard(
                title: "已掌握",
                value: "\(masteredCount)",
                icon: "checkmark.seal.fill",
                color: Color.brand.success
            )
            
            StatCard(
                title: "本周新增",
                value: "\(weeklyNewCount)",
                icon: "plus.circle.fill",
                color: Color.brand.warning
            )
            
            StatCard(
                title: "复习次数",
                value: "\(totalReviewCount)",
                icon: "clock.arrow.circlepath",
                color: Color.brand.secondary
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("学习统计")
    }
}

// MARK: - MasteryDistributionChart

/// 掌握度分布图表
struct MasteryDistributionChart: View {
    let data: [MasteryChartData]
    let isEmpty: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("掌握度分布")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            
            if isEmpty {
                EmptyChartPlaceholder()
            } else {
                Chart {
                    ForEach(data) { item in
                        SectorMark(
                            angle: .value("数量", item.count),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(item.color.gradient)
                        .cornerRadius(4)
                        .annotation(position: .overlay) {
                            VStack(spacing: 2) {
                                Text("\(item.count)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 200)
                .accessibilityLabel(chartAccessibilityLabel)
                
                // 图例
                HStack(spacing: DesignTokens.Spacing.lg) {
                    ForEach(data) { item in
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                                .accessibilityHidden(true)
                            Text(item.label)
                                .font(.caption)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(item.label)：\(item.count)题")
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(Color.semantic.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
    }
    
    private var chartAccessibilityLabel: String {
        let descriptions = data.map { "\($0.label)\($0.count)题" }
        return "掌握度分布图：" + descriptions.joined(separator: "，")
    }
}

// MARK: - SubjectDistributionChart

/// 学科分布图表
struct SubjectDistributionChart: View {
    let data: [SubjectData]
    let isEmpty: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("学科分布")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            
            if isEmpty {
                EmptyChartPlaceholder()
            } else {
                Chart(data, id: \.subject) { item in
                    BarMark(
                        x: .value("数量", item.count),
                        y: .value("学科", item.subject)
                    )
                    .foregroundStyle(Color.brand.primary.gradient)
                    .cornerRadius(6)
                    .annotation(position: .trailing) {
                        Text("\(item.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: CGFloat(max(data.count * 40, 200)))
                .chartXAxis(.hidden)
                .accessibilityLabel(chartAccessibilityLabel)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(Color.semantic.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
    }
    
    private var chartAccessibilityLabel: String {
        let descriptions = data.map { "\($0.subject)\($0.count)题" }
        return "学科分布图：" + descriptions.joined(separator: "，")
    }
}

// MARK: - EmptyChartPlaceholder

/// 空图表占位符
struct EmptyChartPlaceholder: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            
            Text("暂无数据")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("暂无数据")
    }
}
