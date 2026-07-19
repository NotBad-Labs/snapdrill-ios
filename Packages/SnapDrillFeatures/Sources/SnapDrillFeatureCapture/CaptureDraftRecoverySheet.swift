//
//  CaptureDraftRecoverySheet.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import SwiftUI
import SnapDrillCore
import UIKit

struct CaptureDraftRecoverySheet: View {
    let title: String
    let message: String
    let canRestore: Bool
    let onContinue: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: canRestore ? "doc.badge.clock" : "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(canRestore ? Color.accentColor : Color.red)
                            .accessibilityHidden(true)

                        Text(title)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(message)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 12) {
                        if canRestore {
                            Button(action: onContinue) {
                                actionLabel(L10n.Capture.draftContinue, isPrimary: true)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("capture.draft.continue")
                        }

                        Button(role: .destructive, action: onDiscard) {
                            actionLabel(L10n.Common.discard, isPrimary: false)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("capture.draft.discard")
                    }
                }
                .frame(maxWidth: 480)
                .padding(24)
                .frame(
                    maxWidth: .infinity,
                    minHeight: geometry.size.height,
                    alignment: .center
                )
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private func actionLabel(_ text: String, isPrimary: Bool) -> some View {
        Text(text)
            .font(.body.weight(.semibold))
            .foregroundStyle(
                isPrimary ? Color(uiColor: .systemBackground) : Color(uiColor: .label)
            )
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .padding(.horizontal, 16)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isPrimary ? Color(uiColor: .label) : Color(uiColor: .systemBackground)
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(uiColor: .label), lineWidth: isPrimary ? 0 : 1)
            }
    }
}
