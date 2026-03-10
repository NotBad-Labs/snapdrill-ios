//
//  SettingsRow.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  设置列表行组件，Telegram 风格渐变图标。
//

import SwiftUI
import SnapDrillCore

/// 设置页通用行组件
///
/// 图标背景使用双色线性渐变（topLeading → bottomTrailing），对齐 Telegram 设计风格。
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
            // 渐变图标容器（Telegram 核心视觉特征）
            ZStack {
                LinearGradient(
                    colors: [gradientStart, gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 30, height: 30)
            .clipShape(RoundedRectangle(cornerRadius: 8))

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
        // preference 向上传播，消除每个调用点重复 .listRowSeparator(.hidden)
        .listRowSeparator(.hidden)
    }
}

/// iCloud 同步关闭时的数据风险提示（共享组件，SettingsView footer 和 DataAndSyncSettingsView 顶部共用）
struct LocalDataWarningView: View {

    /// 紧凑模式（单行 Label，用于 Section footer）
    let compact: Bool

    var body: some View {
        if compact {
            Label(L10n.Settings.localModeWarning, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
        } else {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Settings.localDataModeTitle)
                        .font(.subheadline.bold())
                    Text(L10n.Settings.localDataModeMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
        }
    }
}
