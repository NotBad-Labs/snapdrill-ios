//
//  AccessibleEmptyState.swift
//  SnapDrillUI
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import SwiftUI
import UIKit

/// High-contrast empty state used where the system placeholder audits as too low contrast.
public struct AccessibleEmptyState: View {
    private let title: String
    private let message: String
    private let systemImage: String
    private let actionTitle: String?
    private let actionSystemImage: String?
    private let action: (() -> Void)?

    public init(
        title: String,
        message: String,
        systemImage: String,
        actionTitle: String? = nil,
        actionSystemImage: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.actionSystemImage = actionSystemImage
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    label(title: actionTitle)
                        .font(.headline)
                        .foregroundStyle(Color(UIColor.systemBackground))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .frame(minHeight: 44)
                        .background(Color(UIColor.label), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func label(title: String) -> some View {
        if let actionSystemImage {
            Label(title, systemImage: actionSystemImage)
                .labelStyle(.titleAndIcon)
        } else {
            Text(title)
        }
    }
}
