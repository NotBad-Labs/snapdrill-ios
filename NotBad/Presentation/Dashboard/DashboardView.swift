//
//  DashboardView.swift
//  NotBad
//
//  数据看板 - iOS 26 现代化设计
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query private var allItems: [ReviewItem]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 欢迎卡片
                    welcomeCard
                    
                    // 统计卡片
                    statisticsGrid
                    
                    // 掌握度分布
                    masteryDistributionChart
                    
                    // 学科分布
                    subjectDistributionChart
                    
                    // 快捷操作
                    quickActions
                }
                .padding()
            }
            .navigationTitle("首页")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - 欢迎卡片
    
    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello！")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("继续你的学习之旅")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.bounce)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - 统计网格
    
    private var statisticsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "总错题",
                value: "\(allItems.count)",
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
    
    // MARK: - 掌握度分布图表
    
    private var masteryDistributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("掌握度分布")
                .font(.headline)
            
            if allItems.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart {
                    ForEach(masteryData, id: \.level) { data in
                        SectorMark(
                            angle: .value("数量", data.count),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(data.color.gradient)
                        .cornerRadius(4)
                        .annotation(position: .overlay) {
                            VStack(spacing: 2) {
                                Text("\(data.count)")
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
                    ForEach(masteryData, id: \.level) { data in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(data.color)
                                .frame(width: 12, height: 12)
                            Text(data.label)
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
    
    // MARK: - 学科分布图表
    
    private var subjectDistributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学科分布")
                .font(.headline)
            
            if allItems.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(subjectData, id: \.subject) { data in
                    BarMark(
                        x: .value("数量", data.count),
                        y: .value("学科", data.subject)
                    )
                    .foregroundStyle(.blue.gradient)
                    .cornerRadius(6)
                    .annotation(position: .trailing) {
                        Text("\(data.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: CGFloat(max(subjectData.count * 40, 200)))
                .chartXAxis(.hidden)
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - 空状态占位符
    
    private var emptyChartPlaceholder: some View {
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
    
    // MARK: - 快捷操作
    
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("快捷操作")
                .font(.headline)
            
            VStack(spacing: 12) {
                NavigationLink(destination: CaptureView()) {
                    QuickActionButton(
                        title: "快速录入",
                        icon: "plus.circle.fill",
                        color: .blue
                    )
                }
                
                NavigationLink(destination: ReviewView()) {
                    QuickActionButton(
                        title: "开始复习",
                        icon: "sparkles",
                        color: .orange
                    )
                }
                
                NavigationLink(destination: LibraryView()) {
                    QuickActionButton(
                        title: "查看题库",
                        icon: "books.vertical.fill",
                        color: .green
                    )
                }
            }
        }
    }
    
    // MARK: - 计算属性
    
    private var masteredCount: Int {
        allItems.filter { $0.masteryLevel == 3 }.count
    }
    
    private var weeklyNewCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allItems.filter { $0.createdAt >= weekAgo }.count
    }
    
    private var totalReviewCount: Int {
        allItems.reduce(0) { $0 + $1.reviewCount }
    }
    
    private var masteryData: [MasteryData] {
        [
            MasteryData(level: 0, label: "不会", color: .red, count: allItems.filter { $0.masteryLevel == 0 }.count),
            MasteryData(level: 1, label: "模糊", color: .orange, count: allItems.filter { $0.masteryLevel == 1 }.count),
            MasteryData(level: 2, label: "熟悉", color: .mint, count: allItems.filter { $0.masteryLevel == 2 }.count),
            MasteryData(level: 3, label: "掌握", color: .green, count: allItems.filter { $0.masteryLevel == 3 }.count)
        ].filter { $0.count > 0 }
    }
    
    private var subjectData: [SubjectData] {
        let subjects = Dictionary(grouping: allItems, by: { $0.subject })
            .map { SubjectData(subject: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
        return subjects
    }
}

// MARK: - 统计卡片

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 快捷操作按钮

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 数据模型

struct MasteryData {
    let level: Int
    let label: String
    let color: Color
    let count: Int
}

struct SubjectData {
    let subject: String
    let count: Int
}

#Preview {
    DashboardView()
        .modelContainer(for: ReviewItem.self, inMemory: true)
}
