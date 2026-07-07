//
//  BackupServiceSizeLimitTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Testing
import Foundation
@testable import SnapDrillData

@Suite("BackupService 解压体积上限测试", .serialized)
struct BackupServiceSizeLimitTests {

    @Test("readManifest 拒绝超过单 entry 上限的 manifest.json")
    func readManifest_rejectsOversizedManifestEntry() async throws {
        let service = BackupService(restoreSizeLimits: .init(maxSingleEntryBytes: 8, maxTotalEntryBytes: 32))
        let archiveURL = try makeArchive(entries: [
            ZIPEntry(path: "manifest.json", data: Data(repeating: 0x61, count: 9))
        ])
        defer { cleanup(archiveURL) }

        do {
            _ = try await service.readManifest(from: archiveURL)
            Issue.record("readManifest should reject oversized manifest.json before decoding")
        } catch BackupError.archiveEntryTooLarge(let path, let limitBytes) {
            #expect(path == "manifest.json")
            #expect(limitBytes == 8)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("extractPayload 拒绝超过单 entry 上限的 data.json")
    func extractPayload_rejectsOversizedDataEntry() async throws {
        let service = BackupService(restoreSizeLimits: .init(maxSingleEntryBytes: 8, maxTotalEntryBytes: 32))
        let archiveURL = try makeArchive(entries: [
            ZIPEntry(path: "data.json", data: Data(repeating: 0x62, count: 9))
        ])
        defer { cleanup(archiveURL) }

        do {
            _ = try await service.extractPayload(from: archiveURL)
            Issue.record("extractPayload should reject oversized data.json before decoding")
        } catch BackupError.archiveEntryTooLarge(let path, let limitBytes) {
            #expect(path == "data.json")
            #expect(limitBytes == 8)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("restoreImages 拒绝超过总解压上限的图片 entries 且不提交部分文件")
    func restoreImages_rejectsTotalUncompressedImageLimit() async throws {
        let service = BackupService(restoreSizeLimits: .init(maxSingleEntryBytes: 16, maxTotalEntryBytes: 20))
        let profileId = UUID()
        let restoreDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RestoreZipBombLimitTest_\(UUID().uuidString)", isDirectory: true)
        defer { cleanup(restoreDir) }

        let archiveURL = try makeArchive(entries: [
            ZIPEntry(
                path: "profiles/\(profileId.uuidString)/images/one.jpg",
                data: Data(repeating: 0x63, count: 12)
            ),
            ZIPEntry(
                path: "profiles/\(profileId.uuidString)/images/two.jpg",
                data: Data(repeating: 0x64, count: 12)
            )
        ])
        defer { cleanup(archiveURL) }

        do {
            try await service.restoreImages(from: archiveURL, profileId: profileId, to: restoreDir)
            Issue.record("restoreImages should reject archives whose image entries exceed total limit")
        } catch BackupError.archiveEntryTooLarge(let path, let limitBytes) {
            #expect(path == "profiles/\(profileId.uuidString)/images/two.jpg")
            #expect(limitBytes == 20)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(!FileManager.default.fileExists(atPath: restoreDir.appendingPathComponent("images/one.jpg").path))
        #expect(!FileManager.default.fileExists(atPath: restoreDir.appendingPathComponent("images/two.jpg").path))
    }

    private func makeArchive(entries: [ZIPEntry]) throws -> URL {
        let archiveURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BackupServiceSizeLimitTests_\(UUID().uuidString).zip")
        try ZIPArchiver().createArchive(entries: entries, at: archiveURL)
        return archiveURL
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
