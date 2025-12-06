//
//  SettingsView.swift
//  NotBad
//
//  设置视图
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                storageSection
                aboutSection
            }
            .navigationTitle("设置")
        }
    }
    
    // MARK: - Sections
    
    private var storageSection: some View {
        Section("存储") {
            HStack {
                Text("图片占用")
                Spacer()
                Text(ImageStorageService.shared.formattedSize)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var aboutSection: some View {
        Section("关于") {
            Text("NotBad 错题本")
            Text("版本 1.0")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SettingsView()
}
