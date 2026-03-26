//
//  ReviewHeroCard.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  首页核心卡片，根据复习数据动态展示状态。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI

/// 仪表盘核心卡片：根据当前的复习数量动态展示不同的 UI 状态
///
/// 包括：
/// - 新用户引导状态（无数据）
/// - 待复习任务状态
/// - 任务已完成状态
struct ReviewHeroCard: View {

    // MARK: - Properties

    /// 点击”立即开始”复习时的回调
    let onStartReview: () -> Void
    /// 点击”录入题目”时的回调
    let onStartCapture: () -> Void

    let totalCount: Int
    let dueCount: Int
    /// 今日已复习数量，用于计算进度环
    let reviewedTodayCount: Int

    // Dynamic Type 支持：待复习数字随系统字号缩放
    @ScaledMetric(relativeTo: .largeTitle) private var dueFontSize: CGFloat = 48

    init(
        totalCount: Int,
        dueCount: Int,
        reviewedTodayCount: Int,
        onStartReview: @escaping () -> Void,
        onStartCapture: @escaping () -> Void
    ) {
        self.totalCount = totalCount
        self.dueCount = dueCount
        self.reviewedTodayCount = reviewedTodayCount
        self.onStartReview = onStartReview
        self.onStartCapture = onStartCapture
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            if totalCount == 0 {
                // 场景 1：新用户（无数据）
                // 引导用户添加第一道题
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.Dashboard.welcome)
                            .font(.title2.bold())
                            .foregroundStyle(.white)

                        Text(L10n.Dashboard.welcomeSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))

                        Button(action: onStartCapture) {
                            Label(L10n.Dashboard.captureItem, systemImage: "plus.circle.fill")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .foregroundStyle(Color.orange)
                                .clipShape(Capsule())
                        }
                        .accessibleButton(label: L10n.Dashboard.captureItem, hint: L10n.Accessibility.captureFirstItemHint)
                    }
                    Spacer()
                    Image(systemName: "flag.checkered.2.crossed")
                        .font(.system(size: 50))
                        .foregroundStyle(.white.opacity(0.8))
                        .accessibilityHidden(true)
                }
                .padding(24)
                .background(
                    LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            } else if dueCount > 0 {
                // 场景 2：有待复习题目（待复习 > 0）
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.Dashboard.todayDue)
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.9))

                            Text("\(dueCount)")
                                .font(.system(size: dueFontSize, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .accessibleGroup(label: L10n.Accessibility.dueCountLabel(count: dueCount))

                        Button(action: onStartReview) {
                            Text(L10n.Dashboard.startNow)
                                .font(.subheadline.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .foregroundStyle(Color.blue)
                                .clipShape(Capsule())
                        }
                        .accessibleButton(label: L10n.Dashboard.startNow, hint: L10n.Accessibility.startReviewNowHint)
                    }
                    Spacer()
                    // 今日复习进度环（已复习 / 今日总数）
                    let totalToday = dueCount + reviewedTodayCount
                    let progress = totalToday > 0 ? CGFloat(reviewedTodayCount) / CGFloat(totalToday) : 0
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(duration: 0.5), value: progress)
                    }
                    .frame(width: 80, height: 80)
                    .accessibleGroup(label: L10n.Accessibility.reviewProgressLabel(reviewed: reviewedTodayCount, total: totalToday))
                }
                .padding(24)
                .background(
                    LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            } else {
                // 场景 3：全部完成（总数 > 0，待复习 == 0）
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.Dashboard.allDone)
                            .font(.title2.bold())
                            .foregroundStyle(.primary)

                        Text(L10n.Dashboard.allDoneSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.green.gradient)
                        .symbolEffect(.bounce, value: true)
                        .accessibilityHidden(true)
                }
                .accessibleGroup(label: L10n.Accessibility.allDoneLabel)
                .padding(24)
                .background(.regularMaterial) // Use material for cards
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

#Preview("Hero Card") {
    ReviewHeroCard(totalCount: 5, dueCount: 3, reviewedTodayCount: 2, onStartReview: {}, onStartCapture: {})
}
