//
//  BackupServiceConcurrentExportTests.swift
//  SnapDrillData
//
//  Verifies that independently created backup files cannot overwrite each other.
//

import Testing
import Foundation
@testable import SnapDrillData

@Suite("BackupService concurrent export", .serialized)
struct BackupServiceConcurrentExportTests {
    @Test("back-to-back exports use distinct temporary URLs")
    func backToBackExportsUseDistinctURLs() async throws {
        let backupDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BackupConcurrentExportTests_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        defer { cleanup(backupDirectory) }
        let service = BackupService(
            restoreSizeLimits: .production,
            backupDirectory: backupDirectory
        )
        let payload = BackupPayload(profiles: [])
        let manifest = BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            appVersion: "1.0",
            totalItemCount: 0,
            profileCount: 0,
            profileNames: []
        )

        async let firstURL = service.createBackup(
            payload: payload,
            manifest: manifest,
            profileDirectories: []
        )
        async let secondURL = service.createBackup(
            payload: payload,
            manifest: manifest,
            profileDirectories: []
        )
        let urls = try await [firstURL, secondURL]

        #expect(Set(urls).count == 2)
        #expect(urls.allSatisfy { FileManager.default.fileExists(atPath: $0.path) })
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
