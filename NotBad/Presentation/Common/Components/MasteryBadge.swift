//
//  MasteryBadge.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - MasteryBadgeStyle

/// 掌握程度徽章样式
enum MasteryBadgeStyle: Sendable {
    /// 紧凑 - 仅图标
    case compact

    /// 标准 - 图标 + 名称
    case standard

    /// 详细 - 图标 + 详细描述
    case detailed

    /// 星级 - 星级显示
    case stars

    /// 进度条 - 带进度条
    case progress
}

// MARK: - MasteryBadge

/// 掌握程度徽章
///
/// 显示错题掌握程度的可视化组件。
///
/// ## 功能特性
///
/// - 多种显示样式：紧凑、标准、详细、星级、进度条
/// - 自动颜色适配
/// - 动画效果支持
///
/// ## 使用示例
///
/// ```swift
/// // 标准样式
/// MasteryBadge(level: .learning)
///
/// // 星级样式
/// MasteryBadge(level: .mastered, style: .stars)
///
/// // 进度样式
/// MasteryBadge(level: .reviewing, style: .progress)
/// ```
struct MasteryBadge: View {

    // MARK: - Properties

    /// 掌握程度
    let level: MasteryLevel

    /// 显示样式
    var style: MasteryBadgeStyle = .standard

    /// 是否显示动画
    var animated: Bool = false

    // MARK: - Backward Compatibility

    /// 向后兼容：是否显示详细文本
    var showDetailText: Bool = false

    private var effectiveStyle: MasteryBadgeStyle {
        showDetailText ? .detailed : style
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch effectiveStyle {
            case .compact:
                compactView
            case .standard:
                standardView
            case .detailed:
                detailedView
            case .stars:
                starsView
            case .progress:
                progressView
            }
        }
    }

    // MARK: - Subviews

    private var compactView: some View {
        Image(systemName: level.icon)
            .font(.caption)
            .padding(DesignTokens.Spacing.sm)
            .background(level.color.opacity(0.1))
            .foregroundStyle(level.color)
            .clipShape(Circle())
            .symbolEffect(.pulse, isActive: animated)
            .accessibilityLabel("掌握程度：\(level.displayName)")
    }

    private var standardView: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: level.icon)
                .symbolEffect(.pulse, isActive: animated)
                .accessibilityHidden(true)
            Text(level.displayName)
        }
        .font(.caption)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(level.color.opacity(0.1))
        .foregroundStyle(level.color)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("掌握程度：\(level.displayName)")
    }

    private var detailedView: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: level.icon)
                .symbolEffect(.pulse, isActive: animated)
                .accessibilityHidden(true)
            Text(level.detailText)
        }
        .font(.caption)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(level.color.opacity(0.1))
        .foregroundStyle(level.color)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("掌握程度：\(level.detailText)")
    }

    private var starsView: some View {
        HStack(spacing: DesignTokens.Spacing.xs / 2) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: index < level.stars ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(index < level.stars ? level.color : .gray.opacity(0.3))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("掌握程度：\(level.stars)星，\(level.displayName)")
    }

    private var progressView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack {
                Text(level.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(level.progress * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                        .fill(level.color.gradient)
                        .frame(width: geo.size.width * level.progress)
                }
            }
            .frame(height: 6)
        }
        .frame(minWidth: 100)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("掌握程度：\(level.displayName)，\(Int(level.progress * 100))%")
        .accessibilityValue("\(Int(level.progress * 100))%")
    }
}

// MARK: - MasteryProgressView

/// 带进度条的掌握程度显示
///
/// 独立的进度条组件，提供更灵活的布局控制。
struct MasteryProgressView: View {

    // MARK: - Properties

    /// 掌握程度
    let level: MasteryLevel

    /// 是否显示标签
    var showLabel: Bool = true

    /// 进度条高度
    var barHeight: CGFloat = 8

    /// 是否显示动画
    var animated: Bool = true

    // MARK: - State

    @State private var animatedProgress: Double = 0

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            if showLabel {
                labelView
            }

            progressBar
        }
        .onAppear {
            if animated {
                withAnimation(.easeOut(duration: 0.8)) {
                    animatedProgress = level.progress
                }
            } else {
                animatedProgress = level.progress
            }
        }
        .onChange(of: level) { _, newValue in
            if animated {
                withAnimation(.easeOut(duration: 0.3)) {
                    animatedProgress = newValue.progress
                }
            } else {
                animatedProgress = newValue.progress
            }
        }
    }

    // MARK: - Subviews

    private var labelView: some View {
        HStack {
            Text(level.displayName)
                .font(.caption)
                .fontWeight(.medium)
            Spacer()
            Text("\(Int(level.progress * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: barHeight / 2)
                    .fill(Color.gray.opacity(0.2))

                // 进度
                RoundedRectangle(cornerRadius: barHeight / 2)
                    .fill(level.color.gradient)
                    .frame(width: geo.size.width * animatedProgress)
            }
        }
        .frame(height: barHeight)
    }
}

// MARK: - MasteryComparisonView

/// 掌握程度对比视图
///
/// 显示两个掌握程度的对比（如复习前后）。
struct MasteryComparisonView: View {

    // MARK: - Properties

    /// 之前的程度
    let before: MasteryLevel

    /// 之后的程度
    let after: MasteryLevel

    /// 是否有进步
    var hasImproved: Bool {
        after.progress > before.progress
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            MasteryBadge(level: before, style: .compact)

            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundStyle(.secondary)

            MasteryBadge(level: after, style: .compact)

            if hasImproved {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        }
    }
}

// MARK: - Preview

#Preview("Badge Styles") {
    VStack(spacing: 16) {
        // Compact
        HStack(spacing: 12) {
            ForEach(MasteryLevel.allCases, id: \.rawValue) { level in
                MasteryBadge(level: level, style: .compact)
            }
        }

        // Standard
        VStack(spacing: 8) {
            ForEach(MasteryLevel.allCases, id: \.rawValue) { level in
                MasteryBadge(level: level, style: .standard)
            }
        }

        // Stars
        HStack(spacing: 12) {
            ForEach(MasteryLevel.allCases, id: \.rawValue) { level in
                MasteryBadge(level: level, style: .stars)
            }
        }

        // Progress
        VStack(spacing: 8) {
            ForEach(MasteryLevel.allCases, id: \.rawValue) { level in
                MasteryBadge(level: level, style: .progress)
            }
        }
        .frame(width: 150)
    }
    .padding()
}

#Preview("Progress View") {
    VStack(spacing: 16) {
        ForEach(MasteryLevel.allCases, id: \.rawValue) { level in
            MasteryProgressView(level: level)
        }
    }
    .padding()
}

#Preview("Comparison View") {
    VStack(spacing: 16) {
        MasteryComparisonView(before: .none, after: .glimpse)
        MasteryComparisonView(before: .glimpse, after: .partial)
        MasteryComparisonView(before: .partial, after: .good)
        MasteryComparisonView(before: .good, after: .mastered)
    }
    .padding()
}
