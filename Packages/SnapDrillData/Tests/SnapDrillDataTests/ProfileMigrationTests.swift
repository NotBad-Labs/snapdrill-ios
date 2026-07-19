//
//  ProfileMigrationTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  首次升级迁移的回归守护：旧版 Documents/default.store + images/ + UserDefaults
//  必须完整迁入 Profile Vault。
//

import Foundation
import SwiftData
import Testing
@testable import SnapDrillCore
@testable import SnapDrillData

struct ProfileMigrationTests {

    private enum TestSetupError: Error {
        case defaultsUnavailable
    }

    private struct ArchiveSnapshot {
        let id: UUID
        let content: String?
        let imagePath: String?
        let easeFactor: Double
        let interval: Int
        let repetitions: Int
    }

    @Test("旧版单库结构迁入 Profile Vault 后保留 store、图片、偏好与 activeProfileId")
    func migratesLegacyDocumentsIntoProfileVault() throws {
        let documentsURL = try makeTempDocuments()
        defer { try? FileManager.default.removeItem(at: documentsURL) }

        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set("Migrated User", forKey: UDKey.userName)
        defaults.set("star.fill", forKey: UDKey.userAvatar)
        defaults.set(3, forKey: UDKey.userAvatarColorIndex)
        defaults.set("Keep local first", forKey: UDKey.userMotto)

        let legacyItemID = UUID()
        try writeLegacyStore(
            at: documentsURL.appendingPathComponent("default.store"),
            itemID: legacyItemID
        )

        let legacyImageData = Data("legacy image bytes".utf8)
        let legacyImagesURL = documentsURL.appendingPathComponent("images")
        try FileManager.default.createDirectory(at: legacyImagesURL, withIntermediateDirectories: true)
        try legacyImageData.write(to: legacyImagesURL.appendingPathComponent("legacy.jpg"))

        ProfileMigration.migrateIfNeeded(documentsURL: documentsURL, defaults: defaults)

        let vault = ProfileVault(documentsURL: documentsURL)
        let profiles = vault.loadProfiles()
        let profile = try #require(profiles.first)
        #expect(profiles.count == 1)
        #expect(profile.name == "Migrated User")
        #expect(profile.avatar == "star.fill")
        #expect(profile.avatarColorIndex == 3)
        #expect(defaults.string(forKey: UDKey.activeProfileId) == profile.id.uuidString)

        let migratedItems = try readArchiveSnapshots(from: vault.storeURL(for: profile.id))
        let migratedItem = try #require(migratedItems.first)
        #expect(migratedItems.count == 1)
        #expect(migratedItem.id == legacyItemID)
        #expect(migratedItem.content == "legacy migration sample")
        #expect(migratedItem.imagePath == "legacy.jpg")
        #expect(migratedItem.easeFactor == 2.1)
        #expect(migratedItem.interval == 4)
        #expect(migratedItem.repetitions == 2)

        let migratedImageURL = vault.imagesDirectory(for: profile.id).appendingPathComponent("legacy.jpg")
        #expect(try Data(contentsOf: migratedImageURL) == legacyImageData)

        let preferences = try readPreferences(from: vault.preferencesURL(for: profile.id))
        #expect(preferences[UDKey.userName] as? String == "Migrated User")
        #expect(preferences[UDKey.userAvatar] as? String == "star.fill")
        #expect(preferences[UDKey.userAvatarColorIndex] as? Int == 3)
        #expect(preferences[UDKey.userMotto] as? String == "Keep local first")

        #expect(!FileManager.default.fileExists(atPath: documentsURL.appendingPathComponent("default.store").path))
        #expect(!FileManager.default.fileExists(atPath: legacyImagesURL.path))
    }

    @Test("profiles.json 已存在时迁移幂等跳过，不触碰旧单库")
    func skipsWhenProfilesJSONAlreadyExists() throws {
        let documentsURL = try makeTempDocuments()
        defer { try? FileManager.default.removeItem(at: documentsURL) }

        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let vault = ProfileVault(documentsURL: documentsURL)
        let existingProfile = Profile(name: "Existing")
        try vault.saveProfiles([existingProfile])

        let legacyStoreURL = documentsURL.appendingPathComponent("default.store")
        let legacyStoreBytes = Data("legacy bytes that should not be touched".utf8)
        try legacyStoreBytes.write(to: legacyStoreURL)

        ProfileMigration.migrateIfNeeded(documentsURL: documentsURL, defaults: defaults)

        let profiles = vault.loadProfiles()
        let profile = try #require(profiles.first)
        #expect(profiles.count == 1)
        #expect(profile.id == existingProfile.id)
        #expect(profile.name == "Existing")
        #expect(profile.avatar == "person.crop.circle.fill")
        #expect(profile.avatarColorIndex == 0)
        #expect(try Data(contentsOf: legacyStoreURL) == legacyStoreBytes)
        #expect(defaults.string(forKey: UDKey.activeProfileId) == nil)
    }

    @Test("迁移跳过 Data 偏好并保留可序列化值与动态可见性")
    func dropsNonJSONPreferencesWithoutCrashing() throws {
        let documentsURL = try makeTempDocuments()
        defer { try? FileManager.default.removeItem(at: documentsURL) }

        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let nonJSONKey = "legacy.non_json.preference"
        defaults.set(Data("legacy".utf8), forKey: nonJSONKey)
        defaults.set("Keep local first", forKey: UDKey.userMotto)
        let visibilityKey = "\(CategoryDimensionModel.visibilityKeyPrefix)legacy"
        defaults.set(false, forKey: visibilityKey)

        ProfileMigration.migrateIfNeeded(documentsURL: documentsURL, defaults: defaults)

        let vault = ProfileVault(documentsURL: documentsURL)
        let profile = try #require(vault.loadProfiles().first)
        let preferences = try readPreferences(from: vault.preferencesURL(for: profile.id))
        #expect(preferences[nonJSONKey] == nil)
        #expect(preferences[UDKey.userMotto] as? String == "Keep local first")
        #expect(preferences[visibilityKey] as? Bool == false)
    }

    private func makeTempDocuments() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProfileMigrationTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeDefaults() throws -> (defaults: UserDefaults, suiteName: String) {
        let suiteName = "ProfileMigrationTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestSetupError.defaultsUnavailable
        }
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    private func writeLegacyStore(at storeURL: URL, itemID: UUID) throws {
        let schema = Schema(SnapDrillSchemaV1.models)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: SnapDrillMigrationPlan.self,
            configurations: ModelConfiguration(url: storeURL)
        )
        let context = container.mainContext
        let item = ArchiveItemModel(
            id: itemID,
            content: "legacy migration sample",
            imagePath: "legacy.jpg",
            easeFactor: 2.1,
            interval: 4,
            repetitions: 2
        )
        context.insert(item)
        try context.save()
    }

    private func readArchiveSnapshots(from storeURL: URL) throws -> [ArchiveSnapshot] {
        let schema = Schema(SnapDrillSchemaV1.models)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: SnapDrillMigrationPlan.self,
            configurations: ModelConfiguration(url: storeURL)
        )
        let descriptor = FetchDescriptor<ArchiveItemModel>()
        return try container.mainContext.fetch(descriptor).map {
            ArchiveSnapshot(
                id: $0.id,
                content: $0.content,
                imagePath: $0.imagePath,
                easeFactor: $0.easeFactor,
                interval: $0.interval,
                repetitions: $0.repetitions
            )
        }
    }

    private func readPreferences(from preferencesURL: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: preferencesURL)
        let object = try JSONSerialization.jsonObject(with: data)
        return object as? [String: Any] ?? [:]
    }
}
