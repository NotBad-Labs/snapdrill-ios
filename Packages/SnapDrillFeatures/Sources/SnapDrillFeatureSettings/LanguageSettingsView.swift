//
//  LanguageSettingsView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/01/02.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  语言设置页面，引导用户前往系统设置修改应用语言。
//

import SwiftUI

/// 语言设置页面
///
/// iOS 不支持在 App 内直接切换语言，正确方式是引导用户前往系统设置。
struct LanguageSettingsView: View {

    // MARK: - Body

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    // 渐变图标容器（与 SettingsRow 保持一致）
                    ZStack {
                        LinearGradient(
                            colors: [.green, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: "globe")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("语言由 iOS 系统控制")
                            .font(.headline)
                        Text("在系统设置中为 SnapDrill 单独指定语言。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            Section {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Text("打开系统设置")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.tint)
                    }
                }
            } footer: {
                Text("前往「设置 → SnapDrill → 语言」，选择偏好语言后重新启动应用即可生效。目前支持简体中文，更多语言持续开发中。")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("语言")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
}
