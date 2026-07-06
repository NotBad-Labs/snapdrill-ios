//
//  ReviewDashboardView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  回顾模块的准备面板 (Idle State)。
//  展示当前待处理概览，并保持成人生产力工具语气。
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

    @ScaledMetric(relativeTo: .largeTitle) private var statFontSize: CGFloat = 42
    
    var body: some View {
        Group {
            if totalItemsCount == 0 {
                emptyLibraryState
            } else {
                dashboardContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Private Helpers
    
    private var iconName: String {
        if pendingCount > 0 {
            return "rectangle.stack"
        } else {
            return "checkmark.circle"
        }
    }

    private var emptyLibraryState: some View {
        AccessibleEmptyState(
            title: L10n.Review.emptyTitle,
            message: L10n.Review.emptyHint,
            systemImage: "clock.arrow.circlepath",
            actionTitle: L10n.Review.emptyAction,
            actionSystemImage: "camera.viewfinder",
            action: onEnter
        )
        .padding(.horizontal, 24)
    }

    private var dashboardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                statusPanel
                primaryAction
            }
            .frame(maxWidth: 560)
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: iconName)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 52, height: 52)
                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Review.todayReview)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(statusMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var statusPanel: some View {
        HStack(spacing: 0) {
            statBlock(
                value: pendingCount,
                title: L10n.Review.pending,
                label: L10n.Accessibility.pendingReview(count: pendingCount)
            )

            Divider()
                .padding(.vertical, 14)
                .accessibilityHidden(true)

            statBlock(
                value: reviewedCount,
                title: L10n.Review.completed,
                label: L10n.Accessibility.reviewedToday(count: reviewedCount)
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
    }

    private func statBlock(value: Int, title: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(value)")
                .font(.system(size: statFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .accessibleGroup(label: label)
    }

    @ViewBuilder
    private var primaryAction: some View {
        if pendingCount > 0 {
            Button(action: onStart) {
                Label(L10n.Review.startReview, systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("review.startButton")
            .accessibilityHint(L10n.Accessibility.startReviewHint)
        } else if totalItemsCount == 0 {
            Button(action: onEnter) {
                Label(L10n.Review.emptyAction, systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityIdentifier("review.captureButton")
        } else {
            Label(L10n.Review.goRest, systemImage: "checkmark.circle")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var statusMessage: String {
        if pendingCount > 0 {
            if reviewedCount > 0 {
                return L10n.Review.reviewedToday(reviewedCount)
            }
            return L10n.Review.cardsPending
        }
        if totalItemsCount == 0 {
            return L10n.Review.emptyHint
        }
        return L10n.Review.excellent
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
