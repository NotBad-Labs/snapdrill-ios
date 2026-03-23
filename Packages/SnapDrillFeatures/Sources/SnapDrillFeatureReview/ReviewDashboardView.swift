//
//  ReviewDashboardView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/01/01.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  复习模块的“准备”面板 (Idle State)
//  展示今日待复习概览，赋予用户开始学习的主动权。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI

struct ReviewDashboardView: View {

    // MARK: - Properties

    let pendingCount: Int
    let reviewedCount: Int // Today's Done
    let totalItemsCount: Int
    let onStart: () -> Void
    let onEnter: () -> Void

    // Dynamic Type 支持：装饰性统计数字随系统字号缩放
    @ScaledMetric(relativeTo: .largeTitle) private var statFontSize: CGFloat = 44
    @ScaledMetric(relativeTo: .largeTitle) private var heroFontSize: CGFloat = 64
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 主视觉区域
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)

                Image(systemName: iconName)
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 40)
            .accessibilityHidden(true)
            
            // 文字摘要
            VStack(spacing: 16) {
                if pendingCount > 0 {
                    if reviewedCount > 0 {
                        // 场景 2：中断 / 进行中（分列统计）
                        HStack(spacing: 40) {
                            // 待复习（左侧）
                            VStack(spacing: 4) {
                                Text("\(pendingCount)")
                                    .font(.system(size: statFontSize, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                Text(L10n.Review.pending)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibleGroup(label: L10n.Accessibility.pendingReview(count: pendingCount))

                            Divider()
                                .frame(height: 40)
                                .accessibilityHidden(true)

                            // 已完成（右侧）
                            VStack(spacing: 4) {
                                Text("\(reviewedCount)")
                                    .font(.system(size: statFontSize, weight: .bold, design: .rounded))
                                    .foregroundStyle(.green)
                                Text(L10n.Review.completed)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibleGroup(label: L10n.Accessibility.reviewedToday(count: reviewedCount))
                        }
                    } else {
                        // 场景 1：全新开始
                        VStack(spacing: 16) {
                            Text(L10n.Review.todayReview)
                                .font(.title2)
                                .foregroundStyle(.secondary)

                            Text("\(pendingCount)")
                                .font(.system(size: heroFontSize, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)

                            Text(L10n.Review.cardsPending)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .accessibleGroup(label: L10n.Accessibility.pendingReview(count: pendingCount))
                    }
                } else if totalItemsCount == 0 {
                    // 空状态
                    Text(L10n.Review.welcomeBack)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text(L10n.Review.emptyHint)
                        .font(.body)
                        .foregroundStyle(.secondary)
                } else {
                    // 场景 3：已完成
                    Text(L10n.Review.excellent)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text(L10n.Review.reviewedToday(reviewedCount))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // 操作按钮
            if pendingCount > 0 {
                Button(action: onStart) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text(L10n.Review.startReview)
                    }
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                }
                .accessibilityHint(L10n.Accessibility.startReviewHint)
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            } else if totalItemsCount == 0 {
                // 空状态操作：跳转去采集
                Button(action: onEnter) {
                    Text(L10n.Dashboard.goCapture)
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
                .padding(.bottom, 60)
            } else {
                // 完成操作：休息
                Button(action: {}, label: {
                    HStack {
                        Image(systemName: "moon.stars.fill")
                        Text(L10n.Review.goRest)
                    }
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                })
                .disabled(true)
                .padding(.bottom, 60)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 添加毛玻璃背景，与后面的动态渐变网格分离
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Private Helpers
    
    private var iconName: String {
        if pendingCount > 0 {
            return "rectangle.stack.fill"
        } else if totalItemsCount == 0 {
            return "plus.square.dashed"
        } else {
            return "checkmark.seal.fill"
        }
    }
}

#Preview {
    ReviewDashboardView(
        pendingCount: 12,
        reviewedCount: 5,
        totalItemsCount: 20,
        onStart: {},
        onEnter: {}
    )
}
