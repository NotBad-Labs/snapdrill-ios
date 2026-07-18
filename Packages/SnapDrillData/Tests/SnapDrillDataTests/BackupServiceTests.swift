//
//  BackupServiceTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  BackupService 创建/读取/恢复 round-trip 及异常路径测试。
//

import Testing
import Foundation
import UIKit
@testable import SnapDrillData

@Suite("BackupService 单元测试", .serialized)
struct BackupServiceTests {

    // MARK: - Helpers

    private static let testProfileId = UUID()

    private static let sampleDimensionId = UUID()
    private static let sampleValueId = UUID()

    private func makeSamplePayload(
        imagePath: String? = "images/test.jpg",
        answerImagePath: String? = nil,
        profileId: UUID = Self.testProfileId
    ) -> BackupPayload {
        let profileData = ProfileBackupData(
            profileName: "默认",
            profileId: profileId,
            reviewItems: [
                ArchiveItemBackupDTO(
                    id: UUID(),
                    content: "测试题目",
                    imagePath: imagePath,
                    createdAt: Date(),
                    lastReviewedAt: .distantPast,
                    nextReviewAt: .distantPast,
                    answerText: "答案",
                    answerImagePath: answerImagePath,
                    easeFactor: 2.5,
                    interval: 0,
                    repetitions: 0,
                    categoryValueIds: [Self.sampleValueId]
                )
            ],
            dimensions: [
                CategoryDimensionBackupDTO(
                    id: Self.sampleDimensionId, name: "分类", isMultiValue: false, isBuiltIn: true,
                    systemKey: CategorySystemKey.category, sortOrder: 0, icon: "book"
                )
            ],
            categoryValues: [
                CategoryValueBackupDTO(
                    id: Self.sampleValueId, name: "数学", icon: "function", colorHex: "#FF0000",
                    sortOrder: 0, createdAt: Date(), dimensionId: Self.sampleDimensionId
                )
            ]
        )
        return BackupPayload(profiles: [profileData])
    }

    private func makeSampleManifest(totalItemCount: Int = 1) -> BackupManifest {
        BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(),
            appVersion: "1.1.0",
            totalItemCount: totalItemCount,
            profileCount: 1,
            profileNames: ["默认"]
        )
    }

    private func createTempProfileDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BackupServiceTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let imageFile = dir.appendingPathComponent("images/test.jpg")
        try FileManager.default.createDirectory(
            at: imageFile.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try makeTestJPEGData().write(to: imageFile)
        return dir
    }

    private func makeTestJPEGData() throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
        return try #require(image.jpegData(compressionQuality: 0.8))
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private func makeArchive(entries: [ZIPEntry]) throws -> URL {
        let archiveURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BackupServiceTests_\(UUID().uuidString).zip")
        try ZIPArchiver().createArchive(entries: entries, at: archiveURL)
        return archiveURL
    }

    private func writeString(_ value: String, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(value.utf8).write(to: url)
    }

    private func stringContents(of url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - Round-trip

    @Test("创建备份 → 读取清单 → 提取数据 round-trip")
    func createReadExtractRoundTrip() async throws {
        let service = BackupService()
        let payload = makeSamplePayload()
        let manifest = makeSampleManifest()
        let profileDir = try createTempProfileDir()
        defer { cleanup(profileDir) }

        let backupURL = try await service.createBackup(
            payload: payload,
            manifest: manifest,
            profileDirectories: [profileDir]
        )
        defer { cleanup(backupURL) }

        #expect(FileManager.default.fileExists(atPath: backupURL.path))

        let readManifest = try await service.readManifest(from: backupURL)
        #expect(readManifest.schemaVersion == manifest.schemaVersion)
        #expect(readManifest.appVersion == manifest.appVersion)
        #expect(readManifest.totalItemCount == manifest.totalItemCount)
        #expect(readManifest.profileCount == manifest.profileCount)

        let extractedPayload = try await service.extractPayload(from: backupURL)
        #expect(extractedPayload.profiles.count == 1)
        let profile = extractedPayload.profiles[0]
        #expect(profile.reviewItems.count == 1)
        #expect(profile.reviewItems[0].content == "测试题目")
        #expect(profile.reviewItems[0].categoryValueIds == [Self.sampleValueId])
        #expect(profile.dimensions.count == 1)
        #expect(profile.categoryValues.count == 1)
    }

    @Test("图片恢复 round-trip")
    func imageRestoreRoundTrip() async throws {
        let service = BackupService()
        let payload = makeSamplePayload()
        let manifest = makeSampleManifest()
        let profileDir = try createTempProfileDir()
        defer { cleanup(profileDir) }

        let backupURL = try await service.createBackup(
            payload: payload,
            manifest: manifest,
            profileDirectories: [profileDir]
        )
        defer { cleanup(backupURL) }

        let restoreDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RestoreTest_\(UUID().uuidString)")
        defer { cleanup(restoreDir) }

        try await service.restoreImages(
            from: backupURL,
            profileId: Self.testProfileId,
            to: restoreDir
        )

        let restoredImagePath = restoreDir.appendingPathComponent("images/test.jpg")
        #expect(FileManager.default.fileExists(atPath: restoredImagePath.path))
        let restoredData = try Data(contentsOf: restoredImagePath)
        try BackupImagePathValidator.validateJPEGData(restoredData)
    }

    @Test("restoreImages 暂存失败时保留旧图片，成功时替换为新图片")
    func restoreImages_preservesOriginalsWhenStagingFails_thenSwapsOnSuccess() async throws {
        let service = BackupService()
        let profileId = UUID()
        let restoreDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RestoreAtomicityTest_\(UUID().uuidString)", isDirectory: true)
        defer { cleanup(restoreDir) }

        let originalImage = restoreDir.appendingPathComponent("images/conflict.jpg")
        try writeString("old-image-data", to: originalImage)
        let validImageData = try makeTestJPEGData()

        let failingArchive = try makeArchive(entries: [
            ZIPEntry(
                path: "profiles/\(profileId.uuidString)/images/conflict.jpg",
                data: validImageData
            ),
            ZIPEntry(
                path: "profiles/\(profileId.uuidString)/images/nested/child.jpg",
                data: Data("not-a-jpeg".utf8)
            )
        ])
        defer { cleanup(failingArchive) }

        var didThrow = false
        do {
            try await service.restoreImages(from: failingArchive, profileId: profileId, to: restoreDir)
        } catch {
            didThrow = true
        }

        #expect(didThrow)
        #expect(try stringContents(of: originalImage) == "old-image-data")
        #expect(!FileManager.default.fileExists(
            atPath: restoreDir.appendingPathComponent("images/nested/child.jpg").path
        ))

        let successfulArchive = try makeArchive(entries: [
            ZIPEntry(
                path: "profiles/\(profileId.uuidString)/images/conflict.jpg",
                data: validImageData
            ),
            ZIPEntry(
                path: "profiles/\(profileId.uuidString)/images/new.jpg",
                data: validImageData
            )
        ])
        defer { cleanup(successfulArchive) }

        try await service.restoreImages(from: successfulArchive, profileId: profileId, to: restoreDir)

        #expect(try Data(contentsOf: originalImage) == validImageData)
        #expect(try Data(contentsOf: restoreDir.appendingPathComponent("images/new.jpg")) == validImageData)
    }

    @Test("进度回调正确触发")
    func progressCallbackFires() async throws {
        let service = BackupService()
        let payload = makeSamplePayload()
        let manifest = makeSampleManifest()
        let profileDir = try createTempProfileDir()
        defer { cleanup(profileDir) }

        let counter = CallCounter()
        let backupURL = try await service.createBackup(
            payload: payload,
            manifest: manifest,
            profileDirectories: [profileDir],
            onProgress: { _, _ in
                Task { await counter.increment() }
            }
        )
        defer { cleanup(backupURL) }

        try await Task.sleep(for: .milliseconds(50))
        let count = await counter.value
        #expect(count > 0)
    }

    // MARK: - 异常路径

    @Test("读取损坏归档抛出 invalidArchive")
    func corruptArchiveThrowsError() async throws {
        let service = BackupService()
        let corruptFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("corrupt_\(UUID().uuidString).zip")
        try Data("not-a-zip-file".utf8).write(to: corruptFile)
        defer { cleanup(corruptFile) }

        await #expect(throws: BackupError.self) {
            _ = try await service.readManifest(from: corruptFile)
        }
    }

    @Test("空 payload（零题目）round-trip")
    func emptyPayloadRoundTrip() async throws {
        let service = BackupService()
        let emptyProfile = ProfileBackupData(
            profileName: "空",
            profileId: UUID(),
            reviewItems: [],
            dimensions: [],
            categoryValues: []
        )
        let payload = BackupPayload(profiles: [emptyProfile])
        let manifest = makeSampleManifest(totalItemCount: 0)
        let emptyDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("EmptyTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)
        defer { cleanup(emptyDir) }

        let backupURL = try await service.createBackup(
            payload: payload,
            manifest: manifest,
            profileDirectories: [emptyDir]
        )
        defer { cleanup(backupURL) }

        let extracted = try await service.extractPayload(from: backupURL)
        #expect(extracted.profiles[0].reviewItems.isEmpty)
        #expect(extracted.profiles[0].dimensions.isEmpty)
    }

    // MARK: - 图片路径边界

    @Test("createBackup 在建档前拒绝可读的 Profile 外图片路径")
    func createBackup_rejectsReadableOutOfScopeImage() async throws {
        let service = BackupService()
        let profileId = UUID()
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("BackupEscapeTest_\(UUID().uuidString)", isDirectory: true)
        let profileDir = root.appendingPathComponent("profile", isDirectory: true)
        let outsideURL = root.appendingPathComponent("private.jpg")
        try FileManager.default.createDirectory(at: profileDir, withIntermediateDirectories: true)
        try Data("private".utf8).write(to: outsideURL)
        defer { cleanup(root) }

        await #expect(throws: BackupError.self) {
            _ = try await service.createBackup(
                payload: makeSamplePayload(imagePath: "../private.jpg", profileId: profileId),
                manifest: makeSampleManifest(),
                profileDirectories: [profileDir]
            )
        }
        #expect(try Data(contentsOf: outsideURL) == Data("private".utf8))
    }

    @Test("extractPayload 在数据库 mutation 前拒绝非法图片 entry")
    func extractPayload_rejectsInvalidImageEntryPath() async throws {
        let service = BackupService()
        let payload = makeSamplePayload()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let archiveURL = try makeArchive(entries: [
            ZIPEntry(path: "data.json", data: try encoder.encode(payload)),
            ZIPEntry(
                path: "profiles/\(Self.testProfileId.uuidString)/images/../escape.jpg",
                data: Data("private".utf8)
            )
        ])
        defer { cleanup(archiveURL) }

        await #expect(throws: BackupError.self) {
            _ = try await service.extractPayload(from: archiveURL)
        }
    }

    @Test("extractPayload 保持忽略 Profile 下未知非图片 entry 的 v2 行为")
    func extractPayload_ignoresUnknownNonImageEntry() async throws {
        let service = BackupService()
        let payload = makeSamplePayload(imagePath: nil)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let archiveURL = try makeArchive(entries: [
            ZIPEntry(path: "data.json", data: try encoder.encode(payload)),
            ZIPEntry(
                path: "profiles/\(Self.testProfileId.uuidString)/future/metadata.bin",
                data: Data("future".utf8)
            )
        ])
        defer { cleanup(archiveURL) }

        let extracted = try await service.extractPayload(from: archiveURL)

        #expect(extracted.profiles.first?.profileId == Self.testProfileId)
    }

    @Test("restoreImages 对任一非法 entry 整体失败且不修改旧图片")
    func restoreImages_rejectsInvalidEntryWithoutPartialMutation() async throws {
        let service = BackupService()
        let profileId = UUID()
        let restoreDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RestoreTraversalPayloadTest_\(UUID().uuidString)", isDirectory: true)
        defer { cleanup(restoreDir) }

        let originalImage = restoreDir.appendingPathComponent("images/keep.jpg")
        try writeString("original-image-data", to: originalImage)

        let maliciousArchive = try makeArchive(entries: [
            ZIPEntry(
                path: "profiles/\(profileId.uuidString)/images/new.jpg",
                data: Data("new-image-data".utf8)
            ),
            ZIPEntry(
                path: "profiles/\(profileId.uuidString)/images/../keep.jpg",
                data: Data("corrupted-image-data".utf8)
            )
        ])
        defer { cleanup(maliciousArchive) }

        await #expect(throws: BackupError.self) {
            try await service.restoreImages(from: maliciousArchive, profileId: profileId, to: restoreDir)
        }
        #expect(try stringContents(of: originalImage) == "original-image-data")
        #expect(!FileManager.default.fileExists(
            atPath: restoreDir.appendingPathComponent("images/new.jpg").path
        ))

        let restoredImageData = try makeTestJPEGData()
        let validArchive = try makeArchive(entries: [
            ZIPEntry(
                path: "profiles/\(profileId.uuidString)/images/keep.jpg",
                data: restoredImageData
            ),
            ZIPEntry(
                path: "profiles/\(profileId.uuidString)/images/custom-name.jpg",
                data: restoredImageData
            )
        ])
        defer { cleanup(validArchive) }

        try await service.restoreImages(from: validArchive, profileId: profileId, to: restoreDir)

        #expect(try Data(contentsOf: originalImage) == restoredImageData)
        #expect(try Data(contentsOf: restoreDir.appendingPathComponent("images/custom-name.jpg")) == restoredImageData)
    }

    @Test("restoreImages 在 staging 前拒绝重复图片 entry 且不修改旧图片")
    func restoreImages_rejectsDuplicateEntriesWithoutMutation() async throws {
        let service = BackupService()
        let profileId = UUID()
        let restoreDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RestoreDuplicateEntryTest_\(UUID().uuidString)", isDirectory: true)
        defer { cleanup(restoreDir) }

        let originalImage = restoreDir.appendingPathComponent("images/keep.jpg")
        try writeString("original-image-data", to: originalImage)
        let duplicatePath = "profiles/\(profileId.uuidString)/images/keep.jpg"
        let archiveURL = try makeArchive(entries: [
            ZIPEntry(path: duplicatePath, data: Data("first".utf8)),
            ZIPEntry(path: duplicatePath, data: Data("second".utf8))
        ])
        defer { cleanup(archiveURL) }

        await #expect(throws: BackupError.self) {
            try await service.restoreImages(from: archiveURL, profileId: profileId, to: restoreDir)
        }
        #expect(try stringContents(of: originalImage) == "original-image-data")
    }

    @Test("restoreImages 拒绝符号链接 images 目录")
    func restoreImages_rejectsSymlinkedImagesDirectory() async throws {
        let service = BackupService()
        let fileManager = FileManager.default
        let profileId = UUID()
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("RestoreSymlinkTest_\(UUID().uuidString)", isDirectory: true)
        let restoreDir = root.appendingPathComponent("profile", isDirectory: true)
        let siblingDir = root.appendingPathComponent("sibling", isDirectory: true)
        try fileManager.createDirectory(at: restoreDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: siblingDir, withIntermediateDirectories: true)
        try fileManager.createSymbolicLink(
            at: restoreDir.appendingPathComponent("images"),
            withDestinationURL: siblingDir
        )
        defer { cleanup(root) }

        let archiveURL = try makeArchive(entries: [
            ZIPEntry(
                path: "profiles/\(profileId.uuidString)/images/victim.jpg",
                data: Data("archive".utf8)
            )
        ])
        defer { cleanup(archiveURL) }

        await #expect(throws: BackupError.self) {
            try await service.restoreImages(from: archiveURL, profileId: profileId, to: restoreDir)
        }
        #expect(!fileManager.fileExists(atPath: siblingDir.appendingPathComponent("victim.jpg").path))
    }
}

/// 线程安全计数器
private actor CallCounter {
    private(set) var value = 0
    func increment() { value += 1 }
}
