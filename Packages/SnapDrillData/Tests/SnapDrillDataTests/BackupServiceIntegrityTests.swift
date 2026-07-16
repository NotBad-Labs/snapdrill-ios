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
        let service = BackupService()
        let profileDir = try makeProfileDirectory()
        let existingBackups = try temporaryBackupArchiveNames()
        defer {
            try? FileManager.default.removeItem(at: profileDir)
            removeTemporaryBackups(excluding: existingBackups)
        }

        await #expect(throws: BackupError.self) {
            _ = try await service.createBackup(
                payload: makePayload(imagePath: "images/missing.jpg"),
                manifest: makeManifest(),
                profileDirectories: [profileDir]
            )
        }

        #expect(try temporaryBackupArchiveNames() == existingBackups)
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

    private func temporaryBackupArchiveNames() throws -> Set<String> {
        let urls = try FileManager.default.contentsOfDirectory(
            at: FileManager.default.temporaryDirectory,
            includingPropertiesForKeys: nil
        )
        return Set(urls.lazy.map(\.lastPathComponent).filter {
            $0.hasPrefix("SnapDrill_Backup_") && $0.hasSuffix(".zip")
        })
    }

    private func removeTemporaryBackups(excluding preservedNames: Set<String>) {
        guard let names = try? temporaryBackupArchiveNames() else { return }
        for name in names.subtracting(preservedNames) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
            try? FileManager.default.removeItem(at: url)
        }
    }
}
