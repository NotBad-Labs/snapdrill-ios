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
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Hero Visual
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
            
            // Text Summary
            VStack(spacing: 16) {
                if pendingCount > 0 {
                    if reviewedCount > 0 {
                        // SCENARIO 2: Interrupted / In-Progress (Split Stats)
                        HStack(spacing: 40) {
                            // Pending (Left)
                            VStack(spacing: 4) {
                                Text("\(pendingCount)")
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                Text(L10n.Review.pending)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibleGroup(label: L10n.Accessibility.pendingReview(count: pendingCount))

                            Divider()
                                .frame(height: 40)
                                .accessibilityHidden(true)

                            // Done (Right)
                            VStack(spacing: 4) {
                                Text("\(reviewedCount)")
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .foregroundStyle(.green)
                                Text(L10n.Review.completed)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibleGroup(label: L10n.Accessibility.reviewedToday(count: reviewedCount))
                        }
                    } else {
                        // SCENARIO 1: Fresh Start
                        VStack(spacing: 16) {
                            Text(L10n.Review.todayReview)
                                .font(.title2)
                                .foregroundStyle(.secondary)

                            Text("\(pendingCount)")
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)

                            Text(L10n.Review.cardsPending)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .accessibleGroup(label: L10n.Accessibility.pendingReview(count: pendingCount))
                    }
                } else if totalItemsCount == 0 {
                    // Empty State
                    Text(L10n.Review.welcomeBack)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text(L10n.Review.emptyHint)
                        .font(.body)
                        .foregroundStyle(.secondary)
                } else {
                    // SCENARIO 3: Finished
                    Text(L10n.Review.excellent)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text(L10n.Review.reviewedToday(reviewedCount))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Actions
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
                // Empty Action: Navigate for collection
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
                // Done Action: Rest
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
        // Add glass background to separate from the dynamic mesh behind it
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
