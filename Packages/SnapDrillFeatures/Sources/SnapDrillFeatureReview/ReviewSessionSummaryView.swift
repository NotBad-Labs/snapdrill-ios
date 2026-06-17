//
//  ReviewSessionSummaryView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  回顾会话完成后的摘要统计视图。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI

/// 回顾会话完成后的摘要统计视图
///
/// 展示本次会话的有印象/没印象分类统计。
struct ReviewSessionSummaryView: View {

    // MARK: - Properties

    /// "有印象"（右滑）的资料数
    let goodCount: Int
    /// "没印象"（左滑）的资料数
    let againCount: Int
    /// 点击完成后的回调
    let onDismiss: () -> Void

    // Dynamic Type 支持：统计数字随系统字号缩放
    @ScaledMetric(relativeTo: .largeTitle) private var statFontSize: CGFloat = 36

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.blue)
                        .frame(width: 52, height: 52)
                        .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.Review.summaryTitle)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(encouragementText)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 0) {
                    statCard(
                        title: L10n.Review.summaryGood,
                        count: goodCount,
                        color: .blue,
                        icon: "checkmark.circle.fill"
                    )

                    Divider()
                        .padding(.vertical, 14)
                        .accessibilityHidden(true)

                    statCard(
                        title: L10n.Review.summaryAgain,
                        count: againCount,
                        color: .orange,
                        icon: "arrow.uturn.left.circle.fill"
                    )
                }
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color(UIColor.separator).opacity(0.14), lineWidth: 1)
                )

                Button(action: onDismiss) {
                    Text(L10n.Review.summaryDismiss)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .frame(maxWidth: 560)
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Private Helpers

    @ViewBuilder
    private func statCard(title: String, count: Int, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text("\(count)")
                .font(.system(size: statFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .accessibleGroup(label: L10n.Accessibility.statCard(title: title, count: count))
    }

    private var encouragementText: String {
        let total = goodCount + againCount
        guard total > 0 else { return L10n.Review.encourageRest }
        if againCount == 0 {
            return L10n.Review.encourageAllGood
        }
        if goodCount == 0 {
            return L10n.Review.encourageKeepGoing
        }
        return L10n.Review.encouragePartial(againCount)
    }
}

// MARK: - Preview

#Preview("全部有印象") {
    ReviewSessionSummaryView(goodCount: 5, againCount: 0, onDismiss: {})
}

#Preview("部分没印象") {
    ReviewSessionSummaryView(goodCount: 3, againCount: 2, onDismiss: {})
}

#Preview("全部没印象") {
    ReviewSessionSummaryView(goodCount: 0, againCount: 5, onDismiss: {})
}
