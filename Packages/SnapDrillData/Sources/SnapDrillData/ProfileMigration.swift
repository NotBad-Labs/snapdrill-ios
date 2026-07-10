//
//  ProfileMigration.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  首次升级迁移：将旧版单数据库结构迁移到 Multi-Profile 目录结构。
//

import Foundation
import SnapDrillCore

/// 首次升级迁移
///
/// 老用户升级时，将现有的 `default.store` 和 `images/` 移入默认 Profile 目录。
/// 必须在 `ModelContainer` 创建之前执行。
enum ProfileMigration {

    private static let fileManager = FileManager.default

    private static var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// 执行迁移（如果需要）。幂等操作：`profiles.json` 已存在则跳过。
    static func migrateIfNeeded() {
        migrateIfNeeded(documentsURL: documentsURL, defaults: .standard)
    }

    /// 执行迁移（如果需要）。测试可注入隔离 Documents/UserDefaults，生产入口保持默认行为。
    static func migrateIfNeeded(documentsURL: URL, defaults: UserDefaults) {
        let vault = ProfileVault(documentsURL: documentsURL)
        guard !fileManager.fileExists(atPath: vault.profilesJSONURL.path) else { return }

        SnapDrillLogger.data.info("ProfileMigration: 首次升级，开始迁移到 Multi-Profile 目录结构")

        let profile = createDefaultProfile(defaults: defaults)
        let profileDir = vault.profileDirectory(for: profile.id)

        do {
            try fileManager.createDirectory(at: profileDir, withIntermediateDirectories: true)
            try migrateDatabase(from: documentsURL, to: profileDir)
            try migrateImages(from: documentsURL, to: profileDir)
            savePerProfilePreferences(to: profileDir, defaults: defaults)
            try vault.saveProfiles([profile])

            defaults.set(profile.id.uuidString, forKey: UDKey.activeProfileId)
            cleanupOldFiles(in: documentsURL)

            SnapDrillLogger.data.info("ProfileMigration: 迁移完成，默认 Profile: \(profile.name)")
        } catch {
            SnapDrillLogger.data.error("ProfileMigration: 迁移失败: \(error.localizedDescription)")
            createFallbackProfile(documentsURL: documentsURL, defaults: defaults)
        }
    }

    // MARK: - Steps

    private static func createDefaultProfile(defaults: UserDefaults) -> Profile {
        let userName = defaults.string(forKey: UDKey.userName) ?? L10n.Settings.defaultProfileName
        let userAvatar = defaults.string(forKey: UDKey.userAvatar) ?? "person.crop.circle.fill"
        let avatarColorIndex = defaults.integer(forKey: UDKey.userAvatarColorIndex)
        return Profile(name: userName, avatar: userAvatar, avatarColorIndex: avatarColorIndex)
    }

    private static func migrateDatabase(from documentsURL: URL, to profileDir: URL) throws {
        let oldStoreURL = documentsURL.appendingPathComponent("default.store")
        let newStoreURL = profileDir.appendingPathComponent("default.store")
        guard fileManager.fileExists(atPath: oldStoreURL.path) else { return }

        try fileManager.copyItem(at: oldStoreURL, to: newStoreURL)
        for suffix in ["-wal", "-shm"] {
            let oldAux = URL(fileURLWithPath: oldStoreURL.path + suffix)
            let newAux = URL(fileURLWithPath: newStoreURL.path + suffix)
            if fileManager.fileExists(atPath: oldAux.path) {
                try fileManager.copyItem(at: oldAux, to: newAux)
            }
        }
    }

    private static func migrateImages(from documentsURL: URL, to profileDir: URL) throws {
        let oldImagesURL = documentsURL.appendingPathComponent("images")
        let newImagesURL = profileDir.appendingPathComponent("images")
        if fileManager.fileExists(atPath: oldImagesURL.path) {
            try fileManager.copyItem(at: oldImagesURL, to: newImagesURL)
        } else {
            try fileManager.createDirectory(at: newImagesURL, withIntermediateDirectories: true)
        }
    }

    private static func savePerProfilePreferences(to profileDir: URL, defaults: UserDefaults) {
        var prefs: [String: Any] = [:]
        for key in ProfileManager.perProfileKeys {
            if let value = defaults.object(forKey: key) {
                prefs[key] = value
            }
        }
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(CategoryDimensionModel.visibilityKeyPrefix) {
            prefs[key] = defaults.object(forKey: key)
        }
        let (safe, dropped) = ProfileManager.jsonSafePreferences(prefs)
        if !dropped.isEmpty {
            SnapDrillLogger.data.warning("ProfileMigration: 偏好含非 JSON 值，已跳过键：\(dropped.joined(separator: ", "))")
        }
        let prefsURL = profileDir.appendingPathComponent("preferences.json")
        do {
            let data = try JSONSerialization.data(withJSONObject: safe, options: .prettyPrinted)
            try data.write(to: prefsURL)
        } catch {
            SnapDrillLogger.data.error("ProfileMigration: 偏好保存失败: \(error.localizedDescription)")
        }
    }

    private static func cleanupOldFiles(in documentsURL: URL) {
        let oldStoreURL = documentsURL.appendingPathComponent("default.store")
        try? fileManager.removeItem(at: oldStoreURL) // best-effort: 迁移已完成，旧文件删不掉不影响功能
        for suffix in ["-wal", "-shm"] {
            try? fileManager.removeItem(at: URL(fileURLWithPath: oldStoreURL.path + suffix)) // best-effort: WAL/SHM 辅助文件清理
        }
        try? fileManager.removeItem(at: documentsURL.appendingPathComponent("images")) // best-effort: 旧图片目录清理
    }

    private static func createFallbackProfile(documentsURL: URL, defaults: UserDefaults) {
        let vault = ProfileVault(documentsURL: documentsURL)
        let userName = defaults.string(forKey: UDKey.userName) ?? L10n.Settings.defaultProfileName
        let profile = Profile(name: userName)
        do {
            try vault.createProfileDirectories(for: profile.id)
            try vault.saveProfiles([profile])
        } catch {
            SnapDrillLogger.data.error("ProfileMigration: fallback Profile 创建失败: \(error.localizedDescription)")
        }
        defaults.set(profile.id.uuidString, forKey: UDKey.activeProfileId)
    }
}
