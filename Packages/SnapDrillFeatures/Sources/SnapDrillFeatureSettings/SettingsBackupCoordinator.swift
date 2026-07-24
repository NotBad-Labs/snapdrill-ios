//
//  SettingsBackupCoordinator.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  备份 / 恢复事务编排器：从 SettingsViewModel 抽出，承载 backup / restore 的全部
//  业务逻辑（收集数据、打包 ZIP、逐 Profile 恢复、恢复前自动备份安全网、回滚）。
//  进度与状态通过 onProgress / onStatus 闭包回写 ViewModel 的 @Observable 属性，
//  使编排逻辑与 UI 状态解耦、可独立于 @Observable 环境演进。
//  activityTracker、安全域访问、isBackupInProgress 由调用方 ViewModel 在薄包装中处理。
//

import Foundation
import SnapDrillCore
import SnapDrillData

/// 备份 / 恢复事务编排器（无 UI 状态）
///
/// 必须 `@MainActor`：内部触碰 `RepositoryContainer`（SwiftData mainContext）与
/// `ProfileManager`。错误一律 rethrow 由调用方 ViewModel 在 catch 中统一设置 backupError。
@MainActor
struct SettingsBackupCoordinator {
    let repositories: RepositoryContainer
    let profileManager: ProfileManager
    let backupService: BackupService
    private let vault: ProfileVault

    init(
        repositories: RepositoryContainer,
        profileManager: ProfileManager,
        backupService: BackupService,
        vault: ProfileVault = ProfileVault()
    ) {
        self.repositories = repositories
        self.profileManager = profileManager
        self.backupService = backupService
        self.vault = vault
    }

    /// 进度回写（0.0 ~ 1.0），@MainActor 闭包隐式 Sendable，可安全传入跨 actor 进度回调
    var onProgress: @MainActor (Double) -> Void = { _ in }
    /// 状态消息回写
    var onStatus: @MainActor (String) -> Void = { _ in }

    /// Profile 恢复期间的错误
    enum RestoreProfileError: LocalizedError {
        case profileCreationFailed(profileName: String, profileId: UUID, underlying: Error)
        case activeProfileRestoreFailed(profileId: UUID, underlying: Error)

        var errorDescription: String? {
            switch self {
            case .profileCreationFailed(let profileName, let profileId, let underlying):
                return "Profile restore target creation failed: \(profileName) (\(profileId.uuidString)): \(underlying.localizedDescription)"
            case .activeProfileRestoreFailed(let profileId, let underlying):
                return "Failed to restore active Profile \(profileId.uuidString): \(underlying.localizedDescription)"
            }
        }
    }

    // MARK: - Backup

    /// 创建全量备份文件，返回 .zip 文件 URL。失败时 rethrow。
    func createBackup() async throws -> URL {
        onStatus(L10n.Settings.backupPreparingData)

        // 1. 收集所有 Profile 数据
        let (payload, totalItemCount) = try await collectAllProfileBackupData()
        let manifest = makeManifest(payload: payload, totalItemCount: totalItemCount)

        onStatus(L10n.Settings.backupPackingItems(totalItemCount))

        // 2. 在 BackupService actor 上打包 ZIP（传所有 Profile 目录）
        // 提取局部闭包，避免跨 actor 进度回调捕获非 Sendable 的 struct self
        let reportProgress = onProgress
        let url = try await backupService.createBackup(
            payload: payload,
            manifest: manifest,
            profileDirectories: payload.profiles.map { vault.profileDirectory(for: $0.profileId) }
        ) { current, total in
            Task { @MainActor in
                reportProgress(total > 0 ? Double(current) / Double(total) : 1.0)
            }
        }

        onStatus(L10n.Settings.backupComplete)
        SnapDrillLogger.generic.info("备份完成: \(totalItemCount) 条资料，\(payload.profiles.count) 个 Profile")
        return url
    }

    /// 收集所有 Profile 的备份数据（活跃用当前 repositories，非活跃临时建 executor）。
    /// 供全量备份与「恢复前全 Profile 安全网」复用。
    private func collectAllProfileBackupData() async throws -> (payload: BackupPayload, totalItemCount: Int) {
        var profileDataList: [ProfileBackupData] = []
        var totalItemCount = 0
        for profile in profileManager.profiles {
            let data: ProfileBackupData
            if profile.id == profileManager.activeProfileId {
                data = try repositories.collectProfileBackupData(profileName: profile.name, profileId: profile.id)
            } else {
                // 非活跃 Profile 临时创建 DataExecutor，避免回落到旧同步容器路径。
                let profileDirectory = vault.profileDirectory(for: profile.id)
                let tempExecutor = await DataExecutor.createOffMainActor(storeURL: vault.storeURL(for: profile.id))
                let tempRepos = RepositoryContainer(
                    executor: tempExecutor,
                    imageStorage: ImageStorage(baseDirectory: profileDirectory)
                )
                data = try tempRepos.collectProfileBackupData(profileName: profile.name, profileId: profile.id)
            }
            profileDataList.append(data)
            totalItemCount += data.reviewItems.count
        }
        return (BackupPayload(profiles: profileDataList), totalItemCount)
    }

    private func makeManifest(payload: BackupPayload, totalItemCount: Int) -> BackupManifest {
        BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            totalItemCount: totalItemCount,
            profileCount: payload.profiles.count,
            profileNames: payload.profiles.map(\.profileName)
        )
    }

    // MARK: - Restore

    /// 从备份文件恢复数据。安全域访问由调用方处理；失败时 rethrow。
    func restoreFromBackup(fileURL: URL) async throws {
        // 1. 读取并验证 manifest
        let manifest = try await backupService.readManifest(from: fileURL)
        if manifest.schemaVersion > BackupManifest.currentSchemaVersion {
            throw BackupError.schemaVersionTooNew(
                fileVersion: manifest.schemaVersion,
                appVersion: BackupManifest.currentSchemaVersion
            )
        }

        onStatus(L10n.Settings.restoreAutoBackup)

        // 2. 恢复前自动备份当前数据（安全网）
        let autoBackupURL = try await createAutoBackupBeforeRestore()

        onStatus(L10n.Settings.restoreReadingData)

        // 3. 提取 payload
        let payload = try await backupService.extractPayload(from: fileURL)

        onStatus(L10n.Settings.restoreRestoringItems(manifest.totalItemCount))

        let preRestoreActiveProfileId = profileManager.activeProfileId

        // 4. 逐个 Profile 恢复数据库和图片
        try await restoreAllProfiles(
            from: fileURL,
            payload: payload,
            autoBackupURL: autoBackupURL,
            preRestoreActiveProfileId: preRestoreActiveProfileId
        )
        try await restoreActiveProfileIfNeeded(preRestoreActiveProfileId)

        // 5. 恢复完全成功 → 清理自动备份
        cleanupAutoBackup(autoBackupURL)

        SnapDrillLogger.generic.info("恢复完成: \(manifest.totalItemCount) 条资料，\(manifest.profileCount) 个 Profile")
    }

    // MARK: - Private Helpers

    /// 逐个 Profile 恢复数据库和图片
    private func restoreAllProfiles(
        from fileURL: URL,
        payload: BackupPayload,
        autoBackupURL: URL?,
        preRestoreActiveProfileId: UUID
    ) async throws {
        let reportProgress = onProgress
        // #4 事务化：整个多 Profile 还原视为一个事务。任一步（DB 或图片）失败 → 回滚
        // （丢弃本次新 ingest 的 Profile 消除孤儿壳 + 从自动备份还原活跃 Profile），再 rethrow。
        var ingestedProfileIds: [UUID] = []
        do {
            for profileData in payload.profiles {
                let (targetProfile, ingested) = try findOrCreateRestoreTargetProfile(for: profileData)
                if ingested { ingestedProfileIds.append(targetProfile.id) }
                let targetRepos = await restoreRepositories(
                    for: targetProfile,
                    preRestoreActiveProfileId: preRestoreActiveProfileId
                )
                try await targetRepos.restoreFromProfileData(profileData)

                // 恢复图片
                let profileDir = vault.profileDirectory(for: targetProfile.id)
                try await backupService.restoreImages(
                    from: fileURL,
                    profileId: profileData.profileId,
                    to: profileDir
                ) { current, total in
                    Task { @MainActor in
                        reportProgress(total > 0 ? Double(current) / Double(total) : 1.0)
                    }
                }
            }
        } catch {
            SnapDrillLogger.generic.error("还原失败，开始事务回滚（含 \(ingestedProfileIds.count) 个已 ingest 的 Profile）: \(error)")
            await rollbackRestore(autoBackupURL: autoBackupURL, ingestedProfileIds: ingestedProfileIds)
            // 回滚后必 rethrow，backupError 由调用方 ViewModel 在 catch 中统一设置
            throw error
        }
    }

    /// 找到或创建还原目标 Profile。`ingested` 标记本次是否新建（用于事务回滚）。
    /// 经 `ProfileManager.ingestProfile` 原子更新内存 + 磁盘，杜绝旧 RestoreProfileHelper
    /// 直写 profiles.json 造成的内存↔磁盘 desync（数据丢失修复）。
    private func findOrCreateRestoreTargetProfile(
        for profileData: ProfileBackupData
    ) throws -> (profile: Profile, ingested: Bool) {
        if let existing = profileManager.profiles.first(where: { $0.id == profileData.profileId }) {
            return (existing, false)
        }

        do {
            let profile = try profileManager.ingestProfile(
                id: profileData.profileId,
                name: profileData.profileName
            )
            return (profile, true)
        } catch {
            SnapDrillLogger.data.error(
                "SettingsBackupCoordinator: 恢复备份时 Profile 创建失败: \(profileData.profileName), id: \(profileData.profileId.uuidString), error: \(error)"
            )
            throw RestoreProfileError.profileCreationFailed(
                profileName: profileData.profileName,
                profileId: profileData.profileId,
                underlying: error
            )
        }
    }

    private func restoreRepositories(
        for profile: Profile,
        preRestoreActiveProfileId: UUID
    ) async -> RepositoryContainer {
        if profile.id == preRestoreActiveProfileId {
            return repositories
        }

        let profileDir = vault.profileDirectory(for: profile.id)
        let storeURL = vault.storeURL(for: profile.id)
        let executor = await DataExecutor.createOffMainActor(storeURL: storeURL)
        return RepositoryContainer(
            executor: executor,
            imageStorage: ImageStorage(baseDirectory: profileDir)
        )
    }

    private func restoreActiveProfileIfNeeded(_ preRestoreActiveProfileId: UUID) async throws {
        guard profileManager.activeProfileId != preRestoreActiveProfileId else { return }
        do {
            try await profileManager.switchProfile(to: preRestoreActiveProfileId)
        } catch {
            throw RestoreProfileError.activeProfileRestoreFailed(
                profileId: preRestoreActiveProfileId,
                underlying: error
            )
        }
    }

    /// 还原失败时的事务回滚（#4 全 Profile 安全网）：
    /// 1. 从恢复前「全 Profile 自动备份」还原**所有**被覆盖的 Profile（活跃 + 非活跃）；
    /// 2. 丢弃本次还原新 ingest 的 Profile（消除孤儿壳）。
    /// 回滚后调用方会 rethrow 原错误，backupError 由 ViewModel catch 统一设置。
    private func rollbackRestore(autoBackupURL: URL?, ingestedProfileIds: [UUID]) async {
        if let autoBackupURL {
            await restoreAllProfilesFromAutoBackup(autoBackupURL)
        }
        for id in ingestedProfileIds {
            profileManager.discardProfile(id: id)
        }
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
    }

    /// 从全 Profile 自动备份逐个还原所有 Profile（best-effort：单个失败记日志继续、不 throw）。
    /// 仅当全部成功才清理自动备份；任一失败则保留供用户手动恢复。
    private func restoreAllProfilesFromAutoBackup(_ fileURL: URL) async {
        onStatus(L10n.Settings.restoreAutoBackup)
        let payload: BackupPayload
        do {
            payload = try await backupService.extractPayload(from: fileURL)
        } catch {
            SnapDrillLogger.generic.error("回滚失败（无法读取自动备份），保留在: \(fileURL.path)")
            return
        }

        var allSucceeded = true
        for profileData in payload.profiles {
            do {
                let repos = await rollbackRepositories(for: profileData)
                try await repos.restoreFromProfileData(profileData)
                try await backupService.restoreImages(
                    from: fileURL,
                    profileId: profileData.profileId,
                    to: vault.profileDirectory(for: profileData.profileId)
                ) { _, _ in }
            } catch {
                allSucceeded = false
                SnapDrillLogger.generic.error("回滚单 Profile 失败（\(profileData.profileName)）: \(error)")
            }
        }

        onStatus(L10n.Settings.restorePartialImageFailure)
        if allSucceeded {
            SnapDrillLogger.generic.info("已回滚所有 Profile 到恢复前状态")
            cleanupAutoBackup(fileURL)
        } else {
            SnapDrillLogger.generic.error("部分 Profile 回滚失败，自动备份保留在: \(fileURL.path)")
        }
    }

    /// 回滚时为某 Profile 取 repositories：活跃用当前，非活跃临时建 executor。
    private func rollbackRepositories(for profileData: ProfileBackupData) async -> RepositoryContainer {
        if profileData.profileId == profileManager.activeProfileId {
            return repositories
        }
        let executor = await DataExecutor.createOffMainActor(storeURL: vault.storeURL(for: profileData.profileId))
        return RepositoryContainer(
            executor: executor,
            imageStorage: ImageStorage(baseDirectory: vault.profileDirectory(for: profileData.profileId))
        )
    }

    /// 恢复前自动备份当前数据到临时目录。任何不完整或写入失败都在 mutation 前中止恢复。
    ///
    /// - Returns: 自动备份文件 URL（恢复成功后应清理）；仅当前资料库完全为空时返回 nil
    private func createAutoBackupBeforeRestore() async throws -> URL? {
        do {
            // 全 Profile 安全网：备份所有 Profile（非仅活跃），使多 Profile 还原中途失败时
            // 可回滚被覆盖的非活跃 Profile，彻底闭环 #4。
            let (payload, totalItemCount) = try await collectAllProfileBackupData()
            guard Self.hasRestorableContent(payload) else { return nil }

            let manifest = makeManifest(payload: payload, totalItemCount: totalItemCount)
            let url = try await backupService.createBackup(
                payload: payload,
                manifest: manifest,
                profileDirectories: payload.profiles.map { vault.profileDirectory(for: $0.profileId) }
            )
            SnapDrillLogger.generic.info("恢复前自动备份已保存（\(payload.profiles.count) 个 Profile）: \(url.lastPathComponent)")
            return url
        } catch {
            SnapDrillLogger.generic.error("恢复前安全快照失败，恢复已在 mutation 前中止: \(error)")
            throw error
        }
    }

    private static func hasRestorableContent(_ payload: BackupPayload) -> Bool {
        payload.profiles.contains {
            !$0.reviewItems.isEmpty || !$0.dimensions.isEmpty || !$0.categoryValues.isEmpty
        }
    }

    private func cleanupAutoBackup(_ url: URL?) {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url) // best-effort: 临时备份清理
    }
}
