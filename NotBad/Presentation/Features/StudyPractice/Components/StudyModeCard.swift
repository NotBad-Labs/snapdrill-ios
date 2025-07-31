import SwiftUI

// MARK: - StudyModeCard
// 位置: Presentation/Features/StudyPractice/Components/StudyModeCard.swift

/// 学习模式卡片组件
/// 单一职责：显示单个学习模式，包含图标、标题、描述和点击交互
/// 符合企业级开发标准：可复用、可测试、可维护
struct StudyModeCard: View {
    
    // MARK: - Properties
    
    /// 模式标题
    let title: String
    
    /// 模式描述
    let description: String
    
    /// 模式图标
    let icon: String
    
    /// 主题颜色
    let color: Color
    
    /// 是否启用
    let isEnabled: Bool
    
    /// 点击回调
    let onTap: () -> Void
    
    // MARK: - Initialization
    
    init(
        title: String,
        description: String,
        icon: String,
        color: Color,
        isEnabled: Bool = true,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.isEnabled = isEnabled
        self.onTap = onTap
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 模式图标区域
                modeIconSection
                
                // 模式信息区域
                modeInfoSection
                
                Spacer()
                
                // 箭头指示器
                arrowIndicator
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
    
    /// 模式图标区域
    private var modeIconSection: some View {
        Image(systemName: icon)
            .font(.title2)
            .foregroundColor(.white)
            .frame(width: 50, height: 50)
            .background(iconBackground)
            .cornerRadius(12)
    }
    
    /// 图标背景
    private var iconBackground: some View {
        Group {
            if isEnabled {
                color
            } else {
                Color.gray
            }
        }
    }
    
    /// 模式信息区域
    private var modeInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(isEnabled ? .primary : .secondary)
                .multilineTextAlignment(.leading)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
        }
    }
    
    /// 箭头指示器
    private var arrowIndicator: some View {
        Image(systemName: "chevron.right")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .opacity(isEnabled ? 1.0 : 0.5)
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

// MARK: - StudyModeCard convenience init

extension StudyModeCard {
    /// 从StudyMode创建StudyModeCard的便利初始化方法
    init(studyMode: StudyMode, onTap: @escaping () -> Void) {
        self.init(
            title: studyMode.title,
            description: studyMode.description,
            icon: studyMode.icon,
            color: studyMode.color,
            isEnabled: studyMode.isEnabled,
            onTap: onTap
        )
    }
}

// MARK: - Preview

#if DEBUG
struct StudyModeCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // 启用状态的模式卡片
            StudyModeCard(
                title: "快速练习",
                description: "随机挑选10道错题进行练习",
                icon: "bolt.fill",
                color: .blue,
                isEnabled: true,
                onTap: {
                    print("快速练习被点击")
                }
            )
            
            // 禁用状态的模式卡片
            StudyModeCard(
                title: "错题复习",
                description: "复习之前做错的题目",
                icon: "arrow.clockwise",
                color: .orange,
                isEnabled: false,
                onTap: {
                    print("错题复习被点击")
                }
            )
            
            // 长描述的模式卡片
            StudyModeCard(
                title: "专项训练",
                description: "针对特定知识点进行强化练习，帮助你突破学习难点，提升专项能力",
                icon: "target",
                color: .green,
                isEnabled: true,
                onTap: {
                    print("专项训练被点击")
                }
            )
            
            // 使用StudyMode数据的示例
            StudyModeCard(
                studyMode: StudyMode(
                    type: .examMode,
                    title: "模拟考试",
                    description: "限时模拟考试环境练习",
                    icon: "clock.fill",
                    color: .red,
                    isEnabled: true
                ),
                onTap: {
                    print("模拟考试被点击")
                }
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif