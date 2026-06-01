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
                // 非活跃 Profile 临时创建 DataExecutor，避免回落到旧同步容器路径。
                let tempExecutor = await DataExecutor.createOffMainActor(storeURL: storeURL)
                let scope = ProfileScope(id: profile.id, name: profile.name)
                let tempRepos = RepositoryContainer(executor: tempExecutor, scope: scope, profileDirectory: profileDir)
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

        onStatus(L10n.Settings.backupPackingItems(totalItemCount))

        // 2. 在 BackupService actor 上打包 ZIP（传所有 Profile 目录）
        // 提取局部闭包，避免跨 actor 进度回调捕获非 Sendable 的 struct self
        let reportProgress = onProgress
        let url = try await backupService.createBackup(
            payload: payload,
            manifest: manifest,
            profileDirectories: profileDataList.map { Self.profileDirectory(for: $0.profileId) }
        ) { current, total in
            Task { @MainActor in
                reportProgress(total > 0 ? Double(current) / Double(total) : 1.0)
            }
        }

        onStatus(L10n.Settings.backupComplete)
        SnapDrillLogger.generic.info("备份完成: \(totalItemCount) 道题目，\(profileDataList.count) 个 Profile")
        return url
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
        let autoBackupURL = await createAutoBackupBeforeRestore()

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

        SnapDrillLogger.generic.info("恢复完成: \(manifest.totalItemCount) 道题目，\(manifest.profileCount) 个 Profile")
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
        for profileData in payload.profiles {
            let targetProfile = try findOrCreateRestoreTargetProfile(for: profileData)
            let targetRepos = await restoreRepositories(
                for: targetProfile,
                preRestoreActiveProfileId: preRestoreActiveProfileId
            )
            try await targetRepos.restoreFromProfileData(profileData)

            // 恢复图片
            let profileDir = Self.profileDirectory(for: targetProfile.id)
            do {
                try await backupService.restoreImages(
                    from: fileURL,
                    profileId: profileData.profileId,
                    to: profileDir
                ) { current, total in
                    Task { @MainActor in
                        reportProgress(total > 0 ? Double(current) / Double(total) : 1.0)
                    }
                }
            } catch {
                SnapDrillLogger.generic.error("图片恢复失败（Profile: \(profileData.profileName)），开始回滚: \(error)")
                // 回滚后必 rethrow，backupError 由调用方 ViewModel 在 catch 中统一设置
                if let autoBackupURL {
                    await rollbackFromAutoBackup(autoBackupURL)
                }
                throw error
            }
        }
    }

    private func findOrCreateRestoreTargetProfile(for profileData: ProfileBackupData) throws -> Profile {
        if let existing = profileManager.profiles.first(where: { $0.id == profileData.profileId }) {
            return existing
        }

        do {
            return try RestoreProfileHelper.createRestoreTargetProfile(
                id: profileData.profileId,
                name: profileData.profileName,
                fallbackProfiles: profileManager.profiles
            )
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

        let profileDir = Self.profileDirectory(for: profile.id)
        let storeURL = profileDir.appendingPathComponent("default.store")
        let executor = await DataExecutor.createOffMainActor(storeURL: storeURL)
        let scope = ProfileScope(id: profile.id, name: profile.name)
        return RepositoryContainer(executor: executor, scope: scope, profileDirectory: profileDir)
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

    /// 从自动备份回滚到恢复前状态（图片恢复失败时调用）
    /// 自动备份仅包含活跃 Profile 数据。回滚后调用方会 rethrow 原错误，
    /// 故此处仅更新中间状态消息 / 记日志，backupError 由 ViewModel catch 统一设置。
    private func rollbackFromAutoBackup(_ fileURL: URL) async {
        onStatus(L10n.Settings.restoreAutoBackup)
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
            onStatus(L10n.Settings.restorePartialImageFailure)
            SnapDrillLogger.generic.info("已回滚到恢复前状态")
            cleanupAutoBackup(fileURL)
        } catch {
            // 回滚也失败 → 保留自动备份供用户手动恢复
            SnapDrillLogger.generic.error("回滚失败，自动备份保留在: \(fileURL.path)")
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

    // MARK: - Profile Directory Helpers

    /// 获取当前活跃 Profile 的目录路径
    static func activeProfileDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if let profileId = UserDefaults.standard.string(forKey: UDKey.activeProfileId) {
            return docs.appendingPathComponent("profiles").appendingPathComponent(profileId)
        }
        return docs
    }

    /// 获取指定 Profile 的目录路径
    static func profileDirectory(for profileId: UUID) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("profiles").appendingPathComponent(profileId.uuidString)
    }
}
