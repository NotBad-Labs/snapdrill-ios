//
//  EmptyReviewState.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - EmptyReviewState

/// 空状态视图
struct EmptyReviewState: View {

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Image(systemName: "checkmark.seal.fill")
                .font(Typography.iconXL)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.brand.success, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.bounce)

            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("review_empty_title")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("review_empty_description")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("review_empty_accessibility")
    }
}

#Preview {
    EmptyReviewState()
}
