//
//  TipPopoverContent.swift
//  SnapDrillUI
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Profile 级 Tip 的 popover 内容视图，模仿 TipKit 原生样式。
//

import SwiftUI
import SnapDrillCore

/// Profile 级 Tip 的 popover 内容（替代 TipKit 的 .popoverTip 样式）
public struct TipPopoverContent: View {

    private let icon: String
    private let title: String
    private let message: String
    private let onDismiss: () -> Void

    public init(icon: String, title: String, message: String, onDismiss: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.message = message
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(.tint)
                Text(title)
                    .font(.headline)
            }
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button(L10n.Common.ok) {
                onDismiss()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .frame(maxWidth: 280)
        .presentationCompactAdaptation(.popover)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(message)")
    }
}
