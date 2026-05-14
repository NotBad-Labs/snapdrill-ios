//
//  BackupDTOTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  BackupPayload / BackupManifest JSON 序列化 round-trip 测试。
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

    // MARK: - BackupPayload

    private static let testProfileId = UUID()

    /// 构造全字段 Payload 用于 round-trip 测试
    private func makeFullPayload() -> (payload: BackupPayload, itemID: UUID) {
        let itemID = UUID()
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
                    subject: "数学",
                    source: "期中模拟卷",
                    tagNames: ["易错", "几何"],
                    answerText: "证明过程...",
                    answerImagePath: "images/answer_\(itemID).jpg",
                    difficulty: 4,
                    grade: "初三",
                    easeFactor: 2.6,
                    interval: 3,
                    repetitions: 2
                )
            ],
            subjects: [SubjectBackupDTO(id: UUID(), name: "数学", icon: "function", colorHex: "#FF5733", sortOrder: 0)],
            sources: [SourceBackupDTO(id: UUID(), name: "期中模拟卷", icon: "doc.text", colorHex: "#007AFF", sortOrder: 1)],
            grades: [GradeBackupDTO(id: UUID(), name: "初三", sortOrder: 3)],
            tags: [TagBackupDTO(id: UUID(), name: "易错", colorHex: "#FF0000")]
        )
        let payload = BackupPayload(profiles: [profileData])
        return (payload, itemID)
    }

    @Test("BackupPayload 全字段 round-trip")
    func payloadFullRoundTrip() throws {
        let (payload, itemID) = makeFullPayload()

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
        #expect(item.subject == "数学")
        #expect(item.source == "期中模拟卷")
        #expect(item.tagNames == ["易错", "几何"])
        #expect(item.answerText == "证明过程...")
        #expect(item.difficulty == 4)
        #expect(item.grade == "初三")
        #expect(item.easeFactor == 2.6)
        #expect(item.interval == 3)
        #expect(item.repetitions == 2)

        #expect(profile.subjects[0].name == "数学")
        #expect(profile.subjects[0].icon == "function")
        #expect(profile.sources[0].name == "期中模拟卷")
        #expect(profile.grades[0].name == "初三")
        #expect(profile.tags[0].name == "易错")
    }

    @Test("ReviewItemBackupDTO 缺失字段使用默认值（前向兼容）")
    func reviewItemMissingFieldsUseDefaults() throws {
        let json = """
        {"id": "550E8400-E29B-41D4-A716-446655440000"}
        """
        let data = Data(json.utf8)
        let item = try JSONDecoder().decode(ReviewItemBackupDTO.self, from: data)

        #expect(item.id == UUID(uuidString: "550E8400-E29B-41D4-A716-446655440000"))
        #expect(item.content == nil)
        #expect(item.imagePath == nil)
        #expect(item.subject == "其他")
        #expect(item.source == "其他")
        #expect(item.tagNames == [])
        #expect(item.difficulty == 1)
        #expect(item.grade == "")
        #expect(item.easeFactor == 2.5)
        #expect(item.interval == 0)
        #expect(item.repetitions == 0)
    }

    @Test("SubjectBackupDTO 缺失可选字段使用默认值")
    func subjectMissingFieldsUseDefaults() throws {
        let json = """
        {"id": "550E8400-E29B-41D4-A716-446655440001", "name": "物理"}
        """
        let data = Data(json.utf8)
        let subject = try JSONDecoder().decode(SubjectBackupDTO.self, from: data)

        #expect(subject.name == "物理")
        #expect(subject.icon == "book.fill")
        #expect(subject.colorHex == "#007AFF")
        #expect(subject.sortOrder == 0)
    }

    @Test("空 Payload round-trip")
    func emptyPayloadRoundTrip() throws {
        let emptyProfile = ProfileBackupData(
            profileName: "空",
            profileId: UUID(),
            reviewItems: [],
            subjects: [],
            sources: [],
            grades: [],
            tags: []
        )
        let payload = BackupPayload(profiles: [emptyProfile])

        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(BackupPayload.self, from: data)

        #expect(decoded.profiles[0].reviewItems.isEmpty)
        #expect(decoded.profiles[0].subjects.isEmpty)
        #expect(decoded.profiles[0].sources.isEmpty)
        #expect(decoded.profiles[0].grades.isEmpty)
        #expect(decoded.profiles[0].tags.isEmpty)
    }

    @Test("ReviewItemBackupDTO nil content 和 nil answerText 正确序列化")
    func nilFieldsSerialization() throws {
        let item = ReviewItemBackupDTO(
            id: UUID(),
            content: nil,
            imagePath: nil,
            createdAt: .distantPast,
            lastReviewedAt: .distantPast,
            nextReviewAt: .distantPast,
            subject: "数学",
            source: "其他",
            tagNames: [],
            answerText: nil,
            answerImagePath: nil,
            difficulty: 1,
            grade: "",
            easeFactor: 2.5,
            interval: 0,
            repetitions: 0
        )

        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ReviewItemBackupDTO.self, from: data)

        #expect(decoded.content == nil)
        #expect(decoded.answerText == nil)
        #expect(decoded.answerImagePath == nil)
    }
}
