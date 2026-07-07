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
        #expect(vault.corruptedStoresDirectory(for: id) == vault.profileDirectory(for: id).appendingPathComponent("corrupted", isDirectory: true))
        #expect(
            vault.corruptedStoreIsolationDirectory(for: id, timestamp: "2026-07-02T12-00-00.000Z")
                == vault.corruptedStoresDirectory(for: id).appendingPathComponent("2026-07-02T12-00-00.000Z", isDirectory: true)
        )
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

    @Test("profiles.json 读失败时记录错误路径并返回空数组")
    func testLoadProfilesReadFailureReturnsEmpty() throws {
        let (vault, docs) = try makeTempVault()
        defer { try? FileManager.default.removeItem(at: docs) }

        try FileManager.default.createDirectory(at: vault.profilesJSONURL, withIntermediateDirectories: false)

        #expect(vault.loadProfiles().isEmpty)
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

    @Test("外来 Profile 还原走 coordinator 磁盘路径")
    func testRestoreForeignProfileUsesDiskRestoreCoordinatorPath() async throws {
        let (vault, docs) = try makeTempVault()
        let previousActiveProfileId = UserDefaults.standard.string(forKey: UDKey.activeProfileId)
        defer {
            if let previousActiveProfileId {
                UserDefaults.standard.set(previousActiveProfileId, forKey: UDKey.activeProfileId)
            } else {
                UserDefaults.standard.removeObject(forKey: UDKey.activeProfileId)
            }
            try? FileManager.default.removeItem(at: docs)
        }

        let manager = await ProfileManager.create(vault: vault)
        let foreignProfileId = UUID()
        let foreignProfileData = makeForeignProfileBackupData(profileId: foreignProfileId)

        #expect(!manager.profiles.contains { $0.id == foreignProfileId })
        let ingestedProfile = try manager.ingestProfile(id: foreignProfileId, name: foreignProfileData.profileName)
        let repositories = await makeRestoreRepositoriesLikeCoordinator(for: ingestedProfile, vault: vault)

        try await repositories.restoreFromProfileData(foreignProfileData)

        #expect(try repositories.archive.totalCount() == foreignProfileData.reviewItems.count)
    }

    @Test("ProfileManager 暴露活跃 Profile 的磁盘 store 恢复事件")
    func testProfileManagerExposesStoreRecoveryEvent() async throws {
        let docs = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let vault = ProfileVault(documentsURL: docs)
        let profile = Profile(name: "Recovered")
        let previousActiveProfileId = UserDefaults.standard.string(forKey: UDKey.activeProfileId)
        defer {
            if let previousActiveProfileId {
                UserDefaults.standard.set(previousActiveProfileId, forKey: UDKey.activeProfileId)
            } else {
                UserDefaults.standard.removeObject(forKey: UDKey.activeProfileId)
            }
            try? FileManager.default.removeItem(at: docs)
        }

        try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        try vault.createProfileDirectories(for: profile.id)
        try vault.saveProfiles([profile])
        UserDefaults.standard.set(profile.id.uuidString, forKey: UDKey.activeProfileId)
        try Data("not sqlite".utf8).write(to: vault.storeURL(for: profile.id))

        let manager = await ProfileManager.create(vault: vault)
        let event = try #require(manager.storeRecoveryEvent)

        #expect(!manager.isUsingInMemoryFallback)
        #expect(manager.activeProfileId == profile.id)
        #expect(event.storeURL == vault.storeURL(for: profile.id))
        #expect(event.isolationDirectoryURL.path.hasPrefix(vault.corruptedStoresDirectory(for: profile.id).path))
    }

    @Test("ProfileManager 启动时保留首个重复 Profile ID，避免 profiles.json 触发 Dictionary trap")
    func testProfileManagerDeduplicatesDuplicateProfileIds() async throws {
        let (vault, docs) = try makeTempVault()
        let duplicateId = UUID()
        let first = Profile(id: duplicateId, name: "First")
        let duplicate = Profile(id: duplicateId, name: "Duplicate")
        let previousActiveProfileId = UserDefaults.standard.string(forKey: UDKey.activeProfileId)
        defer {
            if let previousActiveProfileId {
                UserDefaults.standard.set(previousActiveProfileId, forKey: UDKey.activeProfileId)
            } else {
                UserDefaults.standard.removeObject(forKey: UDKey.activeProfileId)
            }
            try? FileManager.default.removeItem(at: docs)
        }

        try vault.saveProfiles([first, duplicate])
        UserDefaults.standard.set(duplicateId.uuidString, forKey: UDKey.activeProfileId)

        let manager = await ProfileManager.create(vault: vault)

        #expect(manager.profiles.map(\.id) == [duplicateId])
        #expect(manager.profiles.map(\.name) == ["First"])
        #expect(manager.activeProfileId == duplicateId)
    }

    private func makeTempVault() throws -> (vault: ProfileVault, docs: URL) {
        let docs = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        return (ProfileVault(documentsURL: docs), docs)
    }

    private func makeRestoreRepositoriesLikeCoordinator(for profile: Profile, vault: ProfileVault) async -> RepositoryContainer {
        let executor = await DataExecutor.createOffMainActor(storeURL: vault.storeURL(for: profile.id))
        let scope = ProfileScope(id: profile.id, name: profile.name)
        return RepositoryContainer(
            executor: executor,
            scope: scope,
            profileDirectory: vault.profileDirectory(for: profile.id)
        )
    }

    private func makeForeignProfileBackupData(profileId: UUID) -> ProfileBackupData {
        let now = Date(timeIntervalSinceReferenceDate: 0)
        let dimensionId = UUID()
        let valueId = UUID()
        let item = ArchiveItemBackupDTO(
            id: UUID(),
            content: "外来 Profile 磁盘还原复现题",
            imagePath: nil,
            createdAt: now,
            lastReviewedAt: now,
            nextReviewAt: now,
            answerText: "A",
            answerImagePath: nil,
            easeFactor: 2.5,
            interval: 0,
            repetitions: 0,
            categoryValueIds: [valueId]
        )
        let dimension = CategoryDimensionBackupDTO(
            id: dimensionId,
            name: "分类",
            isMultiValue: false,
            isBuiltIn: true,
            systemKey: CategorySystemKey.category,
            sortOrder: 0,
            icon: "folder"
        )
        let value = CategoryValueBackupDTO(
            id: valueId,
            name: "复现",
            icon: "circle",
            colorHex: "#0A84FF",
            sortOrder: 0,
            createdAt: now,
            dimensionId: dimensionId
        )
        return ProfileBackupData(
            profileName: "外来资料空间",
            profileId: profileId,
            reviewItems: [item],
            dimensions: [dimension],
            categoryValues: [value]
        )
    }
}
