//
//  DashboardView.swift
//  NotBad
//
//  仪表盘视图 - 学习概览和统计
//

import SwiftUI
import SwiftData
import ReviewKit

struct DashboardView: View {
    @Query private var items: [ReviewItemModel]
    
    // MARK: - Computed Statistics
    
    private var totalCount: Int { items.count }
    
    private var pendingReviewCount: Int {
        items.filter { $0.needsReview }.count
    }
    
    private var masteredCount: Int {
        items.filter { $0.masteryLevel >= 3 }.count
    }
    
    private var masteryRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(masteredCount) / Double(totalCount)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 统计卡片
                    statisticsSection
                    
                    // 快捷操作
                    quickActionsSection
                    
                    // 今日待复习
                    if pendingReviewCount > 0 {
                        todayReviewSection
                    }
                }
                .padding()
            }
            .navigationTitle("首页")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Sections
    
    private var statisticsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "错题总数",
                value: "\(totalCount)",
                icon: "doc.text",
                color: .blue
            )
            
            StatCard(
                title: "待复习",
                value: "\(pendingReviewCount)",
                icon: "clock",
                color: .orange
            )
            
            StatCard(
                title: "已掌握",
                value: "\(masteredCount)",
                icon: "checkmark.circle",
                color: .green
            )
            
            StatCard(
                title: "掌握率",
                value: String(format: "%.0f%%", masteryRate * 100),
                icon: "chart.pie",
                color: .purple
            )
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快捷操作")
                .font(.headline)
            
            HStack(spacing: 16) {
                QuickActionButton(
                    title: "开始复习",
                    icon: "brain",
                    color: .blue
                ) {
                    // TODO: 跳转到复习页
                }
                
                QuickActionButton(
                    title: "添加错题",
                    icon: "plus.circle",
                    color: .green
                ) {
                    // TODO: 跳转到录入页
                }
            }
        }
    }
    
    private var todayReviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日待复习")
                    .font(.headline)
                Spacer()
                Text("\(pendingReviewCount) 道")
                    .foregroundStyle(.secondary)
            }
            
            // 显示前 3 个待复习项目
            ForEach(items.filter { $0.needsReview }.prefix(3)) { item in
                ItemRow(item: item)
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - StatCard

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - QuickActionButton

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityHint("双击\(title)")
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
