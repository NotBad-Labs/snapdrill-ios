//
//  DataAndSyncSettingsView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/01/02.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  数据与同步设置页面，管理数据导出、清空等操作。
//

import SwiftUI
import CloudKit
import UniformTypeIdentifiers
import SnapDrillCore
import SnapDrillData

/// 数据与云同步设置页面
struct DataAndSyncSettingsView: View {

    // MARK: - Properties

    @Bindable var viewModel: SettingsViewModel

    // Cloud Sync
    @AppStorage(UDKey.iCloudSyncEnabled) private var iCloudSyncEnabled = true
    @State private var accountStatus: CKAccountStatus = .couldNotDetermine
    @State private var isCheckingStatus = false

    // Storage Cache
    @AppStorage(UDKey.autoDeleteOldItems) private var autoDeleteOldItems = false
    @AppStorage(UDKey.autoDeleteDays) private var autoDeleteDays = 30
    @State private var showingClearCacheAlert = false
    @State private var cacheSize: String = L10n.Settings.calculating
    @State private var cacheCalculateTask: Task<Void, Never>?
    @State private var cacheClearTask: Task<Void, Never>?
    @State private var accountCheckTask: Task<Void, Never>?

    // Backup / Restore
    @State private var backupTask: Task<Void, Never>?
    @State private var restoreTask: Task<Void, Never>?
    @State private var showingRestoreConfirmation = false
    @State private var showingRestoreFilePicker = false
    @State private var showingShareSheet = false
    @State private var showingBackupError = false
    @State private var showingRestoreSuccess = false
    
    var body: some View {
        List {
            if !iCloudSyncEnabled {
                Section {
                    LocalDataWarningView(compact: false)
                }
            }

            // Cloud Sync Section (Real Logic)
            Section {
                Toggle(isOn: $iCloudSyncEnabled) {
                    Text(L10n.Settings.enableICloudSync)
                        .foregroundStyle(.primary)
                }
                .onChange(of: iCloudSyncEnabled) { _, _ in
                    if iCloudSyncEnabled {
                        checkAccountStatus()
                    }
                }
                
                if iCloudSyncEnabled {
                    HStack {
                        if isCheckingStatus {
                            ProgressView()
                                .controlSize(.small)
                            Text(L10n.Settings.checkingAccountStatus)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            statusIcon
                            VStack(alignment: .leading, spacing: 2) {
                                Text(statusTitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Text(statusMessage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text(L10n.Settings.cloudSync)
            } footer: {
                if iCloudSyncEnabled {
                    Text(L10n.Settings.icloudSyncFooter)
                } else {
                    Text(L10n.Settings.syncDisabledFooter)
                }
            }
            
            // Backup / Restore
            Section {
                // 备份按钮
                Button {
                    backupTask?.cancel()
                    backupTask = Task {
                        await viewModel.createBackup()
                        if viewModel.backupFileURL != nil {
                            showingShareSheet = true
                        } else if viewModel.backupError != nil {
                            showingBackupError = true
                        }
                    }
                } label: {
                    HStack {
                        Label(L10n.Settings.backupData, systemImage: "arrow.up.doc")
                        Spacer()
                        if viewModel.isBackupInProgress && viewModel.backupFileURL == nil {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(viewModel.isBackupInProgress)

                // 恢复按钮
                Button {
                    showingRestoreConfirmation = true
                } label: {
                    Label(L10n.Settings.restoreData, systemImage: "arrow.down.doc")
                }
                .disabled(viewModel.isBackupInProgress)

                // 进度条（备份/恢复过程中显示）
                if viewModel.isBackupInProgress {
                    VStack(alignment: .leading, spacing: 6) {
                        if !viewModel.backupStatusMessage.isEmpty {
                            Text(viewModel.backupStatusMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: viewModel.backupProgress, total: 1.0)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text(L10n.Settings.backup)
            } footer: {
                Text(L10n.Settings.backupFooter)
            }

            // Cache Storage
            Section {
                HStack {
                    Text(L10n.Settings.mediaCacheUsage)
                    Spacer()
                    Text(cacheSize)
                        .foregroundStyle(.secondary)
                }

                Button(role: .destructive) {
                    showingClearCacheAlert = true
                } label: {
                    Text(L10n.Settings.clearCache)
                }
            } header: {
                Text(L10n.Settings.storageSpace)
            }
            
            // Auto Cleanup
            Section {
                Toggle(L10n.Settings.autoArchiveOldItems, isOn: $autoDeleteOldItems)

                if autoDeleteOldItems {
                    Picker(L10n.Settings.archiveTime, selection: $autoDeleteDays) {
                        Text(L10n.Settings.daysAgo30).tag(30)
                        Text(L10n.Settings.daysAgo60).tag(60)
                        Text(L10n.Settings.daysAgo90).tag(90)
                        Text(L10n.Settings.daysAgo180).tag(180)
                    }
                }
            } header: {
                Text(L10n.Settings.dataMaintenance)
            } footer: {
                Text(L10n.Settings.dataMaintenanceFooter)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.Settings.dataAndSync)
        .navigationBarTitleDisplayMode(.inline)
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
            if iCloudSyncEnabled {
                checkAccountStatus()
            }
        }
        .onDisappear {
            cacheCalculateTask?.cancel()
            cacheClearTask?.cancel()
            accountCheckTask?.cancel()
            backupTask?.cancel()
            restoreTask?.cancel()
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
            allowedContentTypes: [UTType(filenameExtension: "snapdrill") ?? .zip, .zip],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                restoreTask?.cancel()
                restoreTask = Task {
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
    }
    
    // MARK: - Private Helpers
    
    // MARK: - Status Logic
    
    private var statusIcon: some View {
        switch accountStatus {
        case .available:
            return Image(systemName: "checkmark.icloud.fill").foregroundStyle(.green)
        case .noAccount, .restricted, .couldNotDetermine:
            return Image(systemName: "exclamationmark.icloud.fill").foregroundStyle(.orange)
        case .temporarilyUnavailable:
            return Image(systemName: "arrow.triangle.2.circlepath.icloud.fill").foregroundStyle(.yellow)
        @unknown default:
            return Image(systemName: "icloud").foregroundStyle(.gray)
        }
    }
    
    private var statusTitle: String {
        switch accountStatus {
        case .available: return L10n.Settings.icloudRunning
        case .noAccount: return L10n.Settings.icloudNotLoggedIn
        case .restricted: return L10n.Settings.icloudStatusRestricted
        case .temporarilyUnavailable: return L10n.Settings.icloudTemporarilyUnavailable
        case .couldNotDetermine: return L10n.Settings.icloudCannotDetermine
        @unknown default: return L10n.Settings.icloudUnknown
        }
    }

    private var statusMessage: String {
        switch accountStatus {
        case .available: return L10n.Settings.icloudSyncingInBackground
        case .noAccount: return L10n.Settings.icloudLoginPrompt
        case .restricted: return L10n.Settings.icloudCheckScreenTime
        case .temporarilyUnavailable: return L10n.Settings.icloudCheckNetwork
        case .couldNotDetermine: return DataAndSyncSettingsView.isCloudKitConfigured ? L10n.Settings.icloudRetryLater : L10n.Settings.icloudNeedXcodeCapability
        @unknown default: return ""
        }
    }
    
    // SAFETY GATE: Change this to true ONLY after enabling iCloud in Xcode -> Signing & Capabilities
    private static let isCloudKitConfigured = true
    
    private func checkAccountStatus() {
        // Prevent crash if entitlement is missing
        guard Self.isCloudKitConfigured else {
            self.accountStatus = .couldNotDetermine
            return
        }
        
        isCheckingStatus = true
        accountCheckTask?.cancel()
        accountCheckTask = Task { @MainActor in
            do {
                let status = try await CKContainer.default().accountStatus()
                isCheckingStatus = false
                accountStatus = status
            } catch {
                isCheckingStatus = false
                SnapDrillLogger.generic.info("iCloud status error: \(error)")
                accountStatus = .couldNotDetermine
            }
        }
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
                    try? FileManager.default.removeItem(at: url)
                }
                
                // 清理缓存目录
                if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                    let cacheContents = try FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil)
                    for url in cacheContents {
                        try? FileManager.default.removeItem(at: url)
                    }
                }
                
                await MainActor.run {
                    cacheSize = "0 MB"
                }
            } catch {
                SnapDrillLogger.generic.info("Failed to clear cache: \(error)")
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

// Preview 需要 RepositoryContainer 初始化 SettingsViewModel，
// 但 PreviewRepositoryContainer 无法直接转为 RepositoryContainer。
// 通过 Xcode GUI 运行 Preview 时可正常显示。
