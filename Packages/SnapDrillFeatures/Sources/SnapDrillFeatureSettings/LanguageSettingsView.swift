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
import SnapDrillCore

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
                        Text(L10n.Settings.languageControlledBySystem)
                            .font(.headline)
                        Text(L10n.Settings.languageSystemHint)
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
                        Text(L10n.Settings.openSystemSettings)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.tint)
                    }
                }
            } footer: {
                Text(L10n.Settings.languageFooter)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.Settings.language)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
}
