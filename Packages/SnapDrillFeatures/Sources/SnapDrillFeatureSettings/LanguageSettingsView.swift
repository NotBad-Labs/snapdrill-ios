//
//  LanguageSettingsView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  语言设置页面，支持 App 内直选语言（通过 AppleLanguages UserDefaults）。
//

import SwiftUI
import SnapDrillCore

/// 支持的 App 语言
enum AppLanguage: String, CaseIterable, Identifiable {
    case zhHans = "zh-Hans"
    case en = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .zhHans: "简体中文"
        case .en: "English"
        }
    }

    /// 当前 App 使用的语言
    static var current: AppLanguage {
        // 优先读 AppleLanguages（用户主动选择的语言）
        if let languages = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
           let first = languages.first {
            if first.hasPrefix("zh") { return .zhHans }
            if first.hasPrefix("en") { return .en }
        }
        // 回退到系统语言
        return LocalizationHelper.isEnglishLocale ? .en : .zhHans
    }
}

/// 语言设置页面
///
/// 列出所有支持的语言，选择后设置 `AppleLanguages` UserDefaults 并提示重启。
struct LanguageSettingsView: View {

    @State private var selectedLanguage = AppLanguage.current
    @State private var showRestartAlert = false

    var body: some View {
        List {
            // 语言选择
            Section {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        guard language != selectedLanguage else { return }
                        selectedLanguage = language
                        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
                        UserDefaults.standard.synchronize()
                        showRestartAlert = true
                    } label: {
                        HStack {
                            Text(language.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if language == selectedLanguage {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settings.language.\(language.rawValue)")
                    .accessibilityAddTraits(language == selectedLanguage ? .isSelected : [])
                }
            } footer: {
                Text(L10n.Settings.languageRestartHint)
            }

            // 系统设置入口（备用）
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
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityIdentifier("settings.language.systemSettings")
            }
        }
        .listStyle(.insetGrouped)
        .accessibilityIdentifier("settings.language.root")
        .navigationTitle(L10n.Settings.language)
        .navigationBarTitleDisplayMode(.inline)
        .alert(L10n.Settings.languageChangeTitle, isPresented: $showRestartAlert) {
            Button(L10n.Common.ok, role: .cancel) {}
        } message: {
            Text(L10n.Settings.languageChangeMessage)
        }
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
}
