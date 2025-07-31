//
//  DiscoveryView.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/7/31.
//


//
//  DiscoveryView.swift  
//  NotBad
//
//  位置: Presentation/Features/Discovery/Views/DiscoveryView.swift
//  职责: Discovery发现页面主视图，负责组合各个Discovery组件
//

import SwiftUI

// MARK: - DiscoveryView

/// Discovery发现页面主视图
/// 
/// 职责：
/// - 组合来自Components文件夹的各个子组件
/// - 处理页面级别的状态（加载、错误、刷新）
/// - 管理导航栏配置
/// - 响应用户交互并委托给ViewModel处理
/// 
/// 架构说明：
/// - 遵循MVVM模式，View只负责UI展示
/// - 通过@State持有ViewModel实例
/// - 所有业务逻辑都委托给ViewModel处理
/// - 子组件来自Components文件夹，实现关注点分离
struct DiscoveryView: View {
    
    // MARK: - Properties
    
    /// ViewModel实例，负责管理页面状态和业务逻辑
    /// 使用@State确保View拥有ViewModel的生命周期
    @State private var viewModel = DiscoveryViewModel()
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部搜索栏区域
            // 固定在顶部，不随内容滚动
            // ✅ 来自: Components/DiscoverySearchBar.swift
            DiscoverySearchBar(viewModel: viewModel)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            // 主内容滚动区域
            ScrollView {
                LazyVStack(spacing: 20) {
                    
                    // 热门话题板块
                    // ✅ 来自: Components/HotTopicsView.swift
                    HotTopicsView(viewModel: viewModel)
                    
                    // 推荐内容板块
                    // TODO: 第4步 - 来自: Components/RecommendedContentView.swift
                    RecommendedContentPlaceholder(viewModel: viewModel)
                    
                    // 底部安全区域，为Tab Bar预留空间
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        // 导航栏配置
        .navigationTitle("发现")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        
        // 下拉刷新功能
        .refreshable {
            await viewModel.refreshData()
        }
        
        // 加载状态覆盖层
        .overlay {
            if viewModel.isLoading && !viewModel.hasInitialData {
                DiscoveryLoadingView()
            }
        }
        
        // 错误提示弹窗
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        
        // 页面初始化任务
        .task {
            if !viewModel.hasInitialData {
                await viewModel.refreshData()
            }
        }
    }
}

// MARK: - 临时占位组件 (仅保留未完成的组件)

/// 推荐内容占位组件
/// TODO: 第4步 - 移动到 Components/RecommendedContentView.swift
private struct RecommendedContentPlaceholder: View {
    @Bindable var viewModel: DiscoveryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 板块标题
            Text("推荐内容")
                .font(.headline)
                .fontWeight(.bold)
            
            // 内容列表
            VStack(spacing: 16) {
                ForEach(viewModel.recommendedContent) { item in
                    FeedItemPlaceholderCard(
                        item: item,
                        onTap: {
                            viewModel.viewContentDetail(item)
                        },
                        onLike: {
                            viewModel.likeContent(item)
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

/// 动态内容卡片占位组件
/// TODO: 第4步 - 移动到 Components/FeedItemCard.swift
private struct FeedItemPlaceholderCard: View {
    let item: FeedItem
    let onTap: () -> Void
    let onLike: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // MARK: - 用户信息头部
            HStack(spacing: 12) {
                // 用户头像（使用emoji作为占位）
                Text(item.author.avatar)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray5))
                    .cornerRadius(20)
                
                // 用户名和发布时间
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(item.author.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        // 认证用户标识
                        if item.author.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // 相对时间显示
                    Text(formatRelativeTime(item.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // MARK: - 内容区域
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 8) {
                    // 内容标题
                    Text(item.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    // 内容描述
                    Text(item.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    // 标签展示
                    if !item.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(item.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.secondary)
                                    .cornerRadius(4)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // MARK: - 交互按钮栏
            HStack(spacing: 24) {
                // 点赞按钮
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: item.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(item.isLiked ? .red : .secondary)
                        Text("\(item.likeCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // 评论按钮
                Button(action: {
                    print("评论: \(item.title)")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "message")
                            .foregroundColor(.secondary)
                        Text("\(item.commentCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // 分享按钮
                Button(action: {
                    print("分享: \(item.title)")
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .font(.subheadline)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    /// 格式化相对时间显示
    private func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            return "\(Int(interval/60))分钟前"
        } else if interval < 86400 {
            return "\(Int(interval/3600))小时前"
        } else {
            return "\(Int(interval/86400))天前"
        }
    }
}

/// Discovery加载视图
private struct DiscoveryLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("加载中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// MARK: - Preview

#if DEBUG
struct DiscoveryView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoveryView()
    }
}
#endif