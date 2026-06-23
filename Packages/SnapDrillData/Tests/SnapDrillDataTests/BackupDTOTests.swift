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
                ReviewItemBackupDTO(
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

    @Test("ReviewItemBackupDTO nil content/answerText + 空 categoryValueIds 正确序列化")
    func nilFieldsSerialization() throws {
        let item = ReviewItemBackupDTO(
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
        let decoded = try JSONDecoder().decode(ReviewItemBackupDTO.self, from: data)

        #expect(decoded.content == nil)
        #expect(decoded.answerText == nil)
        #expect(decoded.answerImagePath == nil)
        #expect(decoded.categoryValueIds.isEmpty)
    }
}
