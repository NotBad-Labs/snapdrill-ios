import SwiftUI

// MARK: - ActivityCard
// 位置: Presentation/Features/Dashboard/Components/ActivityCard.swift

/// 活动卡片组件
/// 单一职责：显示单个学习活动记录，包含类型、学科、描述、时间和分数
/// 符合企业级开发标准：可复用、可测试、可维护
struct ActivityCard: View {
    
    // MARK: - Properties
    
    /// 活动类型
    let activityType: ActivityType
    
    /// 学科名称
    let subject: String
    
    /// 活动描述
    let description: String
    
    /// 活动时间
    let timestamp: Date
    
    /// 分数（可选）
    let score: Int?
    
    /// 点击回调（可选）
    let onTap: (() -> Void)?
    
    // MARK: - Initialization
    
    init(
        activityType: ActivityType,
        subject: String,
        description: String,
        timestamp: Date,
        score: Int? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.activityType = activityType
        self.subject = subject
        self.description = description
        self.timestamp = timestamp
        self.score = score
        self.onTap = onTap
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: 12) {
                // 活动类型图标
                activityIconSection
                
                // 活动信息区域
                activityInfoSection
                
                Spacer()
                
                // 分数显示（如果有）
                if let score = score {
                    scoreSection(score)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(onTap == nil) // 如果没有回调，禁用点击
    }
    
    // MARK: - Private Views
    
    /// 活动类型图标区域
    private var activityIconSection: some View {
        Image(systemName: activityType.icon)
            .font(.title3)
            .foregroundColor(activityType.color)
            .frame(width: 40, height: 40)
            .background(activityType.color.opacity(0.1))
            .cornerRadius(10)
    }
    
    /// 活动信息区域
    private var activityInfoSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            // 学科名称
            Text(subject)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // 活动描述
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // 时间显示
            Text(formatRelativeTime(timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    /// 分数区域
    private func scoreSection(_ score: Int) -> some View {
        Text("\(score)分")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(scoreBackgroundColor(score))
            .foregroundColor(scoreTextColor(score))
            .cornerRadius(4)
    }
    
    // MARK: - Private Methods
    
    /// 格式化相对时间
    private func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            return "\(Int(interval/60))分钟前"
        } else if interval < 86400 {
            return "\(Int(interval/3600))小时前"
        } else if interval < 604800 { // 7天
            return "\(Int(interval/86400))天前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd"
            return formatter.string(from: date)
        }
    }
    
    /// 分数背景颜色
    private func scoreBackgroundColor(_ score: Int) -> Color {
        if score >= 90 {
            return Color.green.opacity(0.1)
        } else if score >= 80 {
            return Color.orange.opacity(0.1)
        } else if score >= 60 {
            return Color.yellow.opacity(0.1)
        } else {
            return Color.red.opacity(0.1)
        }
    }
    
    /// 分数文字颜色
    private func scoreTextColor(_ score: Int) -> Color {
        if score >= 90 {
            return .green
        } else if score >= 80 {
            return .orange
        } else if score >= 60 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Supporting Data Models
// TODO: 架构重构 - 将这些模型迁移到Domain层

/// 活动类型
enum ActivityType {
    case questionAdded
    case studyCompleted
    case achievementUnlocked
    case reviewCompleted
    case practiceStarted
    
    var icon: String {
        switch self {
        case .questionAdded: return "plus.circle.fill"
        case .studyCompleted: return "checkmark.circle.fill"
        case .achievementUnlocked: return "star.circle.fill"
        case .reviewCompleted: return "arrow.clockwise.circle.fill"
        case .practiceStarted: return "play.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .questionAdded: return .blue
        case .studyCompleted: return .green
        case .achievementUnlocked: return .yellow
        case .reviewCompleted: return .orange
        case .practiceStarted: return .purple
        }
    }
    
    var description: String {
        switch self {
        case .questionAdded: return "添加题目"
        case .studyCompleted: return "完成学习"
        case .achievementUnlocked: return "获得成就"
        case .reviewCompleted: return "完成复习"
        case .practiceStarted: return "开始练习"
        }
    }
}

/// 活动数据模型
struct ActivityData: Identifiable {
    let id = UUID()
    let activityType: ActivityType
    let subject: String
    let description: String
    let timestamp: Date
    let score: Int?
    
    /// 默认活动数据
    static let mockData: [ActivityData] = [
        ActivityData(
            activityType: .studyCompleted,
            subject: "数学",
            description: "完成二次函数练习",
            timestamp: Date().addingTimeInterval(-2 * 60), // 2分钟前
            score: 85
        ),
        ActivityData(
            activityType: .questionAdded,
            subject: "英语",
            description: "添加阅读理解错题",
            timestamp: Date().addingTimeInterval(-10 * 60), // 10分钟前
            score: nil
        ),
        ActivityData(
            activityType: .achievementUnlocked,
            subject: "系统",
            description: "获得\"学习达人\"徽章",
            timestamp: Date().addingTimeInterval(-60 * 60), // 1小时前
            score: nil
        ),
        ActivityData(
            activityType: .reviewCompleted,
            subject: "物理",
            description: "完成力学专题复习",
            timestamp: Date().addingTimeInterval(-3 * 3600), // 3小时前
            score: 92
        ),
        ActivityData(
            activityType: .practiceStarted,
            subject: "化学",
            description: "开始有机化学练习",
            timestamp: Date().addingTimeInterval(-86400), // 1天前
            score: nil
        )
    ]
}

// MARK: - Preview

#if DEBUG
struct ActivityCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            // 有分数的活动
            ActivityCard(
                activityType: .studyCompleted,
                subject: "数学",
                description: "完成二次函数练习",
                timestamp: Date().addingTimeInterval(-2 * 60),
                score: 85,
                onTap: {
                    print("学习完成活动被点击")
                }
            )
            
            // 无分数的活动
            ActivityCard(
                activityType: .questionAdded,
                subject: "英语",
                description: "添加阅读理解错题",
                timestamp: Date().addingTimeInterval(-10 * 60),
                score: nil,
                onTap: {
                    print("添加题目活动被点击")
                }
            )
            
            // 成就类活动
            ActivityCard(
                activityType: .achievementUnlocked,
                subject: "系统",
                description: "获得\"学习达人\"徽章",
                timestamp: Date().addingTimeInterval(-60 * 60)
            )
            
            // 低分数测试
            ActivityCard(
                activityType: .reviewCompleted,
                subject: "物理",
                description: "完成力学专题复习",
                timestamp: Date().addingTimeInterval(-86400),
                score: 45
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif