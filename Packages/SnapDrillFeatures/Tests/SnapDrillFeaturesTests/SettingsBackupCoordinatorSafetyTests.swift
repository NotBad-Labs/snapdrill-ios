//
//  SettingsBackupCoordinatorSafetyTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Testing
import Foundation
import UIKit
@testable import SnapDrillFeatureSettings
@testable import SnapDrillData
@testable import SnapDrillCore

extension SettingsViewModelTests {

    @Test("恢复前安全快照缺图时在任何 mutation 前失败")
    func incompleteSafetySnapshotLeavesLibraryUntouched() async throws {
        let context = try makeContext()
        defer { context.cleanup() }
        let activeProfile = context.activeProfile
        let repositories = context.manager.activeRepositories

        let dimension = CategoryDimensionModel(
            name: "原分类", isMultiValue: false, isBuiltIn: false,
            systemKey: nil, sortOrder: 100, icon: "folder"
        )
        try repositories.dimension.insertAndSave(dimension)
        let value = CategoryValueModel(name: "原值", dimension: dimension)
        try repositories.categoryValue.insertAndSave(value)

        let originalItem = ArchiveItemModel(
            content: "恢复前资料",
            imagePath: "images/sentinel.jpg",
            answerText: "恢复前答案",
            answerImagePath: "images/missing.jpg"
        )
        originalItem.categoryValues = [value]
        repositories.archive.insert(originalItem)
        try repositories.archive.saveContext()

        let sentinelURL = context.vault.imagesDirectory(for: activeProfile.id)
            .appendingPathComponent("sentinel.jpg")
        let sentinelBytes = Data("sentinel-image-bytes".utf8)
        try sentinelBytes.write(to: sentinelURL)

        let replacement = makeProfileData(
            profileId: activeProfile.id,
            profileName: activeProfile.name
        )
        let restoreInput = try await makeRestoreInput(
            profileData: replacement,
            vault: context.vault,
            documentsURL: context.documentsURL
        )

        let viewModel = SettingsViewModel(
            repositories: repositories,
            profileManager: context.manager,
            profileVault: context.vault
        )
        let notificationFlag = NotificationFlag()
        let observer = NotificationCenter.default.addObserver(
            forName: .reviewDataDidChange,
            object: viewModel,
            queue: .main
        ) { _ in
            Task { await notificationFlag.markReceived() }
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        await viewModel.restoreFromBackup(fileURL: restoreInput)

        let storedItems = try repositories.archive.fetchAllModels()
        let storedItem = try #require(storedItems.first(where: { $0.id == originalItem.id }))
        let notificationReceived = await notificationFlag.wasReceived
        #expect(viewModel.backupError == L10n.Errors.restoreFailed)
        #expect(notificationReceived == false)
        #expect(storedItems.count == 1)
        #expect(storedItem.content == "恢复前资料")
        #expect(storedItem.answerText == "恢复前答案")
        #expect(storedItem.imagePath == "images/sentinel.jpg")
        #expect(storedItem.answerImagePath == "images/missing.jpg")
        #expect(storedItem.categoryValues?.map(\.id) == [value.id])
        #expect(try Data(contentsOf: sentinelURL) == sentinelBytes)
    }

    @Test("外部备份缺失引用图片时在数据库 mutation 前失败")
    func malformedExternalBackupLeavesLibraryUntouched() async throws {
        let context = try makeContext()
        defer { context.cleanup() }
        let repositories = context.manager.activeRepositories

        let dimension = CategoryDimensionModel(
            name: "保留分类", isMultiValue: false, isBuiltIn: false,
            systemKey: nil, sortOrder: 100, icon: "folder"
        )
        try repositories.dimension.insertAndSave(dimension)
        let value = CategoryValueModel(name: "保留值", dimension: dimension)
        try repositories.categoryValue.insertAndSave(value)
        let originalItem = ArchiveItemModel(content: "必须保留", answerText: "原答案")
        originalItem.categoryValues = [value]
        repositories.archive.insert(originalItem)
        try repositories.archive.saveContext()

        let replacement = makeProfileData(
            profileId: context.activeProfile.id,
            profileName: context.activeProfile.name,
            imagePath: "images/test.jpg"
        )
        let restoreInput = try makeMalformedRestoreInput(
            profileData: replacement,
            documentsURL: context.documentsURL
        )
        let coordinator = SettingsBackupCoordinator(
            repositories: repositories,
            profileManager: context.manager,
            backupService: BackupService(),
            vault: context.vault
        )

        await #expect(throws: BackupError.self) {
            try await coordinator.restoreFromBackup(fileURL: restoreInput)
        }

        let storedItems = try repositories.archive.fetchAllModels()
        let storedItem = try #require(storedItems.first(where: { $0.id == originalItem.id }))
        #expect(storedItems.count == 1)
        #expect(storedItem.content == "必须保留")
        #expect(storedItem.answerText == "原答案")
        #expect(storedItem.categoryValues?.map(\.id) == [value.id])
        #expect(try repositories.dimension.fetchAllModels().map(\.id) == [dimension.id])
        #expect(repositories.categoryValue.fetchAllModels(in: dimension).map(\.id) == [value.id])
    }

    @Test("taxonomy-only 资料库在后续图片恢复失败时完整回滚")
    func taxonomyOnlyLibraryRollsBackAfterImageFailure() async throws {
        let context = try makeContext()
        defer { context.cleanup() }
        let activeProfile = context.activeProfile
        let repositories = context.manager.activeRepositories

        let originalDimension = CategoryDimensionModel(
            name: "仅分类数据", isMultiValue: false, isBuiltIn: false,
            systemKey: nil, sortOrder: 100, icon: "folder"
        )
        try repositories.dimension.insertAndSave(originalDimension)
        let originalValue = CategoryValueModel(name: "必须保留", dimension: originalDimension)
        try repositories.categoryValue.insertAndSave(originalValue)

        let sourceDirectory = context.documentsURL
            .appendingPathComponent("external-backup-source", isDirectory: true)
        let sourceImage = sourceDirectory.appendingPathComponent("images/test.jpg")
        try FileManager.default.createDirectory(
            at: sourceImage.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try makeTestJPEGData().write(to: sourceImage)
        let replacement = makeProfileData(
            profileId: activeProfile.id,
            profileName: activeProfile.name,
            imagePath: "images/test.jpg"
        )
        let restoreInput = try await makeRestoreInput(
            profileData: replacement,
            vault: context.vault,
            documentsURL: context.documentsURL,
            sourceDirectory: sourceDirectory
        )

        let targetImages = context.vault.imagesDirectory(for: activeProfile.id)
        try FileManager.default.removeItem(at: targetImages)
        let symlinkTarget = context.documentsURL.appendingPathComponent("unsafe-images", isDirectory: true)
        try FileManager.default.createDirectory(at: symlinkTarget, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: targetImages, withDestinationURL: symlinkTarget)

        let coordinator = SettingsBackupCoordinator(
            repositories: repositories,
            profileManager: context.manager,
            backupService: BackupService(),
            vault: context.vault
        )
        await #expect(throws: BackupError.self) {
            try await coordinator.restoreFromBackup(fileURL: restoreInput)
        }

        #expect(try repositories.archive.totalCount() == 0)
        #expect(try repositories.dimension.fetchAllModels().contains { $0.id == originalDimension.id })
        #expect(repositories.categoryValue.fetchAllModels(in: originalDimension).contains {
            $0.id == originalValue.id
        })
    }

    private func makeContext() throws -> TestContext {
        let documentsURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("RestoreSafetyTests_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        let vault = ProfileVault(documentsURL: documentsURL)
        let manager = ProfileManager(inMemory: true, vault: vault)
        let activeProfile = try #require(manager.activeProfile)
        try FileManager.default.createDirectory(
            at: vault.imagesDirectory(for: activeProfile.id),
            withIntermediateDirectories: true
        )
        return TestContext(
            vault: vault,
            documentsURL: documentsURL,
            manager: manager,
            activeProfile: activeProfile
        )
    }

    private func makeRestoreInput(
        profileData: ProfileBackupData,
        vault: ProfileVault,
        documentsURL: URL,
        sourceDirectory: URL? = nil
    ) async throws -> URL {
        let payload = BackupPayload(profiles: [profileData])
        let manifest = BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            appVersion: "test",
            totalItemCount: profileData.reviewItems.count,
            profileCount: 1,
            profileNames: [profileData.profileName]
        )
        let generated = try await BackupService().createBackup(
            payload: payload,
            manifest: manifest,
            profileDirectories: [sourceDirectory ?? vault.profileDirectory(for: profileData.profileId)]
        )
        defer { try? FileManager.default.removeItem(at: generated) }

        let input = documentsURL.appendingPathComponent("restore-input-\(UUID().uuidString).zip")
        try FileManager.default.copyItem(at: generated, to: input)
        return input
    }

    private func makeMalformedRestoreInput(
        profileData: ProfileBackupData,
        documentsURL: URL
    ) throws -> URL {
        let manifest = BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            appVersion: "test",
            totalItemCount: profileData.reviewItems.count,
            profileCount: 1,
            profileNames: [profileData.profileName]
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let input = documentsURL.appendingPathComponent("malformed-restore-\(UUID().uuidString).zip")
        try ZIPArchiver().createArchive(
            entries: [
                ZIPEntry(path: "manifest.json", data: try encoder.encode(manifest)),
                ZIPEntry(
                    path: "data.json",
                    data: try encoder.encode(BackupPayload(profiles: [profileData]))
                )
            ],
            at: input
        )
        return input
    }

    private func makeTestJPEGData() throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
        return try #require(image.jpegData(compressionQuality: 0.8))
    }

    private func makeProfileData(
        profileId: UUID,
        profileName: String,
        imagePath: String? = nil
    ) -> ProfileBackupData {
        let now = Date(timeIntervalSinceReferenceDate: 0)
        return ProfileBackupData(
            profileName: profileName,
            profileId: profileId,
            reviewItems: [
                ArchiveItemBackupDTO(
                    id: UUID(),
                    content: "替换资料",
                    imagePath: imagePath,
                    createdAt: now,
                    lastReviewedAt: now,
                    nextReviewAt: now,
                    answerText: "替换答案",
                    answerImagePath: nil,
                    easeFactor: 2.5,
                    interval: 0,
                    repetitions: 0,
                    categoryValueIds: []
                )
            ],
            dimensions: [],
            categoryValues: []
        )
    }
}

@MainActor
private struct TestContext {
    let vault: ProfileVault
    let documentsURL: URL
    let manager: ProfileManager
    let activeProfile: Profile

    func cleanup() {
        try? FileManager.default.removeItem(at: documentsURL)
    }
}

private actor NotificationFlag {
    private(set) var wasReceived = false

    func markReceived() {
        wasReceived = true
    }
}
