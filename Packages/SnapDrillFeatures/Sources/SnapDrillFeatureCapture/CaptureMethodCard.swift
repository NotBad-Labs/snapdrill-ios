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

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.1))
                .clipShape(Circle())
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

struct CaptureMethodCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let accessibilityHintText: String
    let accessibilityID: String?
    let action: () -> Void

    init(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        accessibilityHint: String = "",
        accessibilityID: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.accessibilityHintText = accessibilityHint
        self.accessibilityID = accessibilityID
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            CaptureMethodCardContent(icon: icon, title: title, subtitle: subtitle, color: color)
        }
        .glassEffect(.regular.tint(color).interactive(), in: .rect(cornerRadius: 16))
        .accessibleButton(label: title, hint: accessibilityHintText.isEmpty ? subtitle : accessibilityHintText)
        .accessibilityIdentifier(accessibilityID ?? "")
    }
}
