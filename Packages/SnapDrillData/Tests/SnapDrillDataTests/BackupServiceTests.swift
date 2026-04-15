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

@Suite("BackupService 单元测试", .serialized)
struct BackupServiceTests {

    // MARK: - Helpers

    private static let testProfileId = UUID()

    private func makeSamplePayload() -> BackupPayload {
        let profileData = ProfileBackupData(
            profileName: "默认",
            profileId: Self.testProfileId,
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
        #expect(profile.reviewItems[0].tagNames == ["重点"])
        #expect(profile.subjects.count == 1)
        #expect(profile.sources.count == 1)
        #expect(profile.grades.count == 1)
        #expect(profile.tags.count == 1)
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
        #expect(String(data: restoredData, encoding: .utf8) == "fake-image-data")
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
        let emptyProfile = ProfileBackupData(
            profileName: "空",
            profileId: UUID(),
            reviewItems: [],
            subjects: [],
            sources: [],
            grades: [],
            tags: []
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
        #expect(extracted.profiles[0].subjects.isEmpty)
    }

    // MARK: - 路径遍历防御

    @Test("restoreImages 跳过含 .. 的路径遍历条目")
    func restoreImages_skipsPathTraversal() async throws {
        let service = BackupService()
        let profileId = UUID()
        let profileData = ProfileBackupData(
            profileName: "测试",
            profileId: profileId,
            reviewItems: [
                ReviewItemBackupDTO(
                    id: UUID(),
                    content: "恶意条目",
                    imagePath: "../evil.jpg",
                    createdAt: Date(),
                    lastReviewedAt: .distantPast,
                    nextReviewAt: .distantPast,
                    subject: "数学",
                    source: "作业",
                    tagNames: [],
                    answerText: nil,
                    answerImagePath: nil,
                    difficulty: 1,
                    grade: "",
                    easeFactor: 2.5,
                    interval: 0,
                    repetitions: 0
                )
            ],
            subjects: [], sources: [], grades: [], tags: []
        )
        let payload = BackupPayload(profiles: [profileData])
        let manifest = makeSampleManifest()

        let sourceDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PathTraversalTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        defer { cleanup(sourceDir) }

        let backupURL = try await service.createBackup(
            payload: payload,
            manifest: manifest,
            profileDirectories: [sourceDir]
        )
        defer { cleanup(backupURL) }

        let restoreDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RestoreTraversalTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: restoreDir, withIntermediateDirectories: true)
        defer { cleanup(restoreDir) }

        try await service.restoreImages(from: backupURL, profileId: profileId, to: restoreDir)

        let evilPath = restoreDir.deletingLastPathComponent().appendingPathComponent("evil.jpg")
        #expect(!FileManager.default.fileExists(atPath: evilPath.path))
    }
}

/// 线程安全计数器
private actor CallCounter {
    private(set) var value = 0
    func increment() { value += 1 }
}
