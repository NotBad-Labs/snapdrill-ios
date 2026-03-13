//
//  BackupServiceTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs on 2026/03/13.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  BackupService 创建/读取/恢复 round-trip 及异常路径测试。
//

import Testing
import Foundation
@testable import SnapDrillData

/// 线程安全计数器，用于 @Sendable 进度回调中累计调用次数。
private actor CallCounter {
    private(set) var value = 0
    func increment() { value += 1 }
}

@Suite("BackupService 单元测试", .serialized)
struct BackupServiceTests {

    // MARK: - Helpers

    private func makeSamplePayload() -> BackupPayload {
        BackupPayload(
            reviewItems: [
                ReviewItemBackupDTO(
                    id: UUID(),
                    content: "测试题目",
                    imagePath: "images/test.jpg",
                    createdAt: Date(),
                    lastReviewedAt: .distantPast,
                    nextReviewAt: .distantPast,
                    subject: "数学",
                    source: "作业",
                    tagNames: ["重点"],
                    answerText: "答案",
                    answerImagePath: nil,
                    difficulty: 3,
                    grade: "高一",
                    easeFactor: 2.5,
                    interval: 0,
                    repetitions: 0
                )
            ],
            subjects: [SubjectBackupDTO(id: UUID(), name: "数学", icon: "function", colorHex: "#FF0000", sortOrder: 0)],
            sources: [SourceBackupDTO(id: UUID(), name: "作业", icon: "doc.text", colorHex: "#0000FF", sortOrder: 0)],
            grades: [GradeBackupDTO(id: UUID(), name: "高一", sortOrder: 0)],
            tags: [TagBackupDTO(id: UUID(), name: "重点", colorHex: "#00FF00")]
        )
    }

    private func makeSampleManifest(itemCount: Int = 1) -> BackupManifest {
        BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(),
            appVersion: "1.1.0",
            itemCount: itemCount
        )
    }

    private func createTempImageDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BackupServiceTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        // 创建一个假图片文件
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

    // MARK: - Round-trip

    @Test("创建备份 → 读取清单 → 提取数据 round-trip")
    func createReadExtractRoundTrip() async throws {
        let service = BackupService()
        let payload = makeSamplePayload()
        let manifest = makeSampleManifest()
        let imageDir = try createTempImageDir()
        defer { cleanup(imageDir) }

        // 创建备份
        let backupURL = try await service.createBackup(
            payload: payload,
            manifest: manifest,
            imageBasePath: imageDir
        )
        defer { cleanup(backupURL) }

        #expect(FileManager.default.fileExists(atPath: backupURL.path))

        // 读取清单
        let readManifest = try await service.readManifest(from: backupURL)
        #expect(readManifest.schemaVersion == manifest.schemaVersion)
        #expect(readManifest.appVersion == manifest.appVersion)
        #expect(readManifest.itemCount == manifest.itemCount)

        // 提取数据
        let extractedPayload = try await service.extractPayload(from: backupURL)
        #expect(extractedPayload.reviewItems.count == 1)
        #expect(extractedPayload.reviewItems[0].content == "测试题目")
        #expect(extractedPayload.reviewItems[0].tagNames == ["重点"])
        #expect(extractedPayload.subjects.count == 1)
        #expect(extractedPayload.sources.count == 1)
        #expect(extractedPayload.grades.count == 1)
        #expect(extractedPayload.tags.count == 1)
    }

    @Test("图片恢复 round-trip")
    func imageRestoreRoundTrip() async throws {
        let service = BackupService()
        let payload = makeSamplePayload()
        let manifest = makeSampleManifest()
        let imageDir = try createTempImageDir()
        defer { cleanup(imageDir) }

        // 创建备份（含图片）
        let backupURL = try await service.createBackup(
            payload: payload,
            manifest: manifest,
            imageBasePath: imageDir
        )
        defer { cleanup(backupURL) }

        // 恢复图片到新目录
        let restoreDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RestoreTest_\(UUID().uuidString)")
        defer { cleanup(restoreDir) }

        try await service.restoreImages(from: backupURL, to: restoreDir)

        // 验证图片文件存在且内容一致
        let restoredImagePath = restoreDir.appendingPathComponent("images/test.jpg")
        #expect(FileManager.default.fileExists(atPath: restoredImagePath.path))
        let restoredData = try Data(contentsOf: restoredImagePath)
        #expect(String(data: restoredData, encoding: .utf8) == "fake-image-data")
    }

    @Test("进度回调正确触发")
    func progressCallbackFires() async throws {
        let service = BackupService()
        let payload = makeSamplePayload()
        let manifest = makeSampleManifest()
        let imageDir = try createTempImageDir()
        defer { cleanup(imageDir) }

        let callCount = CallCounter()
        let backupURL = try await service.createBackup(
            payload: payload,
            manifest: manifest,
            imageBasePath: imageDir,
            onProgress: { _, _ in
                Task { await callCount.increment() }
            }
        )
        defer { cleanup(backupURL) }

        // 至少触发过进度回调（1 张图片）
        let count = await callCount.value
        #expect(count > 0)
    }

    // MARK: - 异常路径

    @Test("读取损坏归档抛出 invalidArchive")
    func corruptArchiveThrowsError() async throws {
        let service = BackupService()
        let corruptFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("corrupt_\(UUID().uuidString).snapdrill")
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
            reviewItems: [], subjects: [], sources: [], grades: [], tags: []
        )
        let manifest = makeSampleManifest(itemCount: 0)
        let emptyDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("EmptyTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)
        defer { cleanup(emptyDir) }

        let backupURL = try await service.createBackup(
            payload: payload,
            manifest: manifest,
            imageBasePath: emptyDir
        )
        defer { cleanup(backupURL) }

        let extracted = try await service.extractPayload(from: backupURL)
        #expect(extracted.reviewItems.isEmpty)
        #expect(extracted.subjects.isEmpty)
    }
}
