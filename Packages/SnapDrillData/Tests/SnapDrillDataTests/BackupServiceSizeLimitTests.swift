//
//  BackupServiceSizeLimitTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Testing
import Foundation
import UIKit
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

    @Test("restoreImages 总量上限使用实际提取字节而非 ZIP header 声明值")
    func restoreImages_countsActualBytesWhenUncompressedSizeUnderreports() async throws {
        let service = BackupService(restoreSizeLimits: .init(maxSingleEntryBytes: 16, maxTotalEntryBytes: 20))
        let profileId = UUID()
        let firstPath = "profiles/\(profileId.uuidString)/images/one.jpg"
        let secondPath = "profiles/\(profileId.uuidString)/images/two.jpg"
        let restoreDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RestoreZipBombHeaderTest_\(UUID().uuidString)", isDirectory: true)
        defer { cleanup(restoreDir) }

        let archiveURL = try makeArchive(entries: [
            ZIPEntry(path: firstPath, data: Data(repeating: 0x63, count: 12)),
            ZIPEntry(path: secondPath, data: Data(repeating: 0x64, count: 12))
        ])
        defer { cleanup(archiveURL) }
        try rewriteDeclaredUncompressedSize(of: firstPath, in: archiveURL, to: 0)
        try rewriteDeclaredUncompressedSize(of: secondPath, in: archiveURL, to: 0)

        do {
            try await service.restoreImages(from: archiveURL, profileId: profileId, to: restoreDir)
            Issue.record("restoreImages should count actual extracted bytes, not ZIP header declarations")
        } catch BackupError.archiveEntryTooLarge(let path, let limitBytes) {
            #expect(path == secondPath)
            #expect(limitBytes == 20)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(!FileManager.default.fileExists(atPath: restoreDir.appendingPathComponent("images/one.jpg").path))
        #expect(!FileManager.default.fileExists(atPath: restoreDir.appendingPathComponent("images/two.jpg").path))
    }

    @Test("extractPayload 图片预检总量使用实际提取字节而非 ZIP header 声明值")
    func extractPayload_countsActualImageBytesWhenHeaderUnderreports() async throws {
        let profileId = UUID()
        let firstPath = "profiles/\(profileId.uuidString)/images/one.jpg"
        let secondPath = "profiles/\(profileId.uuidString)/images/two.jpg"
        let imageData = try makeTestJPEGData()
        let totalLimit = Int64(imageData.count * 2 - 1)
        let service = BackupService(
            restoreSizeLimits: .init(maxSingleEntryBytes: 10_000, maxTotalEntryBytes: totalLimit)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let archiveURL = try makeArchive(entries: [
            ZIPEntry(path: "data.json", data: try encoder.encode(makePayload(profileId: profileId))),
            ZIPEntry(path: firstPath, data: imageData),
            ZIPEntry(path: secondPath, data: imageData)
        ])
        defer { cleanup(archiveURL) }
        try rewriteDeclaredUncompressedSize(of: firstPath, in: archiveURL, to: 0)
        try rewriteDeclaredUncompressedSize(of: secondPath, in: archiveURL, to: 0)

        do {
            _ = try await service.extractPayload(from: archiveURL)
            Issue.record("extractPayload should count actual image bytes, not ZIP header declarations")
        } catch BackupError.archiveEntryTooLarge(let path, let limitBytes) {
            #expect(path == secondPath)
            #expect(limitBytes == totalLimit)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("createBackup 拒绝 reader 会因图片总量上限拒绝的 payload")
    func createBackup_rejectsImageTotalReaderWouldReject() async throws {
        let profileId = UUID()
        let imageData = try makeTestJPEGData()
        let totalLimit = Int64(imageData.count * 2 - 1)
        let service = BackupService(
            restoreSizeLimits: .init(maxSingleEntryBytes: 10_000, maxTotalEntryBytes: totalLimit)
        )
        let profileDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BackupWriterLimitTests_\(UUID().uuidString)", isDirectory: true)
        let imagesDirectory = profileDirectory.appendingPathComponent("images", isDirectory: true)
        try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        try imageData.write(to: imagesDirectory.appendingPathComponent("one.jpg"))
        try imageData.write(to: imagesDirectory.appendingPathComponent("two.jpg"))
        defer { cleanup(profileDirectory) }

        let manifest = BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            appVersion: "1.0",
            totalItemCount: 2,
            profileCount: 1,
            profileNames: ["Default"]
        )

        do {
            _ = try await service.createBackup(
                payload: makePayload(profileId: profileId),
                manifest: manifest,
                profileDirectories: [profileDirectory]
            )
            Issue.record("createBackup should not emit an archive its reader rejects")
        } catch BackupError.archiveEntryTooLarge(let path, let limitBytes) {
            #expect(path.hasPrefix("profiles/\(profileId.uuidString)/images/"))
            #expect(limitBytes == totalLimit)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("createBackup 拒绝超过 reader 单 entry 上限的图片")
    func createBackup_rejectsImageSingleEntryReaderWouldReject() async throws {
        let profileId = UUID()
        let imageData = try makeTestJPEGData()
        let singleLimit = Int64(imageData.count - 1)
        let service = BackupService(
            restoreSizeLimits: .init(maxSingleEntryBytes: singleLimit, maxTotalEntryBytes: 10_000)
        )
        let profileDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BackupWriterSingleLimitTests_\(UUID().uuidString)", isDirectory: true)
        let imageURL = profileDirectory.appendingPathComponent("images/one.jpg")
        try FileManager.default.createDirectory(
            at: imageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try imageData.write(to: imageURL)
        defer { cleanup(profileDirectory) }

        let manifest = BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            appVersion: "1.0",
            totalItemCount: 1,
            profileCount: 1,
            profileNames: ["Default"]
        )

        do {
            _ = try await service.createBackup(
                payload: makePayload(profileId: profileId, imagePaths: ["images/one.jpg"]),
                manifest: manifest,
                profileDirectories: [profileDirectory]
            )
            Issue.record("createBackup should enforce the reader's per-entry image limit")
        } catch BackupError.archiveEntryTooLarge(let path, let limitBytes) {
            #expect(path == "profiles/\(profileId.uuidString)/images/one.jpg")
            #expect(limitBytes == singleLimit)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    private func makePayload(
        profileId: UUID,
        imagePaths: [String] = ["images/one.jpg", "images/two.jpg"]
    ) -> BackupPayload {
        let now = Date(timeIntervalSinceReferenceDate: 0)
        let items = imagePaths.map { path in
            ArchiveItemBackupDTO(
                id: UUID(),
                content: "Item",
                imagePath: path,
                createdAt: now,
                lastReviewedAt: now,
                nextReviewAt: now,
                answerText: nil,
                answerImagePath: nil,
                easeFactor: 2.5,
                interval: 0,
                repetitions: 0,
                categoryValueIds: []
            )
        }
        return BackupPayload(profiles: [
            ProfileBackupData(
                profileName: "Default",
                profileId: profileId,
                reviewItems: items,
                dimensions: [],
                categoryValues: []
            )
        ])
    }

    private func makeTestJPEGData() throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
        return try #require(image.jpegData(compressionQuality: 0.8))
    }

    private func makeArchive(entries: [ZIPEntry]) throws -> URL {
        let archiveURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BackupServiceSizeLimitTests_\(UUID().uuidString).zip")
        try ZIPArchiver().createArchive(entries: entries, at: archiveURL)
        return archiveURL
    }

    private func rewriteDeclaredUncompressedSize(of path: String, in archiveURL: URL, to size: UInt32) throws {
        var archiveData = try Data(contentsOf: archiveURL)
        let pathData = Data(path.utf8)
        var rewriteCount = 0

        for offset in 0 ..< archiveData.count {
            if matchesSignature(0x04034b50, at: offset, in: archiveData),
               matchesPath(pathData, at: offset + 30, in: archiveData) {
                writeUInt32LE(size, at: offset + 22, in: &archiveData)
                rewriteCount += 1
            }
            if matchesSignature(0x02014b50, at: offset, in: archiveData),
               matchesPath(pathData, at: offset + 46, in: archiveData) {
                writeUInt32LE(size, at: offset + 24, in: &archiveData)
                rewriteCount += 1
            }
        }

        #expect(rewriteCount >= 2)
        try archiveData.write(to: archiveURL)
    }

    private func matchesPath(_ pathData: Data, at offset: Int, in archiveData: Data) -> Bool {
        let end = offset + pathData.count
        guard offset >= 0, end <= archiveData.count else { return false }
        return archiveData[offset ..< end].elementsEqual(pathData)
    }

    private func matchesSignature(_ signature: UInt32, at offset: Int, in archiveData: Data) -> Bool {
        guard offset >= 0, offset + 4 <= archiveData.count else { return false }
        return readUInt32LE(at: offset, in: archiveData) == signature
    }

    private func readUInt32LE(at offset: Int, in data: Data) -> UInt32 {
        UInt32(data[offset])
            | UInt32(data[offset + 1]) << 8
            | UInt32(data[offset + 2]) << 16
            | UInt32(data[offset + 3]) << 24
    }

    private func writeUInt32LE(_ value: UInt32, at offset: Int, in data: inout Data) {
        let bytes = Data([
            UInt8(value & 0xff),
            UInt8((value >> 8) & 0xff),
            UInt8((value >> 16) & 0xff),
            UInt8((value >> 24) & 0xff)
        ])
        data.replaceSubrange(offset ..< offset + 4, with: bytes)
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
