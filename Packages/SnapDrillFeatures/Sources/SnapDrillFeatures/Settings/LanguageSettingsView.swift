//
//  LanguageSettingsView.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2026/01/02.
//

import SwiftUI

/// 语言设置页面
struct LanguageSettingsView: View {
    
    // MARK: - Properties
    
    @AppStorage("appLanguage") private var appLanguage = "zh-Hans" // zh-Hans, en
    
    // MARK: - Body
    
    var body: some View {
        List {
            Section {
                Button {
                    appLanguage = "zh-Hans"
                } label: {
                    HStack {
                        Text("简体中文")
                            .foregroundStyle(.primary)
                        Spacer()
                        if appLanguage == "zh-Hans" {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                Button {
                    appLanguage = "en"
                } label: {
                    HStack {
                        Text("English")
                            .foregroundStyle(.primary)
                        Spacer()
                        if appLanguage == "en" {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            } footer: {
                Text("更改语言后需要重启应用")
            }
        }
        .navigationTitle("语言")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
}
