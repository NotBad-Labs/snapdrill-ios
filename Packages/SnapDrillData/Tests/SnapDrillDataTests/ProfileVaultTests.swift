//
//  ProfileVaultTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ProfileVault 路径布局 + profiles.json codec 的回归守护；
//  ProfileManager.ingestProfile / discardProfile 的内存一致性契约（修 #3 desync 的机制）。
//

import Testing
import Foundation
@testable import SnapDrillData
import SnapDrillCore

struct ProfileVaultTests {

    /// 在临时目录构造 vault（注入 documentsURL，避免污染真实沙盒）。
    private func makeTempVault() throws -> (vault: ProfileVault, docs: URL) {
        let docs = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        return (ProfileVault(documentsURL: docs), docs)
    }

    @Test("路径布局与历史磁盘结构 1:1（防 refactor 漂移导致数据错位）")
    func testPathLayoutMatchesLegacy() {
        let docs = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let vault = ProfileVault(documentsURL: docs)
        let id = UUID()
        #expect(vault.profilesJSONURL == docs.appendingPathComponent("profiles.json"))
        #expect(vault.profilesDirectoryURL == docs.appendingPathComponent("profiles"))
        #expect(vault.profileDirectory(for: id) == docs.appendingPathComponent("profiles").appendingPathComponent(id.uuidString))
        #expect(vault.storeURL(for: id) == vault.profileDirectory(for: id).appendingPathComponent("default.store"))
        #expect(vault.imagesDirectory(for: id) == vault.profileDirectory(for: id).appendingPathComponent("images"))
        #expect(vault.preferencesURL(for: id) == vault.profileDirectory(for: id).appendingPathComponent("preferences.json"))
    }

    @Test("profiles.json load/save roundtrip（iso8601 codec，0 格式变更）")
    func testCodecRoundtrip() throws {
        let (vault, docs) = try makeTempVault()
        defer { try? FileManager.default.removeItem(at: docs) }

        #expect(vault.loadProfiles().isEmpty) // 不存在 → []

        let p1 = Profile(name: "甲")
        let p2 = Profile(name: "乙")
        try vault.saveProfiles([p1, p2])

        let loaded = vault.loadProfiles()
        #expect(loaded.count == 2)
        #expect(loaded.map(\.id) == [p1.id, p2.id])
        #expect(loaded.map(\.name) == ["甲", "乙"])
    }

    @Test("createProfileDirectories 建 profiles/<id>/ 与 images/ 子目录")
    func testCreateDirectories() throws {
        let (vault, docs) = try makeTempVault()
        defer { try? FileManager.default.removeItem(at: docs) }

        let id = UUID()
        try vault.createProfileDirectories(for: id)
        #expect(FileManager.default.fileExists(atPath: vault.profileDirectory(for: id).path))
        #expect(FileManager.default.fileExists(atPath: vault.imagesDirectory(for: id).path))
    }
}

@MainActor
struct ProfileManagerIngestTests {

    @Test("ingestProfile 更新内存 profiles + scope，且幂等（修 #3 的核心 API）")
    func testIngestUpdatesMemoryAndIdempotent() throws {
        let pm = ProfileManager(inMemory: true)
        let baseCount = pm.profiles.count

        let id = UUID()
        let ingested = try pm.ingestProfile(id: id, name: "还原导入的学习者")
        #expect(ingested.id == id)
        #expect(pm.profiles.count == baseCount + 1)
        #expect(pm.profiles.contains { $0.id == id })

        // 幂等：ID 已存在直接返回现有，不重复追加
        let again = try pm.ingestProfile(id: id, name: "重复名")
        #expect(again.id == id)
        #expect(pm.profiles.count == baseCount + 1)
    }

    @Test("discardProfile 从内存移除（还原失败回滚孤儿壳，#4）")
    func testDiscardRemovesFromMemory() throws {
        let pm = ProfileManager(inMemory: true)
        let id = UUID()
        _ = try pm.ingestProfile(id: id, name: "临时还原 Profile")
        #expect(pm.profiles.contains { $0.id == id })

        pm.discardProfile(id: id)
        #expect(!pm.profiles.contains { $0.id == id })
    }
}
