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
public final class SettingsViewModel {
    private let repositories: RepositoryContainer
    private let profileManager: ProfileManager
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
    /// 清空数据操作的错误信息
    public var clearError: String?

    // MARK: - Initialization

    /// 创建设置页 ViewModel
    /// - Parameters:
    ///   - repositories: 应用的数据仓库容器
    ///   - profileManager: Profile 管理器（备份恢复需要遍历所有 Profile）。测试中可传入默认实例
    public init(repositories: RepositoryContainer, profileManager: ProfileManager = ProfileManager()) {
        self.repositories = repositories
        self.profileManager = profileManager
    }

    // MARK: - Helpers

    /// 获取当前活跃 Profile 的目录路径
    private static func activeProfileDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if let profileId = UserDefaults.standard.string(forKey: UDKey.activeProfileId) {
            return docs.appendingPathComponent("profiles").appendingPathComponent(profileId)
        }
        return docs
    }

    /// 获取指定 Profile 的目录路径
    private static func profileDirectory(for profileId: UUID) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("profiles").appendingPathComponent(profileId.uuidString)
    }

    // MARK: - Public API

    /// 清空所有题目数据并通知 UI 刷新
    ///
    /// 操作不可撤销，失败时自动回滚 `mainContext` 以防止脏数据。
    public func clearAllData() async {
        clearError = nil
        do {
            try await repositories.deleteAllData()
            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
            SnapDrillLogger.generic.info("所有数据已清空，已通知 UI 刷新。")
        } catch {
            // deleteAllData 内部为多步写入，部分已落盘的步骤无法通过 rollback 撤回；
            // 此处 rollback 仅清理内存脏状态，防止未落盘的待删对象被后续操作意外持久化
            repositories.review.rollbackContext()
            SnapDrillLogger.generic.error("清空数据失败: \(error)")
            clearError = L10n.Settings.clearFailed
        }
    }

    // MARK: - Backup

    /// 创建全量备份文件
    ///
    /// 收集所有数据和图片，打包为 .snapdrill (ZIP) 文件。
    /// 完成后将文件 URL 存入 `backupFileURL`，供 View 层触发分享。
    public func createBackup() async {
        guard !isBackupInProgress else { return }
        AppActivityTracker.shared.begin(.backupRestore)
        defer { AppActivityTracker.shared.end(.backupRestore) }
        isBackupInProgress = true; backupProgress = 0
        backupError = nil; backupFileURL = nil; backupStatusMessage = L10n.Settings.backupPreparingData

        do {
            // 1. 收集所有 Profile 数据
            var profileDataList: [ProfileBackupData] = []
            var totalItemCount = 0

            for profile in profileManager.profiles {
                let profileDir = Self.profileDirectory(for: profile.id)
                let storeURL = profileDir.appendingPathComponent("default.store")

                if profile.id == profileManager.activeProfileId {
                    // 活跃 Profile 直接用当前 repositories
                    let data = try repositories.collectProfileBackupData(
                        profileName: profile.name, profileId: profile.id
                    )
                    profileDataList.append(data)
                    totalItemCount += data.reviewItems.count
                } else {
                    // 非活跃 Profile 临时创建容器
                    let tempPersistence = PersistenceController(storeURL: storeURL)
                    let tempRepos = RepositoryContainer(
                        modelContext: tempPersistence.container.mainContext
                    )
                    let data = try tempRepos.collectProfileBackupData(
                        profileName: profile.name, profileId: profile.id
                    )
                    profileDataList.append(data)
                    totalItemCount += data.reviewItems.count
                }
            }

            let payload = BackupPayload(profiles: profileDataList)
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            let manifest = BackupManifest(
                schemaVersion: BackupManifest.currentSchemaVersion,
                createdAt: Date(),
                appVersion: appVersion,
                totalItemCount: totalItemCount,
                profileCount: profileDataList.count,
                profileNames: profileDataList.map(\.profileName)
            )

            backupStatusMessage = L10n.Settings.backupPackingItems(totalItemCount)

            // 2. 在 BackupService actor 上打包 ZIP（传所有 Profile 目录）
            let url = try await backupService.createBackup(
                payload: payload,
                manifest: manifest,
                profileDirectories: profileDataList.map { Self.profileDirectory(for: $0.profileId) }
            ) { [weak self] current, total in
                Task { @MainActor in
                    guard let self else { return }
                    self.backupProgress = total > 0 ? Double(current) / Double(total) : 1.0
                }
            }

            backupFileURL = url
            backupStatusMessage = L10n.Settings.backupComplete
            SnapDrillLogger.generic.info("备份完成: \(totalItemCount) 道题目，\(profileDataList.count) 个 Profile")
        } catch {
            backupError = L10n.Errors.backupFailed
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
        AppActivityTracker.shared.begin(.backupRestore)
        defer { AppActivityTracker.shared.end(.backupRestore) }
        isBackupInProgress = true; backupProgress = 0
        backupError = nil; backupStatusMessage = L10n.Settings.restoreVerifying

        // 安全域访问（fileImporter 选择的文件在安全沙箱外）
        guard fileURL.startAccessingSecurityScopedResource() else {
            backupError = L10n.Errors.fileAccessDenied
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

            backupStatusMessage = L10n.Settings.restoreAutoBackup

            // 2. 恢复前自动备份当前数据（安全网）
            let autoBackupURL = await createAutoBackupBeforeRestore()

            backupStatusMessage = L10n.Settings.restoreReadingData

            // 3. 提取 payload
            let payload = try await backupService.extractPayload(from: fileURL)

            backupStatusMessage = L10n.Settings.restoreRestoringItems(manifest.totalItemCount)

            // 4. 逐个 Profile 恢复数据库和图片
            try await restoreAllProfiles(from: fileURL, payload: payload, autoBackupURL: autoBackupURL)

            // 5. 恢复完全成功 → 清理自动备份
            cleanupAutoBackup(autoBackupURL)

            // 6. 通知 UI 刷新
            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
            backupStatusMessage = L10n.Settings.restoreComplete
            SnapDrillLogger.generic.info("恢复完成: \(manifest.totalItemCount) 道题目，\(manifest.profileCount) 个 Profile")
        } catch {
            backupError = L10n.Errors.restoreFailed
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
        try? FileManager.default.removeItem(at: url) // best-effort: 临时备份文件残留不影响功能
        backupFileURL = nil
        backupStatusMessage = ""
        SnapDrillLogger.generic.info("已清理备份临时文件: \(url.lastPathComponent)")
    }

    // MARK: - CSV 导入

    /// 从 CSV 文件导入题目数据
    ///
    /// CSV 首行为列名，支持的列：Content, Subject, Source, Difficulty, Answer, Grade, Tags。
    /// 列名不区分大小写，缺失列使用默认值。
    public func importCSV(fileURL: URL) async {
        guard !isBackupInProgress else { return }
        AppActivityTracker.shared.begin(.backupRestore)
        defer { AppActivityTracker.shared.end(.backupRestore) }
        isBackupInProgress = true; backupProgress = 0
        backupError = nil; backupStatusMessage = L10n.Settings.importReading
        let accessing = fileURL.startAccessingSecurityScopedResource()
        defer { if accessing { fileURL.stopAccessingSecurityScopedResource() } }

        do {
            let csvString = try String(contentsOf: fileURL, encoding: .utf8)
            backupStatusMessage = L10n.Settings.importParsing

            let rows = parseCSV(csvString)
            guard !rows.isEmpty else {
                backupError = L10n.Settings.importNoValidRows
                isBackupInProgress = false
                backupStatusMessage = ""
                return
            }

            backupStatusMessage = L10n.Settings.importSaving(rows.count)

            // 批量创建 ReviewItemModel（每 50 条 yield 一次，避免长时间阻塞主线程）
            for (index, row) in rows.enumerated() {
                let model = ReviewItemModel(
                    content: row["content"],
                    subject: row["subject"] ?? "",
                    source: row["source"] ?? "",
                    answerText: row["answer"],
                    difficulty: min(5, max(1, Int(row["difficulty"] ?? "1") ?? 1)),
                    grade: row["grade"] ?? ""
                )
                repositories.review.insert(model)

                // 处理标签
                if let tagsString = row["tags"], !tagsString.isEmpty {
                    let tagNames = tagsString.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    for tagName in tagNames {
                        let tag = try repositories.tag.fetchOrCreateModel(name: tagName, colorHex: "")
                        model.tags = (model.tags ?? []) + [tag]
                    }
                }

                backupProgress = Double(index + 1) / Double(rows.count)

                // 每 50 条让出主线程，让 UI 更新进度
                if (index + 1).isMultiple(of: 50) {
                    await Task.yield()
                }
            }

            try repositories.review.saveContext()

            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
            backupStatusMessage = L10n.Settings.importComplete(rows.count)
            SnapDrillLogger.generic.info("CSV 导入完成: \(rows.count) 道题")
        } catch {
            repositories.review.rollbackContext()
            backupError = L10n.Settings.importFailed
            backupStatusMessage = ""
            SnapDrillLogger.generic.error("CSV 导入失败: \(error)")
        }

        isBackupInProgress = false
    }

    /// 解析 CSV 文本为字典数组
    ///
    /// - Returns: 每行一个字典，key 为列名（小写），value 为字段值
    private func parseCSV(_ csvString: String) -> [[String: String]] {
        let lines = csvString.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count >= 2 else { return [] }

        let headers = parseCSVLine(lines[0]).map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        guard !headers.isEmpty else { return [] }

        var results: [[String: String]] = []
        for lineIndex in 1..<lines.count {
            let values = parseCSVLine(lines[lineIndex])
            var row: [String: String] = [:]
            for (index, header) in headers.enumerated() where index < values.count {
                let value = values[index].trimmingCharacters(in: .whitespaces)
                if !value.isEmpty {
                    row[header] = value
                }
            }
            // 至少有 content 或 subject 才算有效行
            if row["content"] != nil || row["subject"] != nil {
                results.append(row)
            }
        }
        return results
    }

    /// 解析单行 CSV（RFC 4180 合规：支持转义双引号 "" 和带引号字段）
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var index = line.startIndex

        while index < line.endIndex {
            let char = line[index]
            if inQuotes {
                if char == "\"" {
                    let next = line.index(after: index)
                    if next < line.endIndex, line[next] == "\"" {
                        // RFC 4180: "" 转义为单个 "
                        current.append("\"")
                        index = line.index(after: next)
                        continue
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(char)
                }
            } else {
                if char == "\"" {
                    inQuotes = true
                } else if char == "," {
                    fields.append(current)
                    current = ""
                } else {
                    current.append(char)
                }
            }
            index = line.index(after: index)
        }
        fields.append(current)
        return fields
    }

    // MARK: - Private Helpers

    /// 逐个 Profile 恢复数据库和图片
    private func restoreAllProfiles(from fileURL: URL, payload: BackupPayload, autoBackupURL: URL?) async throws {
        let originalActiveProfileId = profileManager.activeProfileId
        for profileData in payload.profiles {
            // 查找或创建对应 Profile
            let targetProfile: Profile
            if let existing = profileManager.profiles.first(where: { $0.name == profileData.profileName }) {
                targetProfile = existing
            } else if let created = profileManager.createProfile(name: profileData.profileName) {
                targetProfile = created
            } else {
                SnapDrillLogger.data.error("SettingsViewModel: 恢复备份时 Profile 创建失败，跳过: \(profileData.profileName)")
                continue
            }

            // 切换到目标 Profile
            if targetProfile.id != profileManager.activeProfileId {
                try profileManager.switchProfile(to: targetProfile.id)
            }

            // 原始活跃 Profile 用 self.repositories（与 createBackup 对称）
            let targetRepos = (targetProfile.id == originalActiveProfileId)
                ? repositories : profileManager.activeRepositories
            try await targetRepos.restoreFromProfileData(profileData)

            // 恢复图片
            let profileDir = Self.profileDirectory(for: targetProfile.id)
            do {
                try await backupService.restoreImages(
                    from: fileURL,
                    profileId: profileData.profileId,
                    to: profileDir
                ) { [weak self] current, total in
                    Task { @MainActor in
                        guard let self else { return }
                        self.backupProgress = total > 0 ? Double(current) / Double(total) : 1.0
                    }
                }
            } catch {
                SnapDrillLogger.generic.error("图片恢复失败（Profile: \(profileData.profileName)），开始回滚: \(error)")
                if let autoBackupURL {
                    await rollbackFromAutoBackup(autoBackupURL)
                } else {
                    backupError = L10n.Errors.restoreFailed
                    backupStatusMessage = ""
                }
                throw error
            }
        }
    }

    /// 从自动备份回滚到恢复前状态（图片恢复失败时调用）
    /// 自动备份仅包含活跃 Profile 数据
    private func rollbackFromAutoBackup(_ fileURL: URL) async {
        backupStatusMessage = L10n.Settings.restoreAutoBackup
        do {
            let payload = try await backupService.extractPayload(from: fileURL)
            guard let profileData = payload.profiles.first else { return }
            try await repositories.restoreFromProfileData(profileData)
            try await backupService.restoreImages(
                from: fileURL,
                profileId: profileData.profileId,
                to: Self.activeProfileDirectory()
            ) { _, _ in }
            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
            backupStatusMessage = L10n.Settings.restorePartialImageFailure
            SnapDrillLogger.generic.info("已回滚到恢复前状态")
            cleanupAutoBackup(fileURL)
        } catch {
            // 回滚也失败 → 保留自动备份供用户手动恢复
            SnapDrillLogger.generic.error("回滚失败，自动备份保留在: \(fileURL.path)")
            backupError = L10n.Errors.restoreFailed
            backupStatusMessage = ""
        }
    }

    /// 恢复前自动备份当前数据到临时目录（best-effort，不中断恢复流程）
    ///
    /// - Returns: 自动备份文件 URL（恢复成功后应清理），备份失败或无数据时返回 nil
    private func createAutoBackupBeforeRestore() async -> URL? {
        do {
            // 仅备份活跃 Profile（自动备份是安全网，不需要全 Profile）
            let activeProfile = profileManager.activeProfile
            let profileData = try repositories.collectProfileBackupData(
                profileName: activeProfile?.name ?? "default",
                profileId: profileManager.activeProfileId
            )
            guard !profileData.reviewItems.isEmpty else { return nil }

            let payload = BackupPayload(profiles: [profileData])
            let manifest = BackupManifest(
                schemaVersion: BackupManifest.currentSchemaVersion,
                createdAt: Date(),
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                totalItemCount: profileData.reviewItems.count,
                profileCount: 1,
                profileNames: [profileData.profileName]
            )
            let url = try await backupService.createBackup(
                payload: payload,
                manifest: manifest,
                profileDirectories: [Self.activeProfileDirectory()]
            )
            SnapDrillLogger.generic.info("恢复前自动备份已保存: \(url.lastPathComponent)")
            return url
        } catch {
            // 自动备份失败不中断恢复流程，仅记录日志
            SnapDrillLogger.generic.warning("恢复前自动备份失败（不影响恢复操作）: \(error)")
            return nil
        }
    }

    private func cleanupAutoBackup(_ url: URL?) {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url) // best-effort: 临时备份清理
    }
}
