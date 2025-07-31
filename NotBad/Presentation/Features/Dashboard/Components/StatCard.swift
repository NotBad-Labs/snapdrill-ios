import SwiftUI

// MARK: - StatCard
// 位置: Presentation/Features/Dashboard/Components/StatCard.swift

/// 统计卡片组件
/// 单一职责：显示单个统计数据，包含图标、数值、标题和趋势
/// 符合企业级开发标准：可复用、可测试、可维护
struct StatCard: View {
    
    // MARK: - Properties
    
    /// 统计标题
    let title: String
    
    /// 统计数值
    let value: String
    
    /// 趋势百分比（可选，正数表示上升，负数表示下降）
    let trend: Double?
    
    /// 图标名称
    let icon: String
    
    /// 主题色
    let color: Color
    
    /// 点击回调
    let onTap: (() -> Void)?
    
    // MARK: - Initialization
    
    init(
        title: String,
        value: String,
        trend: Double? = nil,
        icon: String,
        color: Color,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.trend = trend
        self.icon = icon
        self.color = color
        self.onTap = onTap
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // 顶部：图标和趋势
                topSection
                
                // 底部：数值和标题
                bottomSection
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(onTap == nil) // 如果没有回调，禁用点击
    }
    
    // MARK: - Private Views
    
    /// 顶部区域：图标和趋势指示器
    private var topSection: some View {
        HStack {
            // 主题图标
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Spacer()
            
            // 趋势指示器
            if let trend = trend {
                trendIndicator(trend)
            }
        }
    }
    
    /// 底部区域：数值和标题
    private var bottomSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            // 主要数值
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // 标题说明
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    /// 趋势指示器
    private func trendIndicator(_ trend: Double) -> some View {
        HStack(spacing: 2) {
            Image(systemName: trend >= 0 ? "arrow.up" : "arrow.down")
                .font(.caption)
            
            Text("\(Int(abs(trend)))%")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(trendColor(trend))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(trendColor(trend).opacity(0.1))
        .cornerRadius(4)
    }
    
    /// 趋势颜色
    private func trendColor(_ trend: Double) -> Color {
        return trend >= 0 ? .green : .red
    }
}

// MARK: - StatCardData
// TODO: 架构重构 - 将数据模型迁移到Domain层

/// 统计卡片数据模型
struct StatCardData: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let trend: Double?
    let icon: String
    let color: Color
    
    /// 默认的统计卡片数据
    static let mockData: [StatCardData] = [
        StatCardData(
            title: "学习时长",
            value: "2.5h",
            trend: 12.0,
            icon: "clock.fill",
            color: .blue
        ),
        StatCardData(
            title: "完成题目",
            value: "15",
            trend: 8.0,
            icon: "checkmark.circle.fill",
            color: .green
        ),
        StatCardData(
            title: "正确率",
            value: "85%",
            trend: 5.0,
            icon: "target",
            color: .orange
        ),
        StatCardData(
            title: "连续天数",
            value: "7天",
            trend: nil, // 连续天数不显示趋势
            icon: "flame.fill",
            color: .red
        )
    ]
}

// MARK: - Preview

#if DEBUG
struct StatCard_Previews: PreviewProvider {
    static var previews: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            // 正常状态：有趋势数据
            StatCard(
                title: "学习时长",
                value: "2.5h",
                trend: 12.0,
                icon: "clock.fill",
                color: .blue,
                onTap: {
                    print("学习时长卡片被点击")
                }
            )
            
            // 下降趋势
            StatCard(
                title: "完成题目",
                value: "15",
                trend: -3.0,
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            // 无趋势数据
            StatCard(
                title: "连续天数",
                value: "7天",
                trend: nil,
                icon: "flame.fill",
                color: .red
            )
            
            // 零趋势
            StatCard(
                title: "正确率",
                value: "85%",
                trend: 0.0,
                icon: "target",
                color: .orange
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif