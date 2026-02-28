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
