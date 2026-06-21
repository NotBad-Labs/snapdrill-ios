//
//  CaptureMethodCard.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集方式卡片组件（iOS 26 Liquid Glass）
//

import SwiftUI
import SnapDrillUI

// Button 和 PhotosPicker 共享的卡片内容视图
struct CaptureMethodCardContent: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var isBusy = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)

                Spacer(minLength: 8)

                if isBusy {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityHidden(true)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 142 : 118, alignment: .topLeading)
        .padding(16)
    }
}

struct CaptureMethodCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let accessibilityHintText: String
    let accessibilityID: String?
    let isBusy: Bool
    let isDisabled: Bool
    let action: () -> Void

    init(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        accessibilityHint: String = "",
        accessibilityID: String? = nil,
        isBusy: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.accessibilityHintText = accessibilityHint
        self.accessibilityID = accessibilityID
        self.isBusy = isBusy
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            CaptureMethodCardContent(icon: icon, title: title, subtitle: subtitle, color: color, isBusy: isBusy)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        .opacity(isDisabled ? 0.55 : 1)
        .disabled(isDisabled)
        .accessibleButton(label: title, hint: accessibilityHintText.isEmpty ? subtitle : accessibilityHintText)
        .accessibilityIdentifier(accessibilityID ?? "capture.method")
    }
}
