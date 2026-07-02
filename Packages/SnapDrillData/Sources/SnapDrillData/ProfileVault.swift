//
//  ProfileVault.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Profile Vault 磁盘持久化的单一契约 owner：目录布局 + profiles.json codec。
//  此前 `profiles/<id>/{default.store, images/, preferences.json}` 与 profiles.json
//  读写散落手拼在 ProfileManager / ProfileMigration / RestoreProfileHelper /
//  SettingsBackupCoordinator 7+ 处、跨 2 个 SPM 模块——改一处忘另一处会漂移、甚至
//  让 Features 层绕过 ProfileManager 直写 profiles.json 造成内存↔磁盘 desync（数据丢失）。
//  收口于此：路径 `public`（Features 可定位备份目录），codec `internal`（仅 Data 层
//  ProfileManager / ProfileMigration 可写，Features 编译期无法直写 profiles.json）。
//

import Foundation
import SnapDrillCore

/// Profile Vault 磁盘布局 + profiles.json 元数据的单一真理源。
///
/// `nonisolated` + 值类型：`ProfileMigration` 在 `ModelContainer` / `ProfileManager`
/// 创建之前（pre-init 静态上下文）即可使用；`documentsURL` 可注入，便于单测在临时目录验证。
nonisolated public struct ProfileVault: Sendable {

    /// Vault 根所在的 Documents 目录（默认 App Documents；测试可注入临时目录）。
    public let documentsURL: URL

    public init(documentsURL: URL? = nil) {
        self.documentsURL = documentsURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - 路径契约（public）

    /// `Documents/profiles.json`
    public var profilesJSONURL: URL {
        documentsURL.appendingPathComponent("profiles.json")
    }

    /// `Documents/profiles/`
    public var profilesDirectoryURL: URL {
        documentsURL.appendingPathComponent("profiles")
    }

    /// `Documents/profiles/<id>/`
    public func profileDirectory(for profileId: UUID) -> URL {
        profilesDirectoryURL.appendingPathComponent(profileId.uuidString)
    }

    /// `Documents/profiles/<id>/default.store`
    public func storeURL(for profileId: UUID) -> URL {
        profileDirectory(for: profileId).appendingPathComponent("default.store")
    }

    /// `Documents/profiles/<id>/images/`
    public func imagesDirectory(for profileId: UUID) -> URL {
        profileDirectory(for: profileId).appendingPathComponent("images")
    }

    /// `Documents/profiles/<id>/preferences.json`
    public func preferencesURL(for profileId: UUID) -> URL {
        profileDirectory(for: profileId).appendingPathComponent("preferences.json")
    }

    /// `Documents/profiles/<id>/corrupted/`
    public func corruptedStoresDirectory(for profileId: UUID) -> URL {
        Self.corruptedStoresDirectory(forProfileDirectory: profileDirectory(for: profileId))
    }

    /// `Documents/profiles/<id>/corrupted/<timestamp>/`
    public func corruptedStoreIsolationDirectory(for profileId: UUID, timestamp: String) -> URL {
        Self.corruptedStoreIsolationDirectory(
            forProfileDirectory: profileDirectory(for: profileId),
            timestamp: timestamp
        )
    }

    /// `profiles/<id>/corrupted/` for a known profile directory.
    static func corruptedStoresDirectory(forProfileDirectory profileDirectory: URL) -> URL {
        profileDirectory.appendingPathComponent("corrupted", isDirectory: true)
    }

    /// `profiles/<id>/corrupted/<timestamp>/` for a known profile directory.
    static func corruptedStoreIsolationDirectory(forProfileDirectory profileDirectory: URL, timestamp: String) -> URL {
        corruptedStoresDirectory(forProfileDirectory: profileDirectory)
            .appendingPathComponent(timestamp, isDirectory: true)
    }

    // MARK: - 目录确保（internal）

    /// 创建 `profiles/<id>/` 与其 `images/` 子目录（幂等）。
    func createProfileDirectories(for profileId: UUID) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: profileDirectory(for: profileId), withIntermediateDirectories: true)
        try fm.createDirectory(at: imagesDirectory(for: profileId), withIntermediateDirectories: true)
    }

    // MARK: - profiles.json codec（internal——仅 Data 层可写，防 Features 绕过 ProfileManager）

    /// 读取并解码 profiles.json；不存在 / 损坏返回 `[]`（与历史行为一致）。
    func loadProfiles() -> [Profile] {
        guard let data = try? Data(contentsOf: profilesJSONURL) else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode([Profile].self, from: data)
        } catch {
            SnapDrillLogger.data.error("ProfileVault: profiles.json 解码失败: \(error.localizedDescription)")
            return []
        }
    }

    /// 编码并写入 profiles.json（iso8601，照搬历史格式，0 兼容性变更）。
    func saveProfiles(_ profiles: [Profile]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(profiles)
        try data.write(to: profilesJSONURL)
    }
}
