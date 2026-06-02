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
        let vault = ProfileVault()
        guard !fileManager.fileExists(atPath: vault.profilesJSONURL.path) else { return }

        SnapDrillLogger.data.info("ProfileMigration: 首次升级，开始迁移到 Multi-Profile 目录结构")

        let profile = createDefaultProfile()
        let profileDir = vault.profileDirectory(for: profile.id)

        do {
            try fileManager.createDirectory(at: profileDir, withIntermediateDirectories: true)
            try migrateDatabase(to: profileDir)
            try migrateImages(to: profileDir)
            savePerProfilePreferences(to: profileDir)
            try vault.saveProfiles([profile])

            UserDefaults.standard.set(profile.id.uuidString, forKey: UDKey.activeProfileId)
            cleanupOldFiles()

            SnapDrillLogger.data.info("ProfileMigration: 迁移完成，默认 Profile: \(profile.name)")
        } catch {
            SnapDrillLogger.data.error("ProfileMigration: 迁移失败: \(error.localizedDescription)")
            createFallbackProfile()
        }
    }

    // MARK: - Steps

    private static func createDefaultProfile() -> Profile {
        let userName = UserDefaults.standard.string(forKey: UDKey.userName) ?? "同学"
        let userAvatar = UserDefaults.standard.string(forKey: UDKey.userAvatar) ?? "person.crop.circle.fill"
        let avatarColorIndex = UserDefaults.standard.integer(forKey: UDKey.userAvatarColorIndex)
        return Profile(name: userName, avatar: userAvatar, avatarColorIndex: avatarColorIndex)
    }

    private static func migrateDatabase(to profileDir: URL) throws {
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

    private static func migrateImages(to profileDir: URL) throws {
        let oldImagesURL = documentsURL.appendingPathComponent("images")
        let newImagesURL = profileDir.appendingPathComponent("images")
        if fileManager.fileExists(atPath: oldImagesURL.path) {
            try fileManager.copyItem(at: oldImagesURL, to: newImagesURL)
        } else {
            try fileManager.createDirectory(at: newImagesURL, withIntermediateDirectories: true)
        }
    }

    private static func savePerProfilePreferences(to profileDir: URL) {
        let defaults = UserDefaults.standard
        var prefs: [String: Any] = [:]
        for key in ProfileManager.perProfileKeys {
            if let value = defaults.object(forKey: key) {
                prefs[key] = value
            }
        }
        let prefsURL = profileDir.appendingPathComponent("preferences.json")
        do {
            let data = try JSONSerialization.data(withJSONObject: prefs, options: .prettyPrinted)
            try data.write(to: prefsURL)
        } catch {
            SnapDrillLogger.data.error("ProfileMigration: 偏好保存失败: \(error.localizedDescription)")
        }
    }

    private static func cleanupOldFiles() {
        let oldStoreURL = documentsURL.appendingPathComponent("default.store")
        try? fileManager.removeItem(at: oldStoreURL) // best-effort: 迁移已完成，旧文件删不掉不影响功能
        for suffix in ["-wal", "-shm"] {
            try? fileManager.removeItem(at: URL(fileURLWithPath: oldStoreURL.path + suffix)) // best-effort: WAL/SHM 辅助文件清理
        }
        try? fileManager.removeItem(at: documentsURL.appendingPathComponent("images")) // best-effort: 旧图片目录清理
    }

    private static func createFallbackProfile() {
        let vault = ProfileVault()
        let userName = UserDefaults.standard.string(forKey: UDKey.userName) ?? "同学"
        let profile = Profile(name: userName)
        do {
            try vault.createProfileDirectories(for: profile.id)
            try vault.saveProfiles([profile])
        } catch {
            SnapDrillLogger.data.error("ProfileMigration: fallback Profile 创建失败: \(error.localizedDescription)")
        }
        UserDefaults.standard.set(profile.id.uuidString, forKey: UDKey.activeProfileId)
    }
}
