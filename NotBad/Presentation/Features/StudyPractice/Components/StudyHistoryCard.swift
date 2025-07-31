import SwiftUI

// MARK: - StudyHistoryCard
// 位置: Presentation/Features/StudyPractice/Components/StudyHistoryCard.swift

/// 学习历史卡片组件
/// 单一职责：显示单条学习记录，包含日期、时长、题目数量、分数等信息
/// 符合企业级开发标准：可复用、可测试、可维护
struct StudyHistoryCard: View {
    
    // MARK: - Properties
    
    /// 日期描述
    let dateDescription: String
    
    /// 学习时长
    let duration: String
    
    /// 题目数量
    let questionCount: Int
    
    /// 得分
    let score: Int
    
    /// 学习模式（可选）
    let studyMode: String?
    
    /// 点击回调（可选）
    let onTap: (() -> Void)?
    
    // MARK: - Initialization
    
    init(
        dateDescription: String,
        duration: String,
        questionCount: Int,
        score: Int,
        studyMode: String? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.dateDescription = dateDescription
        self.duration = duration
        self.questionCount = questionCount
        self.score = score
        self.studyMode = studyMode
        self.onTap = onTap
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: 16) {
                // 日期信息区域
                dateInfoSection
                
                // 学习详情区域
                studyDetailsSection
                
                Spacer()
                
                // 分数显示区域
                scoreSection
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(onTap == nil)
    }
    
    // MARK: - Private Views
    
    /// 日期信息区域
    private var dateInfoSection: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(dateDescription)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("\(questionCount)题")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 60)
    }
    
    /// 学习详情区域
    private var studyDetailsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                // 时长信息
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(duration)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                if let mode = studyMode {
                    // 分隔符
                    Text("·")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 模式信息
                    Text(mode)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
            }
            
            // 题目统计
            Text("完成题目: \(questionCount)道")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    /// 分数显示区域
    private var scoreSection: some View {
        VStack(spacing: 4) {
            Text("\(score)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(scoreTextColor)
            
            Text("分")
                .font(.caption)
                .foregroundColor(scoreTextColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(scoreBackgroundColor)
        .cornerRadius(8)
    }
    
    // MARK: - Private Computed Properties
    
    /// 分数背景颜色
    private var scoreBackgroundColor: Color {
        if score >= 90 {
            return Color.green.opacity(0.15)
        } else if score >= 80 {
            return Color.orange.opacity(0.15)
        } else if score >= 60 {
            return Color.yellow.opacity(0.15)
        } else {
            return Color.red.opacity(0.15)
        }
    }
    
    /// 分数文字颜色
    private var scoreTextColor: Color {
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

/// 学习历史数据模型
struct StudyHistoryData: Identifiable {
    let id = UUID()
    let date: Date
    let duration: TimeInterval // 学习时长（秒）
    let questionCount: Int
    let score: Int
    let studyModeType: StudyMode.StudyModeType?
    
    /// 日期描述（今天、昨天、具体日期）
    var dateDescription: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) == true {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd"
            return formatter.string(from: date)
        }
    }
    
    /// 时长描述
    var durationDescription: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 {
            return "\(minutes)分钟"
        } else {
            return "\(seconds)秒"
        }
    }
    
    /// 学习模式描述
    var studyModeDescription: String? {
        switch studyModeType {
        case .quickPractice:
            return "快速练习"
        case .topicPractice:
            return "专项训练"
        case .examMode:
            return "模拟考试"
        case .reviewMode:
            return "错题复习"
        case .none:
            return nil
        }
    }
    
    /// 默认学习历史数据
    static let mockData: [StudyHistoryData] = [
        StudyHistoryData(
            date: Date(), // 今天
            duration: 45 * 60, // 45分钟
            questionCount: 20,
            score: 85,
            studyModeType: .quickPractice
        ),
        StudyHistoryData(
            date: Date().addingTimeInterval(-86400), // 昨天
            duration: 38 * 60, // 38分钟
            questionCount: 15,
            score: 92,
            studyModeType: .topicPractice
        ),
        StudyHistoryData(
            date: Date().addingTimeInterval(-2 * 86400), // 前天
            duration: 52 * 60, // 52分钟
            questionCount: 25,
            score: 78,
            studyModeType: .examMode
        ),
        StudyHistoryData(
            date: Date().addingTimeInterval(-3 * 86400), // 3天前
            duration: 25 * 60, // 25分钟
            questionCount: 12,
            score: 95,
            studyModeType: .reviewMode
        ),
        StudyHistoryData(
            date: Date().addingTimeInterval(-7 * 86400), // 一周前
            duration: 60 * 60, // 60分钟
            questionCount: 30,
            score: 67,
            studyModeType: .examMode
        )
    ]
}

// MARK: - Preview

#if DEBUG
struct StudyHistoryCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            // 高分记录
            StudyHistoryCard(
                dateDescription: "今天",
                duration: "45分钟",
                questionCount: 20,
                score: 92,
                studyMode: "快速练习",
                onTap: {
                    print("今天的学习记录被点击")
                }
            )
            
            // 中等分数记录
            StudyHistoryCard(
                dateDescription: "昨天",
                duration: "38分钟",
                questionCount: 15,
                score: 85,
                studyMode: "专项训练"
            )
            
            // 低分记录
            StudyHistoryCard(
                dateDescription: "前天",
                duration: "52分钟",
                questionCount: 25,
                score: 45,
                studyMode: "模拟考试",
                onTap: {
                    print("前天的学习记录被点击")
                }
            )
            
            // 无模式记录
            StudyHistoryCard(
                dateDescription: "03-15",
                duration: "30分钟",
                questionCount: 18,
                score: 78
            )
            
            // 使用数据模型的示例
            StudyHistoryCard(
                dateDescription: StudyHistoryData.mockData[0].dateDescription,
                duration: StudyHistoryData.mockData[0].durationDescription,
                questionCount: StudyHistoryData.mockData[0].questionCount,
                score: StudyHistoryData.mockData[0].score,
                studyMode: StudyHistoryData.mockData[0].studyModeDescription,
                onTap: {
                    print("数据模型记录被点击")
                }
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif