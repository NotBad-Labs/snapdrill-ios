//
//  SettingsBackupCoordinator.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import SnapDrillCore
import SnapDrillData

/// Single-library backup and restore orchestration without UI state.
@MainActor
struct SettingsBackupCoordinator {
    let repositories: RepositoryContainer
    let backupService: BackupService

    var onProgress: @MainActor (Double) -> Void = { _ in }
    var onStatus: @MainActor (String) -> Void = { _ in }

    func createBackup() async throws -> URL {
        onStatus(L10n.Settings.backupPreparingData)
        let payload = try repositories.collectBackupData()
        let itemCount = payload.reviewItems.count
        let manifest = makeManifest(itemCount: itemCount)
        let reportProgress = onProgress

        onStatus(L10n.Settings.backupPackingItems(itemCount))
        let url = try await backupService.createBackup(
            payload: payload,
            manifest: manifest,
            libraryDirectory: repositories.libraryDirectory
        ) { current, total in
            Task { @MainActor in
                reportProgress(total > 0 ? Double(current) / Double(total) : 1.0)
            }
        }

        onStatus(L10n.Settings.backupComplete)
        SnapDrillLogger.generic.info("备份完成: \(itemCount) 条资料")
        return url
    }

    func restoreFromBackup(fileURL: URL) async throws {
        let manifest = try await backupService.readManifest(from: fileURL)
        guard manifest.schemaVersion == BackupManifest.currentSchemaVersion else {
            throw BackupError.unsupportedSchemaVersion(
                fileVersion: manifest.schemaVersion,
                appVersion: BackupManifest.currentSchemaVersion
            )
        }

        onStatus(L10n.Settings.restoreReadingData)
        let payload = try await backupService.extractPayload(from: fileURL)
        let referencedImagePaths = imagePaths(in: payload)
        try await backupService.validateImages(
            in: fileURL,
            expectedPaths: referencedImagePaths
        )

        onStatus(L10n.Settings.restoreAutoBackup)
        let autoBackupURL = try await createAutoBackupBeforeRestore()

        do {
            onStatus(L10n.Settings.restoreRestoringItems(manifest.totalItemCount))
            try await applyRestore(
                payload: payload,
                referencedImagePaths: referencedImagePaths,
                imagesFrom: fileURL,
                reportsProgress: true,
                requiresCompleteImages: true
            )
        } catch {
            await rollbackRestore(from: autoBackupURL)
            throw error
        }

        cleanupAutoBackup(autoBackupURL)
        SnapDrillLogger.generic.info("恢复完成: \(manifest.totalItemCount) 条资料")
    }

    private func makeManifest(itemCount: Int) -> BackupManifest {
        BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            totalItemCount: itemCount
        )
    }

    private func createAutoBackupBeforeRestore() async throws -> URL {
        let payload = try repositories.collectBackupData()
        let temporaryURL = try await backupService.createBackup(
            payload: payload,
            manifest: makeManifest(itemCount: payload.reviewItems.count),
            libraryDirectory: repositories.libraryDirectory,
            allowsMissingImages: true
        )
        let recoveryDirectory = repositories.libraryDirectory
            .appendingPathComponent("Recovery", isDirectory: true)
        let recoveryURL = recoveryDirectory
            .appendingPathComponent("pre_restore_\(UUID().uuidString).zip")
        do {
            try FileManager.default.createDirectory(
                at: recoveryDirectory,
                withIntermediateDirectories: true
            )
            try FileManager.default.moveItem(at: temporaryURL, to: recoveryURL)
        } catch {
            try? FileManager.default.removeItem(at: temporaryURL)
            throw error
        }
        SnapDrillLogger.generic.info("恢复前自动备份已保存: \(recoveryURL.lastPathComponent)")
        return recoveryURL
    }

    private func rollbackRestore(from autoBackupURL: URL) async {
        do {
            let payload = try await backupService.extractPayload(from: autoBackupURL)
            try await applyRestore(
                payload: payload,
                referencedImagePaths: imagePaths(in: payload),
                imagesFrom: autoBackupURL,
                reportsProgress: false,
                requiresCompleteImages: false
            )
            cleanupAutoBackup(autoBackupURL)
            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
            SnapDrillLogger.generic.info("恢复失败后已回滚到操作前状态")
        } catch {
            SnapDrillLogger.generic.error("恢复回滚失败，自动备份保留在 \(autoBackupURL.path): \(error)")
        }
    }

    private func applyRestore(
        payload: BackupPayload,
        referencedImagePaths: Set<String>,
        imagesFrom backupURL: URL,
        reportsProgress: Bool,
        requiresCompleteImages: Bool
    ) async throws {
        let previousImagePaths = try await repositories.restore(from: payload)
        let reportProgress = onProgress
        try await backupService.restoreImages(
            from: backupURL,
            to: repositories.libraryDirectory,
            expectedPaths: requiresCompleteImages ? referencedImagePaths : nil
        ) { current, total in
            guard reportsProgress else { return }
            Task { @MainActor in
                reportProgress(total > 0 ? Double(current) / Double(total) : 1.0)
            }
        }
        await repositories.deleteImages(paths: previousImagePaths.subtracting(referencedImagePaths))
    }

    private func imagePaths(in payload: BackupPayload) -> Set<String> {
        Set(
            payload.reviewItems
                .flatMap { [$0.imagePath, $0.answerImagePath].compactMap { $0 } }
                .filter(ImageStorage.isSafeRelativeImagePath)
        )
    }

    private func cleanupAutoBackup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
