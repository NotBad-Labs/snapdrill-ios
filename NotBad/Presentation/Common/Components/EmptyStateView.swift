//
//  EmptyStateView.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - EmptyStateView

/// 通用空状态视图
///
/// 用于在没有内容时向用户展示友好的空状态界面。
///
/// ## 功能特性
///
/// - 可自定义图标、标题和消息
/// - 可选的操作按钮
/// - 多种预定义状态
/// - 支持动画效果
///
/// ## 使用示例
///
/// ```swift
/// // 预定义状态
/// EmptyStateView.noItems
///
/// // 自定义状态
/// EmptyStateView(
///     icon: "folder",
///     title: "文件夹为空",
///     message: "还没有添加任何文件"
/// )
///
/// // 带操作按钮
/// EmptyStateView.networkError {
///     viewModel.refresh()
/// }
/// ```
struct EmptyStateView: View {

    // MARK: - Properties

    /// 图标名称
    let icon: String

    /// 标题文字
    let title: String

    /// 描述消息
    let message: String

    /// 操作按钮标题
    var actionTitle: String?

    /// 操作回调
    var action: (() -> Void)?

    /// 是否显示动画
    var animated: Bool = true

    /// 支持 Dynamic Type 的图标尺寸
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 64

    // MARK: - Body

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            iconView
            textContent
            actionButton
        }
        .padding(DesignTokens.Spacing.xxl + DesignTokens.Spacing.sm)
    }

    // MARK: - Subviews

    private var iconView: some View {
        Image(systemName: icon)
            .font(.system(size: iconSize))
            .foregroundStyle(
                LinearGradient(
                    colors: [.gray.opacity(0.6), .gray.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .symbolEffect(.pulse, isActive: animated)
            .accessibleDecorative()
    }

    private var textContent: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if let actionTitle, let action {
            Button(action: action) {
                Text(actionTitle)
                    .fontWeight(.semibold)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .background(Color.brand.primary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .accessibleButton(actionTitle)
        }
    }
}

// MARK: - Convenience Initializers

extension EmptyStateView {

    /// 创建带操作的空状态视图
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
}

// MARK: - Predefined States

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

    /// 筛选无结果
    static var noFilterResults: EmptyStateView {
        EmptyStateView(
            icon: "line.3.horizontal.decrease.circle",
            title: "无匹配结果",
            message: "尝试调整筛选条件"
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

    /// 加载失败
    static func loadingError(message: String = "加载失败，请稍后重试", retry: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: "出错了",
            message: message,
            actionTitle: "重试",
            action: retry
        )
    }

    /// 权限被拒绝
    static func permissionDenied(title: String, message: String, action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "lock.shield",
            title: title,
            message: message,
            actionTitle: "前往设置",
            action: action
        )
    }

    /// 摆拍无照片
    static func noCameraPermission(action: @escaping () -> Void) -> EmptyStateView {
        .permissionDenied(
            title: "无法访问相机",
            message: "需要相机权限才能拍照录入错题",
            action: action
        )
    }

    /// 今日复习完成
    static var reviewCompleted: EmptyStateView {
        EmptyStateView(
            icon: "star.fill",
            title: "今日复习完成",
            message: "继续保持，明天再来！"
        )
    }
}

// MARK: - Preview

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

#Preview("Network Error") {
    EmptyStateView.networkError {
        print("重试")
    }
}
