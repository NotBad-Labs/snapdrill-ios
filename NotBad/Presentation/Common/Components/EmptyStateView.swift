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

    /// 题库空状态 - 首次使用引导
    static func noItems(onAddTap: @escaping () -> Void) -> some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            // 主要内容
            VStack(spacing: DesignTokens.Spacing.xl) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.brand.primary, Color.brand.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse)
                
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("library_empty_welcome_title")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("library_empty_welcome_subtitle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // 使用提示卡片
            VStack(spacing: DesignTokens.Spacing.md) {
                tipRow(icon: "camera.fill", text: String(localized: "library_empty_tip_camera"))
                tipRow(icon: "brain.head.profile", text: String(localized: "library_empty_tip_ai"))
                tipRow(icon: "arrow.triangle.2.circlepath", text: String(localized: "library_empty_tip_review"))
            }
            .padding(DesignTokens.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .fill(Color(.secondarySystemBackground))
            )
            
            // 操作按钮
            Button(action: onAddTap) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                    Text("library_empty_add_button")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, DesignTokens.Spacing.xxl)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(
                    LinearGradient(
                        colors: [Color.brand.primary, Color.brand.secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
        }
        .padding(DesignTokens.Spacing.xxl)
    }
    
    /// 提示行
    private static func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.brand.primary)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
    
    /// 题库空状态（无操作按钮）
    static var noItems: EmptyStateView {
        EmptyStateView(
            icon: "books.vertical",
            title: String(localized: "empty_state_title"),
            message: String(localized: "empty_state_description")
        )
    }

    /// 复习空状态
    static var noReviewItems: EmptyStateView {
        EmptyStateView(
            icon: "checkmark.seal.fill",
            title: String(localized: "review_empty_title"),
            message: String(localized: "review_empty_description")
        )
    }

    /// 搜索无结果
    static var noSearchResults: EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: String(localized: "search_empty_title"),
            message: String(localized: "search_empty_description")
        )
    }

    /// 筛选无结果
    static var noFilterResults: EmptyStateView {
        EmptyStateView(
            icon: "line.3.horizontal.decrease.circle",
            title: String(localized: "filter_empty_title"),
            message: String(localized: "filter_empty_description")
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
