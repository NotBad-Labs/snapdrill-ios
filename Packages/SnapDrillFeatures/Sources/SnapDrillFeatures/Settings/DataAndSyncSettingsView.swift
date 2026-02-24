//
//  DataAndSyncSettingsView.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2026/01/02.
//

import SwiftUI
import CloudKit
import SnapDrillCore

/// 数据与云同步设置页面
struct DataAndSyncSettingsView: View {
    // Cloud Sync
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = true
    @State private var accountStatus: CKAccountStatus = .couldNotDetermine
    @State private var isCheckingStatus = false
    
    // Network Status
    @Environment(NetworkMonitor.self) private var networkMonitor
    
    // Storage Cache
    @AppStorage("autoDeleteOldItems") private var autoDeleteOldItems = false
    @AppStorage("autoDeleteDays") private var autoDeleteDays = 30
    @State private var showingClearCacheAlert = false
    @State private var cacheSize: String = "计算中..."
    
    var body: some View {
        List {
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
    }
    
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
        // Use container identifier if set, otherwise default
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                isCheckingStatus = false
                if let error = error {
                    SnapDrillLogger.generic.info("iCloud status error: \(error)")
                    self.accountStatus = .couldNotDetermine
                } else {
                    self.accountStatus = status
                }
            }
        }
    }
    
    private func calculateCacheSize() {
        Task {
            let size = await getCacheSize()
            await MainActor.run {
                cacheSize = formatBytes(size)
            }
        }
    }
    
    private func clearCache() {
        Task {
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

#Preview {
    NavigationStack {
        DataAndSyncSettingsView()
    }
}
