//
//  ProfileTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Profile 模型和 ProfileError 测试。
//

import Testing
import Foundation
@testable import SnapDrillData
@testable import SnapDrillCore

// MARK: - Profile Model Tests

@Suite("Profile 模型")
struct ProfileModelTests {

    @Test("创建 Profile 默认值正确")
    func defaultValues() {
        let profile = Profile(name: "小明")
        #expect(profile.name == "小明")
        #expect(profile.avatar == "person.crop.circle.fill")
        #expect(profile.avatarColorIndex == 0)
        #expect(profile.createdAt <= Date())
    }

    @Test("自定义属性初始化")
    func customInit() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_000_000)
        let profile = Profile(
            id: id,
            name: "小红",
            avatar: "star.fill",
            avatarColorIndex: 3,
            createdAt: date
        )
        #expect(profile.id == id)
        #expect(profile.name == "小红")
        #expect(profile.avatar == "star.fill")
        #expect(profile.avatarColorIndex == 3)
        #expect(profile.createdAt == date)
    }

    @Test("JSON 序列化往返")
    func codableRoundTrip() throws {
        // iso8601 截断亚秒精度，用整秒时间戳避免 round-trip 精度丢失
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let original = Profile(name: "测试用户", avatar: "heart.fill", avatarColorIndex: 2, createdAt: fixedDate)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Profile.self, from: data)

        #expect(decoded == original)
    }

    @Test("JSON 数组序列化往返")
    func codableArrayRoundTrip() throws {
        let profiles = [
            Profile(name: "小明"),
            Profile(name: "小红", avatar: "star.fill", avatarColorIndex: 1),
            Profile(name: "小刚", avatarColorIndex: 5)
        ]

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(profiles)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode([Profile].self, from: data)

        #expect(decoded.count == 3)
        #expect(decoded[0].name == "小明")
        #expect(decoded[1].name == "小红")
        #expect(decoded[2].name == "小刚")
    }

    @Test("Equatable 行为正确")
    func equatable() {
        let id = UUID()
        let date = Date()
        let profileA = Profile(id: id, name: "Test", createdAt: date)
        let profileB = Profile(id: id, name: "Test", createdAt: date)
        let profileC = Profile(name: "Test") // 不同 id

        #expect(profileA == profileB)
        #expect(profileA != profileC)
    }

    @Test("name 可变更")
    func mutableName() {
        var profile = Profile(name: "旧名字")
        profile.name = "新名字"
        #expect(profile.name == "新名字")
    }
}

// MARK: - ProfileError Tests

@Suite("ProfileError 错误处理")
struct ProfileErrorTests {

    @Test("cannotDeleteLastProfile 提供本地化描述")
    func errorDescription() throws {
        let error = ProfileError.cannotDeleteLastProfile
        let description = try #require(error.errorDescription)
        #expect(!description.isEmpty)
    }

    @Test("cannotDeleteLastProfile 是 LocalizedError")
    func conformsToLocalizedError() {
        let error: any LocalizedError = ProfileError.cannotDeleteLastProfile
        #expect(error.errorDescription != nil)
    }

    // MARK: - Typed throws 行为（ADR D-001 / Phase 2 PR #6）

    @Test("deleteProfile 删除最后一个 Profile 抛 typed ProfileError.cannotDeleteLastProfile")
    @MainActor
    func deleteLastProfile_throwsTypedProfileError() async {
        let manager = ProfileManager(inMemory: true)
        guard let onlyProfile = manager.profiles.first else {
            Issue.record("inMemory ProfileManager 应有默认 Profile")
            return
        }

        // Typed throws 核心价值：catch block 的 error 静态类型由编译器推断为 ProfileError，
        // enum case 可直接 pattern-match（无需 `catch let e as ProfileError`）。
        do {
            try await manager.deleteProfile(id: onlyProfile.id)
            Issue.record("deleteProfile 应当抛出 cannotDeleteLastProfile")
        } catch .cannotDeleteLastProfile {
            // 预期路径
        } catch {
            Issue.record("Unexpected ProfileError case: \(error)")
        }
    }

    @Test("inMemory 删除活跃 Profile 时重建 active scope 和 repositories")
    @MainActor
    func deleteActiveProfile_rebuildsInMemoryScopeAndRepositories() async throws {
        let manager = ProfileManager(inMemory: true)
        let originalId = manager.activeProfileId
        let nextProfile = try #require(manager.createProfile(name: "Next"))

        try await manager.deleteProfile(id: originalId)

        #expect(manager.activeProfileId == nextProfile.id)
        #expect(manager.activeScope?.id == nextProfile.id)
        #expect(manager.activeRepositories.scope.id == nextProfile.id)
    }
}

@Suite("ProfileManager per-profile preferences")
struct ProfileManagerPreferenceTests {

    @Test("切换 Profile 前清理 per-profile keys，避免草稿 metadata 串档")
    func clearPerProfileValues_removesDraftMetadataAndDynamicVisibilityOnly() throws {
        let suiteName = "ProfileManagerPreferenceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(Data("draft".utf8), forKey: UDKey.captureDraftMetadata)
        defaults.set(true, forKey: UDKey.captureFieldCategory)
        defaults.set(true, forKey: "\(CategoryDimensionModel.visibilityKeyPrefix)test")
        defaults.set("keep", forKey: "unrelated.global.key")

        ProfileManager.clearPerProfileValues(in: defaults)

        #expect(defaults.object(forKey: UDKey.captureDraftMetadata) == nil)
        #expect(defaults.object(forKey: UDKey.captureFieldCategory) == nil)
        #expect(defaults.object(forKey: "\(CategoryDimensionModel.visibilityKeyPrefix)test") == nil)
        #expect(defaults.string(forKey: "unrelated.global.key") == "keep")
    }
}
