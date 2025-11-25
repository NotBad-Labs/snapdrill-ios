//
//  EmptyStateView.swift
//  NotBad
//
//  通用空状态视图组件
//

import SwiftUI

/// 通用空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            // 图标
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.gray.opacity(0.6), .gray.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse)
            
            // 文字
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 操作按钮
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(40)
    }
}

/// 预定义的空状态类型
extension EmptyStateView {
    /// 题库空状态
    static var noItems: EmptyStateView {
        EmptyStateView(
            icon: "books.vertical",
            title: "暂无错题",
            message: "快去录入你的第一道错题吧"
        )
    }
    
    /// 复习空状态
    static var noReviewItems: EmptyStateView {
        EmptyStateView(
            icon: "checkmark.seal.fill",
            title: "暂无需要复习的错题",
            message: "太棒了！你已经掌握了所有错题"
        )
    }
    
    /// 搜索无结果
    static var noSearchResults: EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "未找到结果",
            message: "试试其他关键词或筛选条件"
        )
    }
    
    /// 网络错误
    static func networkError(retry: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "网络连接失败",
            message: "请检查网络设置后重试",
            actionTitle: "重试",
            action: retry
        )
    }
}

#Preview("No Items") {
    EmptyStateView.noItems
}

#Preview("No Review") {
    EmptyStateView.noReviewItems
}

#Preview("No Search Results") {
    EmptyStateView.noSearchResults
}

#Preview("With Action") {
    EmptyStateView(
        icon: "tray",
        title: "收件箱为空",
        message: "暂时没有新消息",
        actionTitle: "刷新",
        action: { print("刷新") }
    )
}
