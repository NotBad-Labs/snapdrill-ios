import SwiftUI

// MARK: - QuickActionCard
// 位置: Presentation/Features/Dashboard/Components/QuickActionCard.swift

/// 快速操作卡片组件
/// 单一职责：显示单个快速操作，包含图标、标题和点击交互
/// 符合企业级开发标准：可复用、可测试、可维护
struct QuickActionCard: View {
    
    // MARK: - Properties
    
    /// 操作标题
    let title: String
    
    /// 图标名称
    let icon: String
    
    /// 主题色
    let color: Color
    
    /// 点击回调
    let onTap: () -> Void
    
    /// 是否启用（默认启用）
    let isEnabled: Bool
    
    // MARK: - Initialization
    
    init(
        title: String,
        icon: String,
        color: Color,
        isEnabled: Bool = true,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isEnabled = isEnabled
        self.onTap = onTap
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 图标区域
                iconSection
                
                // 标题
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isEnabled ? .primary : .secondary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // 箭头指示器
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(isEnabled ? 1.0 : 0.5)
            }
            .padding(16)
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            .scaleEffect(isEnabled ? 1.0 : 0.95)
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
    }
    
    // MARK: - Private Views
    
    /// 图标区域
    private var iconSection: some View {
        Image(systemName: icon)
            .font(.title3)
            .foregroundColor(.white)
            .frame(width: 44, height: 44)
            .background(isEnabled ? color : Color.gray)
            .cornerRadius(12)
    }
    
    /// 卡片背景
    private var cardBackground: some View {
        Color(.systemBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isEnabled ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - QuickActionData
// TODO: 架构重构 - 将数据模型迁移到Domain层

/// 快速操作数据模型
struct QuickActionData: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let actionType: ActionType
    let isEnabled: Bool
    
    enum ActionType {
        case captureQuestion
        case startPractice
        case viewAnalytics
        case reviewMistakes
        
        var description: String {
            switch self {
            case .captureQuestion: return "拍照录题"
            case .startPractice: return "开始练习"
            case .viewAnalytics: return "查看分析"
            case .reviewMistakes: return "错题复习"
            }
        }
    }
    
    /// 默认的快速操作数据
    static let mockData: [QuickActionData] = [
        QuickActionData(
            title: "拍照录题",
            icon: "camera.fill",
            color: .blue,
            actionType: .captureQuestion,
            isEnabled: true
        ),
        QuickActionData(
            title: "开始练习",
            icon: "play.fill",
            color: .green,
            actionType: .startPractice,
            isEnabled: true
        ),
        QuickActionData(
            title: "查看分析",
            icon: "chart.bar.fill",
            color: .purple,
            actionType: .viewAnalytics,
            isEnabled: true
        ),
        QuickActionData(
            title: "错题复习",
            icon: "arrow.clockwise",
            color: .orange,
            actionType: .reviewMistakes,
            isEnabled: false // 演示禁用状态
        )
    ]
}

// MARK: - Preview

#if DEBUG
struct QuickActionCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // 正常状态
            QuickActionCard(
                title: "拍照录题",
                icon: "camera.fill",
                color: .blue,
                onTap: {
                    print("拍照录题被点击")
                }
            )
            
            // 禁用状态
            QuickActionCard(
                title: "错题复习",
                icon: "arrow.clockwise",
                color: .orange,
                isEnabled: false,
                onTap: {
                    print("错题复习被点击")
                }
            )
            
            // 长标题测试
            QuickActionCard(
                title: "这是一个很长的操作标题用来测试换行",
                icon: "star.fill",
                color: .yellow,
                onTap: {
                    print("长标题操作被点击")
                }
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif