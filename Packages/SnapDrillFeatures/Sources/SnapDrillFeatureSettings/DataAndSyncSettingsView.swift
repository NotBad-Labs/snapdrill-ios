//
//  DataAndSyncSettingsView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  数据设置页面，管理备份、恢复和 CSV 导入。
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
#if DEBUG
    @State private var didApplyUITestOperation = false
#endif

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
                .accessibilityIdentifier("settings.dataAndSync.backup")
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
                .accessibilityIdentifier("settings.dataAndSync.restore")
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
                    .accessibilityIdentifier("settings.dataAndSync.backupProgress")
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
                .accessibilityIdentifier("settings.dataAndSync.importCSV")

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
                    .accessibilityIdentifier("settings.dataAndSync.importProgress")
                }
            } header: {
                Text(L10n.Settings.importData)
            } footer: {
                Text(L10n.Settings.importCSVFormat)
            }
        }
        .listStyle(.insetGrouped)
        .accessibilityIdentifier("settings.dataAndSync.root")
        .navigationTitle(L10n.Settings.dataAndSync)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
#if DEBUG
        .onAppear {
            applyUITestOperationIfNeeded()
        }
#endif
        .onDisappear {
            backupTask?.cancel()
            restoreTask?.cancel()
            importTask?.cancel()
#if DEBUG
            if didApplyUITestOperation {
                clearUITestOperation()
            } else {
                activeOperation = nil
            }
#else
            activeOperation = nil
#endif
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

#if DEBUG
    private static let uiTestBackupProgressArgument = "--ui-test-data-sync-backup-progress"
    private static let uiTestImportProgressArgument = "--ui-test-data-sync-import-progress"

    private func applyUITestOperationIfNeeded() {
        let arguments = ProcessInfo.processInfo.arguments
        guard !didApplyUITestOperation,
              arguments.contains("--uitesting") else {
            return
        }

        if arguments.contains(Self.uiTestBackupProgressArgument) {
            didApplyUITestOperation = true
            activeOperation = .backup
            viewModel.isBackupInProgress = true
            viewModel.backupProgress = 0.58
            viewModel.backupStatusMessage = L10n.Settings.backupPackingItems(24)
        } else if arguments.contains(Self.uiTestImportProgressArgument) {
            didApplyUITestOperation = true
            activeOperation = .importCSV
            viewModel.isBackupInProgress = true
            viewModel.backupProgress = 0.42
            viewModel.backupStatusMessage = L10n.Settings.importSaving(36)
        }
    }

    private func clearUITestOperation() {
        didApplyUITestOperation = false
        activeOperation = nil
        viewModel.isBackupInProgress = false
        viewModel.backupProgress = 0
        viewModel.backupStatusMessage = ""
    }
#endif
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
