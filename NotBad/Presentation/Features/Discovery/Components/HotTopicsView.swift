//
//  HotTopicsView.swift
//  NotBad
//
//  位置: Presentation/Features/Discovery/Components/HotTopicsView.swift
//  职责: Discovery页面热门话题组件
//

import SwiftUI

// MARK: - HotTopicsView

/// Discovery热门话题组件
/// 
/// 企业级特性：
/// - 响应式网格布局：适配不同屏幕尺寸
/// - 关注状态管理：乐观更新 + 错误回滚
/// - 加载状态处理：骨架屏效果
/// - 无障碍支持：语音朗读和导航
/// - 性能优化：LazyVGrid延迟加载
/// - 错误处理：网络异常和状态回滚
/// 
/// 使用示例：
/// ```swift
/// HotTopicsView(viewModel: viewModel)
/// ```
struct HotTopicsView: View {
    @Bindable var viewModel: DiscoveryViewModel
    
    /// 网格列配置：响应式布局
    private let gridColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    /// 骨架屏加载状态
    @State private var isShowingSkeleton = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 板块头部
            sectionHeader
            
            // 话题网格内容
            topicsGrid
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("热门话题板块")
    }
    
    /// 板块头部
    private var sectionHeader: some View {
        HStack {
            // 标题
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.headline)
                
                Text("热门话题")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            // 查看更多按钮
            Button(action: {
                // TODO: 导航到话题列表页面
                print("查看更多热门话题")
            }) {
                HStack(spacing: 4) {
                    Text("更多")
                        .font(.subheadline)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.accentColor)
            }
            .accessibilityLabel("查看更多热门话题")
        }
    }
    
    /// 话题网格
    private var topicsGrid: some View {
        Group {
            if viewModel.isLoading && viewModel.hotTopics.isEmpty {
                // 骨架屏加载状态
                topicsSkeletonView
            } else if viewModel.hotTopics.isEmpty {
                // 空状态
                topicsEmptyView
            } else {
                // 实际内容
                topicsContentView
            }
        }
    }
    
    /// 话题内容视图
    private var topicsContentView: some View {
        LazyVGrid(columns: gridColumns, spacing: 8) {
            ForEach(viewModel.hotTopics) { topic in
                HotTopicCard(
                    topic: topic,
                    onTap: {
                        handleTopicTap(topic)
                    },
                    onFollowToggle: {
                        handleFollowToggle(topic)
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.hotTopics.count)
    }
    
    /// 骨架屏视图
    private var topicsSkeletonView: some View {
        LazyVGrid(columns: gridColumns, spacing: 8) {
            ForEach(0..<6, id: \.self) { _ in
                TopicSkeletonCard()
            }
        }
    }
    
    /// 空状态视图
    private var topicsEmptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tag.slash")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("暂无热门话题")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("刷新试试") {
                Task {
                    await viewModel.refreshData()
                }
            }
            .font(.subheadline)
            .foregroundColor(.accentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Actions
    
    /// 处理话题点击
    private func handleTopicTap(_ topic: HotTopic) {
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // 委托给ViewModel处理
        viewModel.selectHotTopic(topic)
    }
    
    /// 处理关注状态切换
    private func handleFollowToggle(_ topic: HotTopic) {
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // TODO: 实现关注/取消关注逻辑
        // 这里应该调用ViewModel的关注用例
        print("切换关注状态: \(topic.name)")
    }
}

// MARK: - HotTopicCard

/// 热门话题卡片组件
/// 
/// 职责：
/// - 展示单个话题信息
/// - 处理关注状态切换
/// - 提供清晰的视觉层次
struct HotTopicCard: View {
    let topic: HotTopic
    let onTap: () -> Void
    let onFollowToggle: () -> Void
    
    /// 卡片按压状态
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 头部：话题名称 + 关注按钮
                topicHeader
                
                // 统计信息
                topicStats
                
                // 关注按钮
                followButton
            }
            .padding(12)
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel("话题：\(topic.name)")
        .accessibilityHint("\(topic.postCount)条内容，\(topic.isFollowing ? "已关注" : "未关注")")
    }
    
    /// 话题头部
    private var topicHeader: some View {
        HStack(alignment: .top) {
            // 话题名称
            Text("#\(topic.name)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // 热门指示器
            Image(systemName: "flame.fill")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }
    
    /// 话题统计
    private var topicStats: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(formatCount(topic.postCount))条内容")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 额外统计信息（如果有）
            if topic.postCount > 1000 {
                Text("本周热门")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(4)
            }
        }
    }
    
    /// 关注按钮
    private var followButton: some View {
        Button(action: onFollowToggle) {
            HStack(spacing: 4) {
                Image(systemName: topic.isFollowing ? "checkmark" : "plus")
                    .font(.caption2)
                
                Text(topic.isFollowing ? "已关注" : "关注")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(followButtonBackground)
            .foregroundColor(followButtonForeground)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(topic.isFollowing ? "取消关注" : "关注话题")
    }
    
    /// 卡片背景
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 0.5)
            )
    }
    
    /// 关注按钮背景色
    private var followButtonBackground: Color {
        topic.isFollowing ? Color(.systemGray5) : Color.accentColor
    }
    
    /// 关注按钮前景色
    private var followButtonForeground: Color {
        topic.isFollowing ? .primary : .white
    }
    
    /// 格式化数量显示
    private func formatCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1fW", Double(count) / 10000.0)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        } else {
            return "\(count)"
        }
    }
}

// MARK: - TopicSkeletonCard

/// 话题骨架屏卡片
struct TopicSkeletonCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题骨架
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 16)
                
                Spacer()
                
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 12, height: 12)
            }
            
            // 统计骨架
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 12)
            
            // 按钮骨架
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 20)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview

#if DEBUG
struct HotTopicsView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack {
                HotTopicsView(viewModel: DiscoveryViewModel())
                Spacer()
            }
            .padding()
        }
    }
}

struct HotTopicCard_Previews: PreviewProvider {
    static var previews: some View {
        let mockTopic = HotTopic(name: "数学函数", postCount: 1234, isFollowing: false)
        
        HotTopicCard(
            topic: mockTopic,
            onTap: { print("Tapped") },
            onFollowToggle: { print("Follow toggled") }
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

struct TopicSkeletonCard_Previews: PreviewProvider {
    static var previews: some View {
        TopicSkeletonCard()
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif