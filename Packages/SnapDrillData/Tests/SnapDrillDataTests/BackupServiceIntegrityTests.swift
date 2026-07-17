//
//  BackupServiceIntegrityTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Testing
import Foundation
@testable import SnapDrillData

extension BackupServiceTests {

    @Test("createBackup 遇到缺失引用图片时失败且删除 partial ZIP")
    func missingReferencedImageFailsWithoutPartialArchive() async throws {
        let backupDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BackupIntegrityArchives_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        let service = BackupService(
            restoreSizeLimits: .production,
            backupDirectory: backupDirectory
        )
        let profileDir = try makeProfileDirectory()
        defer {
            try? FileManager.default.removeItem(at: profileDir)
            try? FileManager.default.removeItem(at: backupDirectory)
        }

        await #expect(throws: BackupError.self) {
            _ = try await service.createBackup(
                payload: makePayload(imagePath: "images/missing.jpg"),
                manifest: makeManifest(),
                profileDirectories: [profileDir]
            )
        }

        let remainingFiles = try FileManager.default.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: nil
        )
        #expect(remainingFiles.isEmpty)
    }

    private func makeProfileDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BackupIntegrityTests_\(UUID().uuidString)", isDirectory: true)
        let imageURL = directory.appendingPathComponent("images/present.jpg")
        try FileManager.default.createDirectory(
            at: imageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("present-image".utf8).write(to: imageURL)
        return directory
    }

    private func makePayload(imagePath: String) -> BackupPayload {
        BackupPayload(profiles: [
            ProfileBackupData(
                profileName: "Test",
                profileId: UUID(),
                reviewItems: [
                    ArchiveItemBackupDTO(
                        id: UUID(),
                        content: "资料",
                        imagePath: imagePath,
                        createdAt: Date(timeIntervalSinceReferenceDate: 0),
                        lastReviewedAt: .distantPast,
                        nextReviewAt: .distantPast,
                        answerText: nil,
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
        ])
    }

    private func makeManifest() -> BackupManifest {
        BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            appVersion: "test",
            totalItemCount: 1,
            profileCount: 1,
            profileNames: ["Test"]
        )
    }

}
