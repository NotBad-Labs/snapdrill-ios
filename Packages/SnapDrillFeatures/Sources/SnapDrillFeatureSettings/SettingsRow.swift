//
//  SettingsRow.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  设置列表行组件，克制的系统色图标背景。
//

import SwiftUI
import SnapDrillCore

/// 设置页通用行组件
///
/// 图标背景使用低饱和系统色，保持 Settings 与其它旗舰屏一致。
struct SettingsRow: View {

    // MARK: - Properties

    let icon: String
    let gradientStart: Color
    let gradientEnd: Color
    let title: String
    var value: String?

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.primary)
                .frame(width: 30, height: 30)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    gradientStart.opacity(0.10),
                                    gradientEnd.opacity(0.14)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .accessibilityHidden(true)

            Text(title)
                .font(.body)
                .foregroundStyle(.primary)

            // Spacer 仅在有 value 时插入，避免 Toggle 包裹时小屏挤压开关
            if let value {
                Spacer()
                Text(value)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

        }
        .padding(.vertical, 2)
    }
}
