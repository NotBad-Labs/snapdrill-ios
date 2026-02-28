//
//  SettingsRow.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  设置列表行组件（从 SettingsView.swift 拆分）
//

import SwiftUI

/// 设置页通用行组件
///
/// 提供统一的图标 + 标题 + 可选值的行样式，对齐 iOS 系统设置风格。
struct SettingsRow: View {
    
    // MARK: - Properties
    
    let icon: String
    let color: Color
    let title: String
    var value: String?
    var isPremium: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标背景框
            ZStack {
                if isPremium {
                    LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                } else {
                    color
                }
            }
            .frame(width: 28, height: 28)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            )

            Text(title)
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()

            if let value {
                Text(value)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
