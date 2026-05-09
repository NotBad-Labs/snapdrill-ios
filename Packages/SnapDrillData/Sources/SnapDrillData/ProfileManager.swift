//
//  ProfileManager.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2026/03/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Profile 生命周期管理器，负责 Profile CRUD、数据库切换和偏好同步。
//

import Foundation
import Observation
import SwiftData
import SnapDrillCore

/// Profile 管理器（Vault 模式的核心枢纽）
///
/// 每个 Profile 对应独立的 SwiftData 数据库和图片目录。
/// 切换 Profile 时重建 `ModelContainer` 和 `RepositoryContainer`，
/// SwiftUI 通过 `.id(activeProfileId)` 强制重建视图树。
@Observable
public final class ProfileManager {

    // MARK: - State

    /// 所有 Profile 列表
    public private(set) var profiles: [Profile] = []

    /// 当前活跃 Profile 的 ID
    public private(set) var activeProfileId: UUID

    /// 当前活跃的 ModelContainer
    public private(set) var activeContainer: ModelContainer

    /// 当前活跃的 RepositoryContainer
    public private(set) var activeRepositories: RepositoryContainer

    /// 数据层 executor（actor），拥有 ModelContainer
    public private(set) var executor: DataExecutor

    /// 是否使用内存降级存储（同步自 executor）
    public private(set) var isUsingInMemoryFallback: Bool = false

    /// 当前活跃的 ImageStorage
    public private(set) var activeImageStorage: ImageStorage

    // MARK: - Private

    private let fileManager = FileManager.default
    private let isInMemory: Bool

    /// Documents 目录
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// profiles.json 路径
    private var profilesFileURL: URL {
        documentsURL.appendingPathComponent("profiles.json")
    }

    /// profiles/ 根目录
    private var profilesDirectoryURL: URL {
        documentsURL.appendingPathComponent("profiles")
    }

    // MARK: - Per-profile UserDefaults 键

    /// 需要 per-profile 隔离的 UserDefaults 键
    static let perProfileKeys: [String] = [
        UDKey.userName, UDKey.userAvatar, UDKey.userAvatarColorIndex, UDKey.userMotto,
        UDKey.dailyReviewGoal,
        UDKey.captureFieldSubject, UDKey.captureFieldSource, UDKey.captureFieldDifficulty,
        UDKey.captureFieldGrade, UDKey.captureFieldAnswer,
        UDKey.lastSelectedSubject, UDKey.lastSelectedSource,
        UDKey.cardFrontAlignment, UDKey.cardFrontFontSize,
        UDKey.cardContextAlignment, UDKey.cardContextFontSize,
        UDKey.reviewReminderEnabled, UDKey.reviewReminderTime,
        UDKey.notificationsEnabled, UDKey.notificationHour, UDKey.notificationMinute,
        UDKey.soundEnabled, UDKey.badgeEnabled,
        UDKey.captureDraftMetadata,
        UDKey.tipReviewSwipeSeen, UDKey.tipFieldConfigSeen
    ]

    // MARK: - Initialization

    /// 初始化 ProfileManager
    ///
    /// 首次启动时自动执行数据迁移（将旧数据移入默认 Profile 目录）。
    /// - Parameter inMemory: 为 true 时使用内存存储（UI 测试用）
    public init(inMemory: Bool = false) {
        self.isInMemory = inMemory
        if inMemory {
            // UI 测试模式：跳过文件迁移和磁盘操作，使用纯内存存储
            let profileId = UUID()
            self.profiles = [Profile(id: profileId, name: "Test")]
            self.activeProfileId = profileId
            let executor = DataExecutor(inMemory: true)
            self.executor = executor
            self.activeContainer = executor.container
            self.activeRepositories = RepositoryContainer(executor: executor)
            self.activeImageStorage = ImageStorage(baseDirectory: FileManager.default.temporaryDirectory)
            syncFallbackStatus()
            SnapDrillLogger.data.info("ProfileManager: in-memory 模式初始化完成")
            return
        }

        // 1. 执行首次升级迁移（必须在 ModelContainer 创建之前）
        ProfileMigration.migrateIfNeeded()

        // 2. 加载 Profile 列表（空时自动创建默认 Profile）
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var loadedProfiles = Self.loadProfiles(from: docs.appendingPathComponent("profiles.json"))
        if loadedProfiles.isEmpty {
            SnapDrillLogger.data.warning("ProfileManager: profiles.json 为空或不存在，创建默认 Profile")
            let fallback = Profile(name: "同学")
            loadedProfiles = [fallback]
        }
        self.profiles = loadedProfiles

        // 3. 确定活跃 Profile
        let savedId = UserDefaults.standard.string(forKey: UDKey.activeProfileId)
            .flatMap(UUID.init(uuidString:))
        let profileId = loadedProfiles.first(where: { $0.id == savedId })?.id
            ?? loadedProfiles.first?.id
            ?? UUID() // 防御性 fallback：loadedProfiles 上方已保证非空
        self.activeProfileId = profileId

        // 4. 创建活跃 Profile 的基础设施
        let profileDir = docs
            .appendingPathComponent("profiles")
            .appendingPathComponent(profileId.uuidString)

        let storeURL = profileDir.appendingPathComponent("default.store")
        let executor = DataExecutor(storeURL: storeURL)
        self.executor = executor
        self.activeContainer = executor.container
        self.activeRepositories = RepositoryContainer(executor: executor)
        self.activeImageStorage = ImageStorage(baseDirectory: profileDir)
        syncFallbackStatus()

        // 5. 加载 per-profile 偏好到 UserDefaults
        loadPreferences(for: profileId)

        let activeName = loadedProfiles.first(where: { $0.id == profileId })?.name ?? "unknown"
        SnapDrillLogger.data.info("ProfileManager: 初始化完成，活跃 Profile: \(activeName)")
    }

    // MARK: - Public API

    /// 当前活跃的 Profile
    public var activeProfile: Profile? {
        profiles.first(where: { $0.id == activeProfileId })
    }

    /// 切换到指定 Profile
    ///
    /// 切换前检查 `AppActivityTracker` 是否有进行中的操作，
    /// 有则抛出 `ProfileError.switchBlocked`。
    public func switchProfile(to profileId: UUID) throws(ProfileError) {
        guard !isInMemory else { return } // inMemory 模式不支持切换（会创建磁盘数据库）
        guard profileId != activeProfileId,
              profiles.contains(where: { $0.id == profileId }) else { return }

        // 中心状态机检查：有进行中的操作时阻止切换
        let tracker = AppActivityTracker.shared
        if let reason = tracker.switchBlockReason {
            throw .switchBlocked(reason: reason)
        }

        // 1. 保存当前 Profile 的偏好
        savePreferences(for: activeProfileId)

        // 2. 切换活跃 Profile
        let profileDir = profilesDirectoryURL.appendingPathComponent(profileId.uuidString)
        let storeURL = profileDir.appendingPathComponent("default.store")
        let executor = DataExecutor(storeURL: storeURL)

        self.executor = executor
        activeContainer = executor.container
        activeRepositories = RepositoryContainer(executor: executor)
        activeImageStorage = ImageStorage(baseDirectory: profileDir)
        syncFallbackStatus()

        // 3. 加载新 Profile 的偏好
        loadPreferences(for: profileId)

        // 4. 更新活跃 ID（触发 SwiftUI 视图树重建）
        activeProfileId = profileId
        UserDefaults.standard.set(profileId.uuidString, forKey: UDKey.activeProfileId)

        // 5. 初始化默认分类数据（新 Profile 首次使用时）
        activeRepositories.subject.seedDefaultsIfNeeded()
        activeRepositories.source.seedDefaultsIfNeeded()
        activeRepositories.grade.seedDefaultsIfNeeded()

        let switchedName = self.profiles.first(where: { $0.id == profileId })?.name ?? "unknown"
        SnapDrillLogger.data.info("ProfileManager: 已切换到 Profile: \(switchedName)")
    }

    /// 创建新 Profile
    @discardableResult
    public func createProfile(name: String) -> Profile? {
        let profile = Profile(name: name)
        profiles.append(profile)

        // 创建 Profile 目录（inMemory 模式跳过磁盘操作）
        if !isInMemory {
            let profileDir = profilesDirectoryURL.appendingPathComponent(profile.id.uuidString)
            do {
                try fileManager.createDirectory(at: profileDir, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: profileDir.appendingPathComponent("images"), withIntermediateDirectories: true)
            } catch {
                SnapDrillLogger.data.error("ProfileManager: Profile 目录创建失败，回滚: \(error.localizedDescription)")
                profiles.removeAll(where: { $0.id == profile.id })
                return nil
            }
        }

        // 保存默认偏好
        let defaults: [String: Any] = [
            UDKey.userName: name,
            UDKey.userAvatar: "person.crop.circle.fill",
            UDKey.userAvatarColorIndex: 0,
            UDKey.captureFieldSubject: true,
            UDKey.captureFieldSource: false,
            UDKey.captureFieldDifficulty: false,
            UDKey.captureFieldGrade: false,
            UDKey.captureFieldAnswer: false,
            UDKey.dailyReviewGoal: 10
        ]
        savePreferencesDict(defaults, for: profile.id)

        saveProfiles()
        return profile
    }

    /// 删除 Profile（禁止删除最后一个）
    ///
    /// Typed throws: 所有 throw 点都是 ProfileError（ADR D-001 "业务验证方法用 typed throws"）。
    /// - `cannotDeleteLastProfile`: 剩余 Profile 数 ≤ 1 时禁止删除
    /// - 内部 `switchProfile(to:)` 也 throws(ProfileError)，向上透传无需转换
    public func deleteProfile(id: UUID) throws(ProfileError) {
        guard profiles.count > 1 else {
            throw .cannotDeleteLastProfile
        }
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }

        // 如果删除的是当前活跃 Profile，必须先切换到其他 Profile
        if id == activeProfileId {
            guard let other = profiles.first(where: { $0.id != id }) else {
                throw .cannotDeleteLastProfile
            }
            if isInMemory {
                // inMemory: 直接更新 activeProfileId，不创建磁盘资源
                activeProfileId = other.id
            } else {
                try switchProfile(to: other.id)
            }
        }

        profiles.remove(at: index)
        saveProfiles()

        // 删除 Profile 目录（后台执行，inMemory 模式跳过）
        if !isInMemory {
            let profileDir = profilesDirectoryURL.appendingPathComponent(id.uuidString)
            Task.detached {
                try? FileManager.default.removeItem(at: profileDir) // best-effort: Profile 已从列表移除，目录删不掉不影响功能
            }
        }
    }

    /// 重命名 Profile
    public func renameProfile(id: UUID, newName: String) {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[index].name = newName
        saveProfiles()

        // 如果是当前活跃 Profile 且非 inMemory，同步更新 UserDefaults
        if id == activeProfileId, !isInMemory {
            UserDefaults.standard.set(newName, forKey: UDKey.userName)
        }
    }

    // MARK: - Preferences Sync

    /// 将 UserDefaults 中的 per-profile 值保存到 preferences.json
    private func savePreferences(for profileId: UUID) {
        guard !isInMemory else { return }
        let defaults = UserDefaults.standard
        var dict: [String: Any] = [:]
        for key in Self.perProfileKeys {
            if let value = defaults.object(forKey: key) {
                dict[key] = value
            }
        }
        savePreferencesDict(dict, for: profileId)
    }

    /// 从 preferences.json 加载 per-profile 值到 UserDefaults
    private func loadPreferences(for profileId: UUID) {
        let prefsURL = profilesDirectoryURL
            .appendingPathComponent(profileId.uuidString)
            .appendingPathComponent("preferences.json")

        let rawData: Data
        do {
            rawData = try Data(contentsOf: prefsURL)
        } catch {
            SnapDrillLogger.data.warning("ProfileManager: 偏好文件读取失败（可能首次使用）: \(error.localizedDescription)")
            return
        }
        let dict: [String: Any]
        do {
            guard let parsed = try JSONSerialization.jsonObject(with: rawData) as? [String: Any] else {
                SnapDrillLogger.data.warning("ProfileManager: 偏好 JSON 格式不是字典")
                return
            }
            dict = parsed
        } catch {
            SnapDrillLogger.data.warning("ProfileManager: 偏好 JSON 解析失败: \(error.localizedDescription)")
            return
        }

        let defaults = UserDefaults.standard
        for (key, value) in dict {
            defaults.set(value, forKey: key)
        }
    }

    /// 异步同步 executor 的降级状态到本地属性（供 SwiftUI 读取）
    private func syncFallbackStatus() {
        Task {
            let fallback = await executor.isUsingInMemoryFallback
            await MainActor.run {
                self.isUsingInMemoryFallback = fallback
            }
        }
    }

    private func savePreferencesDict(_ dict: [String: Any], for profileId: UUID) {
        guard !isInMemory else { return }
        let prefsURL = profilesDirectoryURL
            .appendingPathComponent(profileId.uuidString)
            .appendingPathComponent("preferences.json")

        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            try data.write(to: prefsURL)
        } catch {
            SnapDrillLogger.data.error("ProfileManager: 偏好保存失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Profile Persistence

    private func saveProfiles() {
        guard !isInMemory else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(profiles)
            try data.write(to: profilesFileURL)
        } catch {
            SnapDrillLogger.data.error("ProfileManager: profiles.json 保存失败: \(error.localizedDescription)")
        }
    }

    private static func loadProfiles(from url: URL) -> [Profile] {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            SnapDrillLogger.data.warning("ProfileManager: profiles.json 读取失败（可能首次启动）: \(error.localizedDescription)")
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode([Profile].self, from: data)
        } catch {
            SnapDrillLogger.data.error("ProfileManager: profiles.json 解码失败: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Errors

/// Profile 操作错误
public enum ProfileError: LocalizedError {
    case cannotDeleteLastProfile
    /// 有进行中的操作，无法切换 Profile
    case switchBlocked(reason: String)

    public var errorDescription: String? {
        switch self {
        case .cannotDeleteLastProfile:
            return "无法删除最后一个学习者"
        case .switchBlocked(let reason):
            return "无法切换：\(reason)"
        }
    }
}
