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
                        onMastered: { onMasteryUpdate(index, .mastered) },
                        onUnclear: { onMasteryUpdate(index, .glimpse) },
                        onFailed: { onMasteryUpdate(index, .none) }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
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
                    onMastered: onMastered,
                    onUnclear: onUnclear,
                    onFailed: onFailed
                )
            } else {
                // 占位视图，保持尺寸一致
                Color.clear
            }
        }
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
