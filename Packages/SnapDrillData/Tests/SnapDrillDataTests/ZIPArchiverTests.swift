//
//  ZIPArchiverTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import Testing
@testable import SnapDrillData

@Suite("ZIPArchiver 单元测试", .serialized)
struct ZIPArchiverTests {

    @Test("ZIP 写入失败时保留原文件，成功时原子替换")
    func createArchive_preservesOriginalWhenTemporaryWriteFails_thenReplacesOnSuccess() async throws {
        let fileManager = FileManager.default
        let workingDir = fileManager.temporaryDirectory
            .appendingPathComponent("ZIPArchiverTests_\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: workingDir, withIntermediateDirectories: true)
        defer {
            try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: workingDir.path)
            try? fileManager.removeItem(at: workingDir)
        }

        let destination = workingDir.appendingPathComponent("backup.zip")
        let originalData = Data("original-zip-bytes".utf8)
        try originalData.write(to: destination)

        let blockedTemporaryDestination = destination.appendingPathExtension("tmp")
        try fileManager.createDirectory(at: blockedTemporaryDestination, withIntermediateDirectories: true)
        try fileManager.setAttributes([.posixPermissions: 0o555], ofItemAtPath: workingDir.path)

        var didThrow = false
        do {
            try ZIPArchiver().createArchive(
                entries: [
                    ZIPEntry(path: "first.txt", data: Data("first".utf8)),
                    ZIPEntry(path: "second.txt", data: Data("second".utf8))
                ],
                at: destination
            )
        } catch {
            didThrow = true
        }

        #expect(didThrow)
        #expect(try Data(contentsOf: destination) == originalData)

        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: workingDir.path)
        try fileManager.removeItem(at: blockedTemporaryDestination)

        let manifest = BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(timeIntervalSince1970: 0),
            appVersion: "1.1.0",
            totalItemCount: 0,
            profileCount: 0,
            profileNames: []
        )
        let payload = BackupPayload(profiles: [])
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        try ZIPArchiver().createArchive(
            entries: [
                ZIPEntry(path: "manifest.json", data: try encoder.encode(manifest)),
                ZIPEntry(path: "data.json", data: try encoder.encode(payload))
            ],
            at: destination
        )

        #expect(try Data(contentsOf: destination) != originalData)
        let service = BackupService()
        let restoredManifest = try await service.readManifest(from: destination)
        let restoredPayload = try await service.extractPayload(from: destination)
        #expect(restoredManifest.schemaVersion == manifest.schemaVersion)
        #expect(restoredManifest.profileCount == 0)
        #expect(restoredPayload.profiles.isEmpty)
    }
}
