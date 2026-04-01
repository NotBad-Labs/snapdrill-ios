//
//  StorageManagementView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/04/01.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  存储管理页面，展示 App 占用的存储空间。
//

import SwiftUI
import SnapDrillCore

/// 存储管理页面
///
/// 显示图片和数据库的存储占用，帮助用户了解 App 的空间使用情况。
struct StorageManagementView: View {

    @State private var imageSize: Int64 = 0
    @State private var isLoading = true

    private let imageStorage = ImageStorage()

    var body: some View {
        List {
            Section {
                HStack {
                    Label(L10n.Settings.storageImages, systemImage: "photo.fill")
                    Spacer()
                    if isLoading {
                        ProgressView()
                    } else {
                        Text(formattedSize(imageSize))
                            .foregroundStyle(.secondary)
                    }
                }

            } footer: {
                Text(L10n.Settings.storageFooter)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.Settings.storageManagement)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            imageSize = await imageStorage.imageDirectorySize()
            isLoading = false
        }
    }

    private func formattedSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
