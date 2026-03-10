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

    // Network Status
    @Environment(NetworkMonitor.self) private var networkMonitor

    // Storage Cache
    @AppStorage(UDKey.autoDeleteOldItems) private var autoDeleteOldItems = false
    @AppStorage(UDKey.autoDeleteDays) private var autoDeleteDays = 30
    @State private var showingClearCacheAlert = false
    @State private var cacheSize: String = "计算中..."
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
                    Text("启用 iCloud 同步")
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
                            Text("检查账户状态...")
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
                Text("云同步")
            } footer: {
                if !networkMonitor.isConnected {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundStyle(.orange)
                        Text("当前离线，数据将在网络恢复后自动同步")
                            .foregroundStyle(.orange)
                    }
                    .font(.caption)
                } else if iCloudSyncEnabled {
                    Text("数据将自动在您的 Apple 设备间保持同步。请确保在系统设置中开启 iCloud 云盘。")
                } else {
                    Text("同步已关闭。数据仅保存在本机。")
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
                        Label("备份数据", systemImage: "arrow.up.doc")
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
                    Label("恢复数据", systemImage: "arrow.down.doc")
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
                Text("备份与恢复")
            } footer: {
                Text("备份文件包含所有题目、分类设置和图片。恢复操作将替换当前全部数据。")
            }

            // Cache Storage
            Section {
                HStack {
                    Text("媒体缓存占用")
                    Spacer()
                    Text(cacheSize)
                        .foregroundStyle(.secondary)
                }
                
                Button(role: .destructive) {
                    showingClearCacheAlert = true
                } label: {
                    Text("清理缓存")
                }
            } header: {
                Text("存储空间")
            }
            
            // Auto Cleanup
            Section {
                Toggle("自动归档旧题目", isOn: $autoDeleteOldItems)
                
                if autoDeleteOldItems {
                    Picker("归档时间", selection: $autoDeleteDays) {
                        Text("30 天前").tag(30)
                        Text("60 天前").tag(60)
                        Text("90 天前").tag(90)
                        Text("180 天前").tag(180)
                    }
                }
            } header: {
                Text("数据维护")
            } footer: {
                Text("自动归档长期未复习的题目，保持题库轻量化。归档后的题目仍可搜索但不会自动安排复习。")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("数据与云同步")
        .navigationBarTitleDisplayMode(.inline)
        .alert("清理缓存", isPresented: $showingClearCacheAlert) {
            Button("清理", role: .destructive) {
                clearCache()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("清理缓存不会删除您的题目数据，仅删除临时图片和下载的资源。")
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
            "恢复数据",
            isPresented: $showingRestoreConfirmation,
            titleVisibility: .visible
        ) {
            Button("选择备份文件", role: .destructive) {
                showingRestoreFilePicker = true
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("恢复将替换当前所有数据，此操作不可撤销。恢复前会自动备份当前数据到临时目录。")
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
            case .failure(let error):
                viewModel.backupError = error.localizedDescription
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
        .alert("操作失败", isPresented: $showingBackupError) {
            Button("确定") {
                viewModel.backupError = nil
            }
        } message: {
            Text(viewModel.backupError ?? "未知错误")
        }
        .alert("恢复成功", isPresented: $showingRestoreSuccess) {
            Button("确定") {}
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
        case .available: return "iCloud 运行正常"
        case .noAccount: return "未登录 iCloud"
        case .restricted: return "iCloud 受限"
        case .temporarilyUnavailable: return "暂时服务不可用"
        case .couldNotDetermine: return "无法获取状态"
        @unknown default: return "未知状态"
        }
    }
    
    private var statusMessage: String {
        switch accountStatus {
        case .available: return "正在后台自动同步数据"
        case .noAccount: return "请在系统设置中登录 Apple ID"
        case .restricted: return "请检查屏幕使用时间设置"
        case .temporarilyUnavailable: return "请检查网络连接"
        case .couldNotDetermine: return DataAndSyncSettingsView.isCloudKitConfigured ? "请稍后重试" : "需在 Xcode 开启 iCloud 能力"
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
