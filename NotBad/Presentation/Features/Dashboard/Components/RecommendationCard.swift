import SwiftUI

// MARK: - RecommendationCard
// 位置: Presentation/Features/Dashboard/Components/RecommendationCard.swift

/// 推荐卡片组件
/// 单一职责：显示单个学习推荐项，包含学科、主题、题目数量、难度和预估时间
/// 符合企业级开发标准：可复用、可测试、可维护
struct RecommendationCard: View {
    
    // MARK: - Properties
    
    /// 学科名称
    let subject: String
    
    /// 主题名称
    let topic: String
    
    /// 题目数量
    let questionCount: Int
    
    /// 难度等级
    let difficulty: DifficultyLevel
    
    /// 预估完成时间（分钟）
    let estimatedMinutes: Int
    
    /// 点击回调
    let onTap: () -> Void
    
    // MARK: - Initialization
    
    init(
        subject: String,
        topic: String,
        questionCount: Int,
        difficulty: DifficultyLevel,
        estimatedMinutes: Int,
        onTap: @escaping () -> Void
    ) {
        self.subject = subject
        self.topic = topic
        self.questionCount = questionCount
        self.difficulty = difficulty
        self.estimatedMinutes = estimatedMinutes
        self.onTap = onTap
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 学科图标区域
                subjectIconSection
                
                // 内容信息区域
                contentSection
                
                Spacer()
                
                // 箭头指示器
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Private Views
    
    /// 学科图标区域
    private var subjectIconSection: some View {
        VStack(spacing: 4) {
            Image(systemName: subjectIcon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(subject)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .lineLimit(1)
        }
        .frame(width: 50)
    }
    
    /// 内容信息区域
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 主题标题
            Text(topic)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // 详细信息标签
            HStack(spacing: 8) {
                infoLabel(
                    icon: "number.circle",
                    text: "\(questionCount)题",
                    color: .secondary
                )
                
                infoLabel(
                    icon: difficulty.icon,
                    text: difficulty.rawValue,
                    color: difficulty.color
                )
                
                infoLabel(
                    icon: "clock",
                    text: "\(estimatedMinutes)分钟",
                    color: .secondary
                )
            }
        }
    }
    
    /// 信息标签
    private func infoLabel(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
    }
    
    /// 根据学科返回对应图标
    private var subjectIcon: String {
        switch subject {
        case "数学":
            return "function"
        case "物理":
            return "atom"
        case "化学":
            return "testtube.2"
        case "英语":
            return "textbook"
        case "语文":
            return "book.closed"
        case "历史":
            return "clock.arrow.circlepath"
        case "地理":
            return "globe.asia.australia"
        case "生物":
            return "leaf"
        default:
            return "book"
        }
    }
}

// MARK: - Supporting Data Models
// TODO: 架构重构 - 将这些模型迁移到Domain层

/// 难度等级
enum DifficultyLevel: String, CaseIterable {
    case easy = "简单"
    case medium = "中等"
    case hard = "困难"
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .easy: return "1.circle"
        case .medium: return "2.circle"
        case .hard: return "3.circle"
        }
    }
}

/// 推荐数据模型
struct RecommendationData: Identifiable {
    let id = UUID()
    let subject: String
    let topic: String
    let questionCount: Int
    let difficulty: DifficultyLevel
    let estimatedMinutes: Int
    
    /// 默认推荐数据
    static let mockData: [RecommendationData] = [
        RecommendationData(
            subject: "数学",
            topic: "二次函数的图像与性质",
            questionCount: 5,
            difficulty: .medium,
            estimatedMinutes: 15
        ),
        RecommendationData(
            subject: "物理",
            topic: "力学平衡问题分析",
            questionCount: 3,
            difficulty: .hard,
            estimatedMinutes: 20
        ),
        RecommendationData(
            subject: "化学",
            topic: "有机化学反应机理",
            questionCount: 7,
            difficulty: .easy,
            estimatedMinutes: 10
        ),
        RecommendationData(
            subject: "英语",
            topic: "阅读理解长难句分析",
            questionCount: 4,
            difficulty: .medium,
            estimatedMinutes: 12
        )
    ]
}

// MARK: - Preview

#if DEBUG
struct RecommendationCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // 不同难度的推荐卡片
            RecommendationCard(
                subject: "数学",
                topic: "二次函数的图像与性质",
                questionCount: 5,
                difficulty: .medium,
                estimatedMinutes: 15,
                onTap: {
                    print("数学推荐被点击")
                }
            )
            
            RecommendationCard(
                subject: "物理",
                topic: "力学平衡问题分析",
                questionCount: 3,
                difficulty: .hard,
                estimatedMinutes: 20,
                onTap: {
                    print("物理推荐被点击")
                }
            )
            
            // 长标题测试
            RecommendationCard(
                subject: "英语",
                topic: "这是一个很长的主题标题用来测试文本换行和布局效果",
                questionCount: 8,
                difficulty: .easy,
                estimatedMinutes: 25,
                onTap: {
                    print("英语推荐被点击")
                }
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif