//
//  ReviewSessionSummaryView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/03/09.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  复习会话完成后的摘要统计视图。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI

/// 复习会话完成后的摘要统计视图
///
/// 展示本次会话的掌握/待加强分类统计和鼓励语。
struct ReviewSessionSummaryView: View {

    // MARK: - Properties

    /// "记得"（右滑）的卡片数
    let goodCount: Int
    /// "忘记"（左滑）的卡片数
    let againCount: Int
    /// 点击"好的"后的回调
    let onDismiss: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // 图标
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green.opacity(0.8))
                .symbolEffect(.bounce, value: true)
                .accessibilityHidden(true)

            // 标题
            Text(L10n.Review.summaryTitle)
                .font(.title2.bold())

            // 统计卡片
            HStack(spacing: 16) {
                statCard(
                    title: L10n.Review.summaryGood,
                    count: goodCount,
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                statCard(
                    title: L10n.Review.summaryAgain,
                    count: againCount,
                    color: .orange,
                    icon: "arrow.counterclockwise.circle.fill"
                )
            }
            .padding(.horizontal, 32)

            // 鼓励语
            Text(encouragementText)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // 按钮
            Button(action: onDismiss) {
                Text(L10n.Review.summaryDismiss)
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Private Helpers

    @ViewBuilder
    private func statCard(title: String, count: Int, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text("\(count)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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

#Preview("全部掌握") {
    ReviewSessionSummaryView(goodCount: 5, againCount: 0, onDismiss: {})
}

#Preview("部分待加强") {
    ReviewSessionSummaryView(goodCount: 3, againCount: 2, onDismiss: {})
}

#Preview("全部忘记") {
    ReviewSessionSummaryView(goodCount: 0, againCount: 5, onDismiss: {})
}
