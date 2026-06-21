//
//  DataAndSyncSettingsView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  数据设置页面，管理备份恢复和缓存清理。
//

import SwiftUI
import UniformTypeIdentifiers
import SnapDrillCore
import SnapDrillData
import SnapDrillUI

/// 数据设置页面
struct DataAndSyncSettingsView: View {

    // MARK: - Properties

    @Bindable var viewModel: SettingsViewModel
    @State private var activeOperation: DataOperation?

    // 存储缓存
    @State private var showingClearCacheAlert = false
    @State private var cacheSize: String = L10n.Settings.calculating
    @State private var cacheCalculateTask: Task<Void, Never>?
    @State private var cacheClearTask: Task<Void, Never>?

    // 备份 / 恢复
    @State private var backupTask: Task<Void, Never>?
    @State private var restoreTask: Task<Void, Never>?
    @State private var showingRestoreConfirmation = false
    @State private var showingRestoreFilePicker = false
    @State private var showingShareSheet = false
    @State private var showingBackupError = false
    @State private var showingRestoreSuccess = false

    // 数据导入
    @State private var importTask: Task<Void, Never>?
    @State private var showingImportFilePicker = false
    @State private var showingImportSuccess = false

    var body: some View {
        List {
            // 本地数据警告
            Section {
                DataNoticeRow(
                    title: L10n.Settings.localDataTitle,
                    message: L10n.Settings.localDataWarning
                )
            }

            // 备份 / 恢复
            Section {
                // 备份按钮
                Button {
                    backupTask?.cancel()
                    backupTask = Task {
                        activeOperation = .backup
                        defer { activeOperation = nil }
                        await viewModel.createBackup()
                        if viewModel.backupFileURL != nil {
                            showingShareSheet = true
                        } else if viewModel.backupError != nil {
                            showingBackupError = true
                        }
                    }
                } label: {
                    DataActionRow(
                        title: L10n.Settings.backupData,
                        subtitle: L10n.Settings.backupDataSubtitle,
                        systemImage: "arrow.up.doc.fill",
                        tint: .blue,
                        isLoading: isOperationActive(.backup)
                    )
                }
                .disabled(viewModel.isBackupInProgress)
                .accessibilityHint(L10n.Accessibility.backupDataHint)

                // 恢复按钮
                Button {
                    showingRestoreConfirmation = true
                } label: {
                    DataActionRow(
                        title: L10n.Settings.restoreData,
                        subtitle: L10n.Settings.restoreDataSubtitle,
                        systemImage: "arrow.down.doc.fill",
                        tint: .teal,
                        isLoading: isOperationActive(.restore)
                    )
                }
                .disabled(viewModel.isBackupInProgress)
                .accessibilityHint(L10n.Accessibility.restoreDataHint)

                // 进度条（备份/恢复过程中显示）
                if shouldShowBackupProgress {
                    VStack(alignment: .leading, spacing: 6) {
                        if !viewModel.backupStatusMessage.isEmpty {
                            Text(viewModel.backupStatusMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: viewModel.backupProgress, total: 1.0)
                    }
                    .padding(.vertical, 4)
                    .accessibleGroup(label: viewModel.backupStatusMessage)
                }
            } header: {
                Text(L10n.Settings.backup)
            } footer: {
                Text(L10n.Settings.backupFooter)
            }

            // 数据导入
            Section {
                Button {
                    showingImportFilePicker = true
                } label: {
                    DataActionRow(
                        title: L10n.Settings.importCSV,
                        subtitle: L10n.Settings.importCSVSubtitle,
                        systemImage: "square.and.arrow.down.fill",
                        tint: .indigo,
                        isLoading: isOperationActive(.importCSV)
                    )
                }
                .disabled(viewModel.isBackupInProgress)

                if isOperationActive(.importCSV) {
                    VStack(alignment: .leading, spacing: 6) {
                        if !viewModel.backupStatusMessage.isEmpty {
                            Text(viewModel.backupStatusMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: viewModel.backupProgress, total: 1.0)
                    }
                    .padding(.vertical, 4)
                    .accessibleGroup(label: viewModel.backupStatusMessage)
                }
            } header: {
                Text(L10n.Settings.importData)
            } footer: {
                Text(L10n.Settings.importCSVFormat)
            }

            // 缓存存储
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.Settings.mediaCacheUsage)
                        Text(L10n.Settings.mediaCacheSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(cacheSize)
                        .foregroundStyle(.secondary)
                }

                Button(role: .destructive) {
                    showingClearCacheAlert = true
                } label: {
                    Label(L10n.Settings.clearCache, systemImage: "trash")
                }
            } header: {
                Text(L10n.Settings.storageSpace)
            }
        }
        .listStyle(.insetGrouped)
        .accessibilityIdentifier("settings.dataAndSync.root")
        .navigationTitle(L10n.Settings.dataAndSync)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .alert(L10n.Settings.clearCacheTitle, isPresented: $showingClearCacheAlert) {
            Button(L10n.Settings.clearCacheAction, role: .destructive) {
                clearCache()
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Settings.clearCacheMessage)
        }
        .onAppear {
            calculateCacheSize()
        }
        .onDisappear {
            cacheCalculateTask?.cancel()
            cacheClearTask?.cancel()
            backupTask?.cancel()
            restoreTask?.cancel()
            importTask?.cancel()
            activeOperation = nil
        }
        .confirmationDialog(
            L10n.Settings.restoreDialogTitle,
            isPresented: $showingRestoreConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.Settings.selectBackupFile, role: .destructive) {
                showingRestoreFilePicker = true
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Settings.restoreDialogMessage)
        }
        .fileImporter(
            isPresented: $showingRestoreFilePicker,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                restoreTask?.cancel()
                restoreTask = Task {
                    activeOperation = .restore
                    defer { activeOperation = nil }
                    await viewModel.restoreFromBackup(fileURL: url)
                    if viewModel.backupError != nil {
                        showingBackupError = true
                    } else {
                        showingRestoreSuccess = true
                    }
                }
            case .failure:
                viewModel.backupError = L10n.Errors.fileAccessDenied
                showingBackupError = true
            }
        }
        .sheet(
            isPresented: $showingShareSheet,
            onDismiss: { viewModel.cleanupBackupFile() },
            content: {
                if let url = viewModel.backupFileURL {
                    ShareSheet(items: [url])
                }
            }
        )
        .alert(L10n.Settings.operationFailed, isPresented: $showingBackupError) {
            Button(L10n.Common.ok) {
                viewModel.backupError = nil
            }
        } message: {
            Text(viewModel.backupError ?? L10n.Settings.unknownError)
        }
        .alert(L10n.Settings.restoreSuccess, isPresented: $showingRestoreSuccess) {
            Button(L10n.Common.ok) {}
        } message: {
            Text(viewModel.backupStatusMessage)
        }
        .fileImporter(
            isPresented: $showingImportFilePicker,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importTask?.cancel()
                importTask = Task {
                    activeOperation = .importCSV
                    defer { activeOperation = nil }
                    await viewModel.importCSV(fileURL: url)
                    if viewModel.backupError != nil {
                        showingBackupError = true
                    } else {
                        showingImportSuccess = true
                    }
                }
            case .failure:
                viewModel.backupError = L10n.Errors.fileAccessDenied
                showingBackupError = true
            }
        }
        .alert(L10n.Settings.importData, isPresented: $showingImportSuccess) {
            Button(L10n.Common.ok) {}
        } message: {
            Text(viewModel.backupStatusMessage)
        }
    }

    // MARK: - Private Helpers

    private var shouldShowBackupProgress: Bool {
        viewModel.isBackupInProgress && activeOperation != .importCSV
    }

    private func isOperationActive(_ operation: DataOperation) -> Bool {
        viewModel.isBackupInProgress && activeOperation == operation
    }

    private func calculateCacheSize() {
        cacheCalculateTask?.cancel()
        cacheCalculateTask = Task {
            let size = await getCacheSize()
            await MainActor.run {
                cacheSize = formatBytes(size)
            }
        }
    }

    private func clearCache() {
        cacheClearTask?.cancel()
        cacheClearTask = Task {
            do {
                // 清理临时目录
                let tmpDir = FileManager.default.temporaryDirectory
                let tmpContents = try FileManager.default.contentsOfDirectory(at: tmpDir, includingPropertiesForKeys: nil)
                for url in tmpContents {
                    try? FileManager.default.removeItem(at: url) // best-effort: 单文件删除失败不中断整批清理
                }

                // 清理缓存目录
                if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                    let cacheContents = try FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil)
                    for url in cacheContents {
                        try? FileManager.default.removeItem(at: url) // best-effort: 单文件删除失败不中断整批清理
                    }
                }

                await MainActor.run {
                    cacheSize = "0 MB"
                }
            } catch {
                SnapDrillLogger.generic.error("Failed to clear cache: \(error.localizedDescription)")
            }
        }
    }

    private func getCacheSize() async -> Int64 {
        var totalSize: Int64 = 0

        // 计算临时目录大小
        let tmpDir = FileManager.default.temporaryDirectory
        totalSize += directorySize(at: tmpDir)

        // 计算缓存目录大小
        if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            totalSize += directorySize(at: cacheDir)
        }

        return totalSize
    }

    private func directorySize(at url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var size: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            size += Int64(fileSize)
        }

        return size
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

private enum DataOperation {
    case backup
    case restore
    case importCSV
}

private struct DataNoticeRow: View {
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "externaldrive.badge.checkmark")
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct DataActionRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 2)
    }
}

// Preview 需要 RepositoryContainer 初始化 SettingsViewModel，
// 但 PreviewRepositoryContainer 无法直接转为 RepositoryContainer。
// 通过 Xcode GUI 运行 Preview 时可正常显示。
