//
//  ReviewComponents.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - ReviewContent

/// 复习内容视图
///
/// 使用懒加载机制，只渲染当前卡片及相邻卡片，
/// 避免一次性加载所有图片导致的性能问题。
struct ReviewContent: View {

    let items: [ReviewItem]
    @Binding var currentIndex: Int
    @Binding var showAnswer: Bool
    let onMasteryUpdate: (Int, MasteryLevel) -> Void
    
    /// 预加载范围（前后各几个）
    private let preloadRange = 1

    var body: some View {
        VStack(spacing: 0) {
            ProgressBar(current: currentIndex + 1, total: items.count)

            TabView(selection: $currentIndex) {
                ForEach(items.indices, id: \.self) { index in
                    // 懒加载：只渲染当前页及相邻页
                    LazyReviewCardView(
                        reviewItem: items[index],
                        index: index,
                        currentIndex: currentIndex,
                        preloadRange: preloadRange,
                        showAnswer: index == currentIndex ? $showAnswer : .constant(false),
                        onMastered: { onMasteryUpdate(index, .mastered) },
                        onUnclear: { onMasteryUpdate(index, .glimpse) },
                        onFailed: { onMasteryUpdate(index, .none) }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // 键盘快捷键提示（仅 iPad/Mac）
            #if !os(watchOS)
            KeyboardShortcutHint()
            #endif
        }
    }
}

// MARK: - KeyboardShortcutHint

/// 键盘快捷键提示视图
///
/// 在 iPad/Mac 上显示快捷键提示
private struct KeyboardShortcutHint: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    var body: some View {
        // 仅在 iPad (Regular Size Class) 显示
        if sizeClass == .regular {
            HStack(spacing: DesignTokens.Spacing.lg) {
                KeyHint(key: "Space", label: "显示答案")
                KeyHint(key: "1", label: "不会")
                KeyHint(key: "2", label: "模糊")
                KeyHint(key: "3", label: "掌握")
                KeyHint(key: "←→", label: "切换")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }
}

/// 单个按键提示
private struct KeyHint: View {
    let key: String
    let label: String
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Text(key)
                .font(.caption2.monospaced())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            Text(label)
        }
    }
}

// MARK: - LazyReviewCardView

/// 懒加载复习卡片包装器
///
/// 只有当卡片进入预加载范围时才真正渲染内容，
/// 大幅减少初始加载时间和内存占用。
private struct LazyReviewCardView: View {
    let reviewItem: ReviewItem
    let index: Int
    let currentIndex: Int
    let preloadRange: Int
    @Binding var showAnswer: Bool
    let onMastered: () -> Void
    let onUnclear: () -> Void
    let onFailed: () -> Void
    
    /// 是否应该加载此卡片
    private var shouldLoad: Bool {
        abs(index - currentIndex) <= preloadRange
    }
    
    var body: some View {
        Group {
            if shouldLoad {
                ReviewCard(
                    reviewItem: reviewItem,
                    showAnswer: $showAnswer,
                    onMastered: onMastered,
                    onUnclear: onUnclear,
                    onFailed: onFailed
                )
            } else {
                // 占位视图，保持 TabView 尺寸稳定，避免滑动时高度跳变
                ReviewCardPlaceholder()
            }
        }
    }
}

/// 卡片占位，确保未预加载时也占据同等布局空间
private struct ReviewCardPlaceholder: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .fill(Color.semantic.secondaryBackground)
                .frame(height: 36)

            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .fill(Color.semantic.secondaryBackground)
                .frame(height: 220)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.semantic.secondaryBackground)
                    .frame(height: 16)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.semantic.secondaryBackground)
                    .frame(height: 14)
            }

            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .fill(Color.semantic.secondaryBackground)
                .frame(height: 120)

            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .fill(Color.semantic.secondaryBackground)
                .frame(height: 96)
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.semantic.background)
        .redacted(reason: .placeholder)
    }
}

// MARK: - ProgressBar

/// 进度条组件
struct ProgressBar: View {

    let current: Int
    let total: Int

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("review_progress_title")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(current) / \(total)")
                    .font(.headline)
                    .foregroundStyle(Color.brand.primary)
            }

            ProgressView(value: Double(current), total: Double(total))
                .tint(Color.brand.primary)
        }
        .padding(DesignTokens.Spacing.lg)
        .background(Color.semantic.secondaryBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "review_progress_accessibility"), current, total))
        .accessibilityValue("\(Int(Double(current) / Double(total) * 100))%")
    }
}
