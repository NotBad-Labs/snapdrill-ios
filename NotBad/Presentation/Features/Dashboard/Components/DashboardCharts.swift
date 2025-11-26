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
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "总错题",
                value: "\(totalCount)",
                icon: "books.vertical.fill",
                color: .blue
            )
            
            StatCard(
                title: "已掌握",
                value: "\(masteredCount)",
                icon: "checkmark.seal.fill",
                color: .green
            )
            
            StatCard(
                title: "本周新增",
                value: "\(weeklyNewCount)",
                icon: "plus.circle.fill",
                color: .orange
            )
            
            StatCard(
                title: "复习次数",
                value: "\(totalReviewCount)",
                icon: "clock.arrow.circlepath",
                color: .purple
            )
        }
    }
}

// MARK: - MasteryDistributionChart

/// 掌握度分布图表
struct MasteryDistributionChart: View {
    let data: [MasteryChartData]
    let isEmpty: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("掌握度分布")
                .font(.headline)
            
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
                
                // 图例
                HStack(spacing: 16) {
                    ForEach(data) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                            Text(item.label)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - SubjectDistributionChart

/// 学科分布图表
struct SubjectDistributionChart: View {
    let data: [SubjectData]
    let isEmpty: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学科分布")
                .font(.headline)
            
            if isEmpty {
                EmptyChartPlaceholder()
            } else {
                Chart(data, id: \.subject) { item in
                    BarMark(
                        x: .value("数量", item.count),
                        y: .value("学科", item.subject)
                    )
                    .foregroundStyle(.blue.gradient)
                    .cornerRadius(6)
                    .annotation(position: .trailing) {
                        Text("\(item.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: CGFloat(max(data.count * 40, 200)))
                .chartXAxis(.hidden)
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - EmptyChartPlaceholder

/// 空图表占位符
struct EmptyChartPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("暂无数据")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }
}
