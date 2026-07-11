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
@testable import SnapDrillData

@Suite("BackupService 单元测试", .serialized)
struct BackupServiceTests {

    // MARK: - Helpers

    private static let sampleDimensionId = UUID()
    private static let sampleValueId = UUID()

    private func makeSamplePayload() -> BackupPayload {
        BackupPayload(
            reviewItems: [
                ArchiveItemBackupDTO(
                    id: UUID(),
                    content: "测试题目",
                    imagePath: "images/test.jpg",
                    createdAt: Date(),
                    lastReviewedAt: .distantPast,
                    nextReviewAt: .distantPast,
                    answerText: "答案",
                    answerImagePath: nil,
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
    }

    private func makeSampleManifest(totalItemCount: Int = 1) -> BackupManifest {
        BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(),
            appVersion: "1.1.0",
            totalItemCount: totalItemCount
        )
    }

    private func createTempLibraryDirectory() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BackupServiceTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let imageFile = dir.appendingPathComponent("images/test.jpg")
        try FileManager.default.createDirectory(
            at: imageFile.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("fake-image-data".utf8).write(to: imageFile)
        return dir
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
        let libraryDirectory = try createTempLibraryDirectory()
        defer { cleanup(libraryDirectory) }

        let backupURL = try await service.createBackup(
            payload: payload,
            manifest: manifest,
            libraryDirectory: libraryDirectory
        )
        defer { cleanup(backupURL) }

        #expect(FileManager.default.fileExists(atPath: backupURL.path))

        let readManifest = try await service.readManifest(from: backupURL)
        #expect(readManifest.schemaVersion == manifest.schemaVersion)
        #expect(readManifest.appVersion == manifest.appVersion)
        #expect(readManifest.totalItemCount == manifest.totalItemCount)

        let extractedPayload = try await service.extractPayload(from: backupURL)
        #expect(extractedPayload.reviewItems.count == 1)
        #expect(extractedPayload.reviewItems[0].content == "测试题目")
        #expect(extractedPayload.reviewItems[0].categoryValueIds == [Self.sampleValueId])
        #expect(extractedPayload.dimensions.count == 1)
        #expect(extractedPayload.categoryValues.count == 1)
    }

    @Test("图片恢复 round-trip")
    func imageRestoreRoundTrip() async throws {
        let service = BackupService()
        let payload = makeSamplePayload()
        let manifest = makeSampleManifest()
        let libraryDirectory = try createTempLibraryDirectory()
        defer { cleanup(libraryDirectory) }

        let backupURL = try await service.createBackup(
            payload: payload,
            manifest: manifest,
            libraryDirectory: libraryDirectory
        )
        defer { cleanup(backupURL) }

        let restoreDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RestoreTest_\(UUID().uuidString)")
        defer { cleanup(restoreDir) }

        try await service.restoreImages(
            from: backupURL,
            to: restoreDir
        )

        let restoredImagePath = restoreDir.appendingPathComponent("images/test.jpg")
        #expect(FileManager.default.fileExists(atPath: restoredImagePath.path))
        let restoredData = try Data(contentsOf: restoredImagePath)
        #expect(String(data: restoredData, encoding: .utf8) == "fake-image-data")
    }

    @Test("同一秒创建的备份使用不同文件路径")
    func backupsCreatedInSameSecondHaveUniquePaths() async throws {
        let service = BackupService()
        let libraryDirectory = try createTempLibraryDirectory()
        defer { cleanup(libraryDirectory) }

        let first = try await service.createBackup(
            payload: makeSamplePayload(),
            manifest: makeSampleManifest(),
            libraryDirectory: libraryDirectory
        )
        defer { cleanup(first) }
        let second = try await service.createBackup(
            payload: makeSamplePayload(),
            manifest: makeSampleManifest(),
            libraryDirectory: libraryDirectory
        )
        defer { cleanup(second) }

        #expect(first != second)
        #expect(FileManager.default.fileExists(atPath: first.path))
        #expect(FileManager.default.fileExists(atPath: second.path))
    }

    @Test("restoreImages 暂存失败时保留旧图片，成功时替换为新图片")
    func restoreImages_preservesOriginalsWhenStagingFails_thenSwapsOnSuccess() async throws {
        let service = BackupService()
        let restoreDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RestoreAtomicityTest_\(UUID().uuidString)", isDirectory: true)
        defer { cleanup(restoreDir) }

        let originalImage = restoreDir.appendingPathComponent("images/conflict")
        try writeString("old-image-data", to: originalImage)

        let failingArchive = try makeArchive(entries: [
            ZIPEntry(
                path: "images/conflict",
                data: Data("new-image-data".utf8)
            ),
            ZIPEntry(
                path: "images/conflict/child.jpg",
                data: Data("child-image-data".utf8)
            )
        ])
        defer { cleanup(failingArchive) }

        var didThrow = false
        do {
            try await service.restoreImages(from: failingArchive, to: restoreDir)
        } catch {
            didThrow = true
        }

        #expect(didThrow)
        #expect(try stringContents(of: originalImage) == "old-image-data")
        #expect(!FileManager.default.fileExists(
            atPath: restoreDir.appendingPathComponent("images/conflict/child.jpg").path
        ))

        let successfulArchive = try makeArchive(entries: [
            ZIPEntry(
                path: "images/conflict",
                data: Data("replacement-image-data".utf8)
            ),
            ZIPEntry(
                path: "images/new.jpg",
                data: Data("brand-new-image-data".utf8)
            )
        ])
        defer { cleanup(successfulArchive) }

        try await service.restoreImages(from: successfulArchive, to: restoreDir)

        #expect(try stringContents(of: originalImage) == "replacement-image-data")
        #expect(try stringContents(
            of: restoreDir.appendingPathComponent("images/new.jpg")
        ) == "brand-new-image-data")
    }

    @Test("进度回调正确触发")
    func progressCallbackFires() async throws {
        let service = BackupService()
        let payload = makeSamplePayload()
        let manifest = makeSampleManifest()
        let libraryDirectory = try createTempLibraryDirectory()
        defer { cleanup(libraryDirectory) }

        let counter = CallCounter()
        let backupURL = try await service.createBackup(
            payload: payload,
            manifest: manifest,
            libraryDirectory: libraryDirectory,
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
        let payload = BackupPayload(
            reviewItems: [],
            dimensions: [],
            categoryValues: []
        )
        let manifest = makeSampleManifest(totalItemCount: 0)
        let emptyDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("EmptyTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)
        defer { cleanup(emptyDir) }

        let backupURL = try await service.createBackup(
            payload: payload,
            manifest: manifest,
            libraryDirectory: emptyDir
        )
        defer { cleanup(backupURL) }

        let extracted = try await service.extractPayload(from: backupURL)
        #expect(extracted.reviewItems.isEmpty)
        #expect(extracted.dimensions.isEmpty)
    }

    // MARK: - 路径遍历防御

    @Test("备份拒绝数据库中的非法图片路径")
    func backupRejectsPathTraversal() async throws {
        let service = BackupService()
        let payload = BackupPayload(
            reviewItems: [
                ArchiveItemBackupDTO(
                    id: UUID(),
                    content: "恶意条目",
                    imagePath: "images/../evil.jpg",
                    createdAt: Date(),
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
            dimensions: [], categoryValues: []
        )
        let manifest = makeSampleManifest()

        let sourceDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PathTraversalTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        defer { cleanup(sourceDir) }
        try Data("must-not-be-archived".utf8).write(
            to: sourceDir.appendingPathComponent("evil.jpg")
        )

        await #expect(throws: BackupError.self) {
            try await service.createBackup(
                payload: payload,
                manifest: manifest,
                libraryDirectory: sourceDir
            )
        }
    }

    @Test("恢复拒绝 payload 引用但 ZIP 缺失的图片")
    func restoreImagesRejectsMissingExpectedImage() async throws {
        let service = BackupService()
        let archiveURL = try makeArchive(entries: [])
        defer { cleanup(archiveURL) }
        let restoreDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RestoreMissingImage_\(UUID().uuidString)")
        defer { cleanup(restoreDir) }

        await #expect(throws: BackupError.self) {
            try await service.restoreImages(
                from: archiveURL,
                to: restoreDir,
                expectedPaths: ["images/missing.jpg"]
            )
        }
    }

    @Test("restoreImages 拒绝真实 ZIP 路径遍历条目并恢复合法条目")
    func restoreImages_rejectsActualPathTraversalPayloads_thenRestoresValidArchive() async throws {
        let service = BackupService()
        let restoreDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RestoreTraversalPayloadTest_\(UUID().uuidString)", isDirectory: true)
        defer { cleanup(restoreDir) }

        let originalImage = restoreDir.appendingPathComponent("images/keep.jpg")
        try writeString("original-image-data", to: originalImage)

        let outsideDir = restoreDir.deletingLastPathComponent()
        let outsideEvil = outsideDir.appendingPathComponent("evil-outside.jpg")
        let outsideNestedEvil = outsideDir.appendingPathComponent("evil-nested.jpg")
        try? FileManager.default.removeItem(at: outsideEvil)
        try? FileManager.default.removeItem(at: outsideNestedEvil)
        defer {
            cleanup(outsideEvil)
            cleanup(outsideNestedEvil)
        }

        let maliciousArchive = try makeArchive(entries: [
            ZIPEntry(
                path: "images/../../evil-outside.jpg",
                data: Data("evil-outside".utf8)
            ),
            ZIPEntry(
                path: "images/nested/../../../evil-nested.jpg",
                data: Data("evil-nested".utf8)
            ),
            ZIPEntry(
                path: "images/../keep.jpg",
                data: Data("corrupted-image-data".utf8)
            ),
            ZIPEntry(
                path: #"images/safe\evil.jpg"#,
                data: Data("backslash-path".utf8)
            )
        ])
        defer { cleanup(maliciousArchive) }

        try await service.restoreImages(from: maliciousArchive, to: restoreDir)

        #expect(!FileManager.default.fileExists(atPath: outsideEvil.path))
        #expect(!FileManager.default.fileExists(atPath: outsideNestedEvil.path))
        #expect(try stringContents(of: originalImage) == "original-image-data")
        #expect(!FileManager.default.fileExists(
            atPath: restoreDir.appendingPathComponent(#"images/safe\evil.jpg"#).path
        ))

        let validArchive = try makeArchive(entries: [
            ZIPEntry(
                path: "images/keep.jpg",
                data: Data("restored-image-data".utf8)
            ),
            ZIPEntry(
                path: "images/safe/new.jpg",
                data: Data("safe-new-image-data".utf8)
            )
        ])
        defer { cleanup(validArchive) }

        try await service.restoreImages(from: validArchive, to: restoreDir)

        #expect(try stringContents(of: originalImage) == "restored-image-data")
        #expect(try stringContents(
            of: restoreDir.appendingPathComponent("images/safe/new.jpg")
        ) == "safe-new-image-data")
    }
}

/// 线程安全计数器
private actor CallCounter {
    private(set) var value = 0
    func increment() { value += 1 }
}
