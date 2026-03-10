//
//  SettingsViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  设置页 ViewModel，处理数据清除等操作。
//

import SwiftUI
import Observation
import SnapDrillCore
import SnapDrillData

/// 设置页 ViewModel
///
/// 处理设置页面的数据操作（如清除全部数据、备份/恢复）。
@Observable
@MainActor
public final class SettingsViewModel {
    private let repositories: RepositoryContainer
    private let backupService = BackupService()

    // MARK: - Properties

    /// 备份/恢复操作进度（0.0 ~ 1.0）
    public var backupProgress: Double = 0
    /// 是否正在执行备份/恢复操作
    public var isBackupInProgress = false
    /// 备份/恢复操作的状态消息
    public var backupStatusMessage = ""
    /// 备份/恢复错误信息
    public var backupError: String?
    /// 备份完成后的文件 URL（用于 ShareLink）
    public var backupFileURL: URL?

    // MARK: - Initialization

    /// 创建设置页 ViewModel
    /// - Parameter repositories: 应用的数据仓库容器
    public init(repositories: RepositoryContainer) {
        self.repositories = repositories
    }

    // MARK: - Public API

    /// 清空所有题目数据并通知 UI 刷新
    ///
    /// 操作不可撤销，失败时自动回滚 `mainContext` 以防止脏数据。
    public func clearAllData() async {
        do {
            try await repositories.deleteAllData()
            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
            SnapDrillLogger.generic.info("所有数据已清空，已通知 UI 刷新。")
        } catch {
            // deleteAllData 内部为多步写入，部分已落盘的步骤无法通过 rollback 撤回；
            // 此处 rollback 仅清理内存脏状态，防止未落盘的待删对象被后续操作意外持久化
            repositories.review.rollbackContext()
            SnapDrillLogger.generic.error("清空数据失败: \(error)")
        }
    }

    // MARK: - Backup

    /// 创建全量备份文件
    ///
    /// 收集所有数据和图片，打包为 .snapdrill (ZIP) 文件。
    /// 完成后将文件 URL 存入 `backupFileURL`，供 View 层触发分享。
    public func createBackup() async {
        guard !isBackupInProgress else { return }
        isBackupInProgress = true
        backupProgress = 0
        backupError = nil
        backupFileURL = nil
        backupStatusMessage = "正在准备数据..."

        do {
            // 1. 收集数据（MainActor 上）
            let payload = try repositories.collectBackupPayload()
            let itemCount = payload.reviewItems.count

            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            let manifest = BackupManifest(
                schemaVersion: BackupManifest.currentSchemaVersion,
                createdAt: Date(),
                appVersion: appVersion,
                itemCount: itemCount
            )

            // 2. 获取 Documents 目录路径
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

            backupStatusMessage = "正在打包 \(itemCount) 道题目..."

            // 3. 在 BackupService actor 上打包 ZIP
            let url = try await backupService.createBackup(
                payload: payload,
                manifest: manifest,
                imageBasePath: documentsURL
            ) { [weak self] current, total in
                Task { @MainActor in
                    guard let self else { return }
                    self.backupProgress = total > 0 ? Double(current) / Double(total) : 1.0
                }
            }

            backupFileURL = url
            backupStatusMessage = "备份完成"
            SnapDrillLogger.generic.info("备份完成: \(itemCount) 道题目")
        } catch {
            backupError = error.localizedDescription
            backupStatusMessage = ""
            SnapDrillLogger.generic.error("备份失败: \(error)")
        }

        isBackupInProgress = false
    }

    // MARK: - Restore

    /// 从备份文件恢复数据
    ///
    /// 恢复前先自动备份当前数据到临时目录（安全网），然后全量替换。
    ///
    /// - Parameter fileURL: 用户选择的 .snapdrill 备份文件路径
    public func restoreFromBackup(fileURL: URL) async {
        guard !isBackupInProgress else { return }
        isBackupInProgress = true
        backupProgress = 0
        backupError = nil
        backupStatusMessage = "正在验证备份文件..."

        // 安全域访问（fileImporter 选择的文件在安全沙箱外）
        guard fileURL.startAccessingSecurityScopedResource() else {
            backupError = "无法访问选择的文件"
            isBackupInProgress = false
            return
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }

        do {
            // 1. 读取并验证 manifest
            let manifest = try await backupService.readManifest(from: fileURL)
            if manifest.schemaVersion > BackupManifest.currentSchemaVersion {
                throw BackupError.schemaVersionTooNew(
                    fileVersion: manifest.schemaVersion,
                    appVersion: BackupManifest.currentSchemaVersion
                )
            }

            backupStatusMessage = "正在恢复前自动备份当前数据..."

            // 2. 恢复前自动备份当前数据（安全网）
            await createAutoBackupBeforeRestore()

            backupStatusMessage = "正在读取备份数据..."

            // 3. 提取 payload
            let payload = try await backupService.extractPayload(from: fileURL)

            backupStatusMessage = "正在恢复 \(manifest.itemCount) 道题目..."

            // 4. 恢复数据库
            try await repositories.restoreFromPayload(payload)

            backupStatusMessage = "正在恢复图片..."

            // 5. 恢复图片文件（数据库已恢复，图片失败不回滚数据库）
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            do {
                try await backupService.restoreImages(
                    from: fileURL,
                    to: documentsURL
                ) { [weak self] current, total in
                    Task { @MainActor in
                        guard let self else { return }
                        self.backupProgress = total > 0 ? Double(current) / Double(total) : 1.0
                    }
                }
            } catch {
                // 数据库已恢复成功，但图片恢复失败——提示用户可重新恢复
                SnapDrillLogger.generic.error("图片恢复失败（数据已恢复）: \(error)")
                NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
                backupStatusMessage = "数据已恢复，但部分图片恢复失败。可尝试重新恢复以修复图片。"
                isBackupInProgress = false
                return
            }

            // 6. 通知 UI 刷新
            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
            backupStatusMessage = "恢复完成"
            SnapDrillLogger.generic.info("恢复完成: \(manifest.itemCount) 道题目")
        } catch {
            backupError = error.localizedDescription
            backupStatusMessage = ""
            SnapDrillLogger.generic.error("恢复失败: \(error)")
        }

        isBackupInProgress = false
    }

    /// 清理备份产生的临时文件
    ///
    /// 在 ShareSheet 关闭后调用，删除临时目录中的 .snapdrill 文件。
    public func cleanupBackupFile() {
        guard let url = backupFileURL else { return }
        try? FileManager.default.removeItem(at: url)
        backupFileURL = nil
        backupStatusMessage = ""
        SnapDrillLogger.generic.info("已清理备份临时文件: \(url.lastPathComponent)")
    }

    // MARK: - Private Helpers

    /// 恢复前自动备份当前数据到临时目录（best-effort，不中断恢复流程）
    private func createAutoBackupBeforeRestore() async {
        do {
            let payload = try repositories.collectBackupPayload()
            let itemCount = payload.reviewItems.count
            // 没有数据时无需备份
            guard itemCount > 0 else { return }

            let manifest = BackupManifest(
                schemaVersion: BackupManifest.currentSchemaVersion,
                createdAt: Date(),
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                itemCount: itemCount
            )
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let url = try await backupService.createBackup(
                payload: payload,
                manifest: manifest,
                imageBasePath: documentsURL
            )
            SnapDrillLogger.generic.info("恢复前自动备份已保存: \(url.lastPathComponent)")
        } catch {
            // 自动备份失败不中断恢复流程，仅记录日志
            SnapDrillLogger.generic.warning("恢复前自动备份失败（不影响恢复操作）: \(error)")
        }
    }
}
