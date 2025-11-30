//
//  ReviewComponents.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - ReviewContent

/// 复习内容视图
struct ReviewContent: View {

    let items: [ReviewItem]
    @Binding var currentIndex: Int
    let onMasteryUpdate: (Int, MasteryLevel) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ProgressBar(current: currentIndex + 1, total: items.count)

            TabView(selection: $currentIndex) {
                ForEach(items.indices, id: \.self) { index in
                    ReviewCard(
                        item: items[index],
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
