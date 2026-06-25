//
//  BackupDTOTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  BackupPayload / BackupManifest JSON 序列化 round-trip 测试（L3 动态维度基线）。
//

import Testing
import Foundation
@testable import SnapDrillData

@Suite("BackupDTO 序列化测试")
struct BackupDTOTests {

    // MARK: - Golden Wire Fixtures

    private static let fixtureDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/BackupWireV2")

    private static let profileId = fixedUUID("11111111-1111-1111-1111-111111111111")
    private static let itemId = fixedUUID("22222222-2222-2222-2222-222222222222")
    private static let dimensionId = fixedUUID("33333333-3333-3333-3333-333333333333")
    private static let valueId = fixedUUID("44444444-4444-4444-4444-444444444444")
    private static let emptyProfileId = fixedUUID("55555555-5555-5555-5555-555555555555")

    private static func fixedUUID(_ value: String) -> UUID {
        guard let uuid = UUID(uuidString: value) else {
            fatalError("Invalid fixed UUID fixture value: \(value)")
        }
        return uuid
    }

    private func canonicalEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private func canonicalDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func fixtureString(named name: String) throws -> String {
        let url = Self.fixtureDirectory.appendingPathComponent(name)
        let data = try Data(contentsOf: url)
        guard let string = String(bytes: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func canonicalString<T: Encodable>(_ value: T) throws -> String {
        let data = try canonicalEncoder().encode(value)
        guard let string = String(bytes: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return string
    }

    private func goldenManifest() -> BackupManifest {
        BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(timeIntervalSince1970: 1_704_067_200),
            appVersion: "1.0.0",
            totalItemCount: 1,
            profileCount: 1,
            profileNames: ["Default"]
        )
    }

    private func goldenPayload() -> BackupPayload {
        let profileData = ProfileBackupData(
            profileName: "Default",
            profileId: Self.profileId,
            reviewItems: [
                ArchiveItemBackupDTO(
                    id: Self.itemId,
                    content: "Reference item",
                    imagePath: "images/22222222-2222-2222-2222-222222222222.jpg",
                    createdAt: Date(timeIntervalSince1970: 1_704_067_200),
                    lastReviewedAt: Date(timeIntervalSince1970: 1_704_153_600),
                    nextReviewAt: Date(timeIntervalSince1970: 1_704_672_000),
                    answerText: "Reference answer",
                    answerImagePath: nil,
                    easeFactor: 2.5,
                    interval: 6,
                    repetitions: 2,
                    categoryValueIds: [Self.valueId]
                )
            ],
            dimensions: [
                CategoryDimensionBackupDTO(
                    id: Self.dimensionId,
                    name: "Category",
                    isMultiValue: false,
                    isBuiltIn: true,
                    systemKey: CategorySystemKey.category,
                    sortOrder: 0,
                    icon: "tray.full"
                )
            ],
            categoryValues: [
                CategoryValueBackupDTO(
                    id: Self.valueId,
                    name: "Reference",
                    icon: "doc.text",
                    colorHex: "#3366FF",
                    sortOrder: 0,
                    createdAt: Date(timeIntervalSince1970: 1_704_067_200),
                    dimensionId: Self.dimensionId
                )
            ]
        )
        return BackupPayload(profiles: [profileData])
    }

    private func emptyGoldenPayload() -> BackupPayload {
        BackupPayload(
            profiles: [
                ProfileBackupData(
                    profileName: "Empty",
                    profileId: Self.emptyProfileId,
                    reviewItems: [],
                    dimensions: [],
                    categoryValues: []
                )
            ]
        )
    }

    // MARK: - BackupManifest

    @Test("BackupManifest JSON round-trip")
    func manifestRoundTrip() throws {
        let original = BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(timeIntervalSince1970: 1_710_000_000),
            appVersion: "1.1.0",
            totalItemCount: 42,
            profileCount: 2,
            profileNames: ["默认", "小明"]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BackupManifest.self, from: data)

        #expect(decoded.schemaVersion == original.schemaVersion)
        #expect(decoded.appVersion == original.appVersion)
        #expect(decoded.totalItemCount == original.totalItemCount)
        #expect(decoded.profileCount == original.profileCount)
        #expect(decoded.profileNames == original.profileNames)
        #expect(decoded.createdAt == original.createdAt)
    }

    @Test("currentSchemaVersion 标记静态 difficulty 删除后的备份边界")
    func schemaVersionIsResetBaseline() {
        #expect(BackupManifest.currentSchemaVersion == 2)
    }

    @Test("BackupManifest v2 golden wire JSON")
    func manifestGoldenWireJSON() throws {
        let fixture = try fixtureString(named: "manifest.json")
        let encoded = try canonicalString(goldenManifest())
        let decoded = try canonicalDecoder().decode(
            BackupManifest.self,
            from: Data(fixture.utf8)
        )

        #expect(encoded == fixture)
        #expect(decoded.schemaVersion == 2)
        #expect(decoded.profileNames == ["Default"])
    }

    // MARK: - BackupPayload

    private static let testProfileId = UUID()
    private static let testItemID = UUID()
    private static let testDimensionID = UUID()
    private static let testValueID = UUID()

    /// 构造全字段 Payload 用于 round-trip 测试（动态维度）
    private func makeFullPayload() -> BackupPayload {
        let itemID = Self.testItemID
        let dimensionID = Self.testDimensionID
        let valueID = Self.testValueID
        let profileData = ProfileBackupData(
            profileName: "默认",
            profileId: Self.testProfileId,
            reviewItems: [
                ArchiveItemBackupDTO(
                    id: itemID,
                    content: "已知 △ABC 中 AB=AC",
                    imagePath: "images/\(itemID).jpg",
                    createdAt: Date(timeIntervalSince1970: 1_710_000_000),
                    lastReviewedAt: Date(timeIntervalSince1970: 1_710_100_000),
                    nextReviewAt: Date(timeIntervalSince1970: 1_710_200_000),
                    answerText: "证明过程...",
                    answerImagePath: "images/answer_\(itemID).jpg",
                    easeFactor: 2.6,
                    interval: 3,
                    repetitions: 2,
                    categoryValueIds: [valueID]
                )
            ],
            dimensions: [
                CategoryDimensionBackupDTO(
                    id: dimensionID, name: "分类", isMultiValue: false, isBuiltIn: true,
                    systemKey: CategorySystemKey.category, sortOrder: 0, icon: "book"
                )
            ],
            categoryValues: [
                CategoryValueBackupDTO(
                    id: valueID, name: "数学", icon: "function", colorHex: "#FF5733",
                    sortOrder: 0, createdAt: Date(timeIntervalSince1970: 1_710_000_000), dimensionId: dimensionID
                )
            ]
        )
        return BackupPayload(profiles: [profileData])
    }

    @Test("BackupPayload 全字段 round-trip")
    func payloadFullRoundTrip() throws {
        let payload = makeFullPayload()
        let itemID = Self.testItemID
        let valueID = Self.testValueID

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(payload)
        let decoded = try decoder.decode(BackupPayload.self, from: data)

        let profile = decoded.profiles[0]
        let item = profile.reviewItems[0]
        #expect(item.id == itemID)
        #expect(item.content == "已知 △ABC 中 AB=AC")
        #expect(item.categoryValueIds == [valueID])
        #expect(item.answerText == "证明过程...")
        #expect(item.easeFactor == 2.6)
        #expect(item.interval == 3)
        #expect(item.repetitions == 2)

        #expect(profile.dimensions[0].name == "分类")
        #expect(profile.dimensions[0].systemKey == CategorySystemKey.category)
        #expect(profile.categoryValues[0].name == "数学")
        #expect(profile.categoryValues[0].dimensionId == profile.dimensions[0].id)
    }

    @Test("BackupPayload v2 golden wire JSON preserves reviewItems key")
    func payloadGoldenWireJSONPreservesReviewItemsKey() throws {
        let fixture = try fixtureString(named: "data.json")
        let encoded = try canonicalString(goldenPayload())
        let decoded = try canonicalDecoder().decode(
            BackupPayload.self,
            from: Data(fixture.utf8)
        )

        #expect(encoded == fixture)
        #expect(fixture.contains(#""reviewItems""#))
        #expect(!fixture.contains(#""archiveItems""#))
        #expect(decoded.profiles[0].profileId == Self.profileId)
        #expect(decoded.profiles[0].reviewItems[0].id == Self.itemId)
        #expect(decoded.profiles[0].reviewItems[0].categoryValueIds == [Self.valueId])
        #expect(decoded.profiles[0].dimensions[0].systemKey == CategorySystemKey.category)
        #expect(decoded.profiles[0].categoryValues[0].dimensionId == Self.dimensionId)
    }

    @Test("BackupPayload v2 empty profile golden JSON keeps empty reviewItems")
    func emptyPayloadGoldenWireJSONKeepsReviewItems() throws {
        let fixture = try fixtureString(named: "data-empty.json")
        let decodedFixture = try canonicalDecoder().decode(
            BackupPayload.self,
            from: Data(fixture.utf8)
        )
        let fixtureCanonical = try canonicalString(decodedFixture)
        let encoded = try canonicalString(emptyGoldenPayload())

        #expect(encoded == fixtureCanonical)
        #expect(fixture.contains(#""reviewItems""#))
        #expect(!fixture.contains(#""archiveItems""#))
        #expect(decodedFixture.profiles[0].reviewItems.isEmpty)
        #expect(decodedFixture.profiles[0].dimensions.isEmpty)
        #expect(decodedFixture.profiles[0].categoryValues.isEmpty)
    }

    @Test("空 Payload round-trip")
    func emptyPayloadRoundTrip() throws {
        let emptyProfile = ProfileBackupData(
            profileName: "空",
            profileId: UUID(),
            reviewItems: [],
            dimensions: [],
            categoryValues: []
        )
        let payload = BackupPayload(profiles: [emptyProfile])

        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(BackupPayload.self, from: data)

        #expect(decoded.profiles[0].reviewItems.isEmpty)
        #expect(decoded.profiles[0].dimensions.isEmpty)
        #expect(decoded.profiles[0].categoryValues.isEmpty)
    }

    @Test("ArchiveItemBackupDTO nil content/answerText + 空 categoryValueIds 正确序列化")
    func nilFieldsSerialization() throws {
        let item = ArchiveItemBackupDTO(
            id: UUID(),
            content: nil,
            imagePath: nil,
            createdAt: .distantPast,
            lastReviewedAt: .distantPast,
            nextReviewAt: .distantPast,
            answerText: nil,
            answerImagePath: nil,
            easeFactor: 2.5,
            interval: 0,
            repetitions: 0,
            categoryValueIds: []
        )

        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ArchiveItemBackupDTO.self, from: data)

        #expect(decoded.content == nil)
        #expect(decoded.answerText == nil)
        #expect(decoded.answerImagePath == nil)
        #expect(decoded.categoryValueIds.isEmpty)
    }
}
