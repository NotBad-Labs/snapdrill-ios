//
//  RepositoryContainerBackupTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs on 2026/03/13.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  RepositoryContainer 的 collectBackupPayload / restoreFromPayload round-trip 测试。
//

import Testing
import SwiftData
import Foundation
import SnapDrillCore
@testable import SnapDrillData

@Suite("RepositoryContainer 备份/恢复测试")
@MainActor
struct RepositoryContainerBackupTests {

    // MARK: - Helpers

    private func createTestContainer() throws -> RepositoryContainer {
        let container = try TestModelContainer.create()
        return RepositoryContainer(modelContext: container.mainContext)
    }

    // MARK: - collectBackupPayload

    @Test("collectBackupPayload 正确收集全量数据")
    func collectPayloadBasic() throws {
        let repos = try createTestContainer()

        // 插入测试数据
        let subject = SubjectModel.mock(name: "数学")
        repos.subject.insert(subject)
        let source = SourceModel.mock(name: "期中卷")
        repos.source.insert(source)
        let grade = GradeModel.mock(name: "初三")
        repos.grade.insert(grade)

        let tag = try repos.tag.fetchOrCreateModel(name: "易错", colorHex: "#FF0000")

        let item = ReviewItemModel.mock(content: "测试题", subject: "数学", source: "期中卷")
        item.grade = "初三"
        item.tags = [tag]
        item.answerText = "答案文本"
        item.difficulty = 4
        repos.review.insert(item)

        try repos.review.saveContext()

        // 收集 payload
        let payload = try repos.collectBackupPayload()

        #expect(payload.reviewItems.count == 1)
        #expect(payload.reviewItems[0].content == "测试题")
        #expect(payload.reviewItems[0].subject == "数学")
        #expect(payload.reviewItems[0].source == "期中卷")
        #expect(payload.reviewItems[0].grade == "初三")
        #expect(payload.reviewItems[0].tagNames == ["易错"])
        #expect(payload.reviewItems[0].answerText == "答案文本")
        #expect(payload.reviewItems[0].difficulty == 4)

        #expect(payload.subjects.count >= 1)
        #expect(payload.subjects.contains(where: { $0.name == "数学" }))
        #expect(payload.sources.contains(where: { $0.name == "期中卷" }))
        #expect(payload.grades.contains(where: { $0.name == "初三" }))
        #expect(payload.tags.contains(where: { $0.name == "易错" }))
    }

    @Test("空数据库 collectBackupPayload 返回空 Payload")
    func collectPayloadEmpty() throws {
        let repos = try createTestContainer()
        let payload = try repos.collectBackupPayload()

        #expect(payload.reviewItems.isEmpty)
        #expect(payload.subjects.isEmpty)
        #expect(payload.sources.isEmpty)
        #expect(payload.grades.isEmpty)
        #expect(payload.tags.isEmpty)
    }

    // MARK: - restoreFromPayload

    @Test("restoreFromPayload 全量恢复 round-trip")
    func restorePayloadRoundTrip() async throws {
        let repos = try createTestContainer()

        // 插入原始数据
        let tag = try repos.tag.fetchOrCreateModel(name: "考前必看", colorHex: "#00FF00")
        let item = ReviewItemModel.mock(content: "原始题目", subject: "英语", source: "听力")
        item.tags = [tag]
        item.answerText = "A"
        item.grade = "高二"
        item.difficulty = 2
        item.easeFactor = 2.8
        item.interval = 5
        item.repetitions = 3
        repos.review.insert(item)
        try repos.review.saveContext()

        // 收集 payload
        let payload = try repos.collectBackupPayload()

        // 清空数据库（模拟恢复前状态）
        try repos.review.deleteAll()
        try repos.subject.deleteAll()
        try repos.source.deleteAll()
        try repos.grade.deleteAll()
        try repos.tag.deleteAll()
        try repos.review.saveContext()
        #expect(try repos.review.totalCount() == 0)

        // 恢复
        try await repos.restoreFromPayload(payload)

        // 验证恢复结果
        let restoredItems = try repos.review.fetchAllModels()
        #expect(restoredItems.count == 1)
        let restored = restoredItems[0]
        #expect(restored.content == "原始题目")
        #expect(restored.subject == "英语")
        #expect(restored.source == "听力")
        #expect(restored.grade == "高二")
        #expect(restored.answerText == "A")
        #expect(restored.difficulty == 2)
        #expect(restored.easeFactor == 2.8)
        #expect(restored.interval == 5)
        #expect(restored.repetitions == 3)
        #expect(restored.tags?.first?.name == "考前必看")

        // 验证分类数据恢复
        let subjects = try repos.subject.fetchAllModels()
        #expect(subjects.contains(where: { $0.name == "英语" }))
    }

    @Test("restoreFromPayload 替换已有数据")
    func restoreReplacesExistingData() async throws {
        let repos = try createTestContainer()

        // 插入旧数据
        let oldItem = ReviewItemModel.mock(content: "旧题目", subject: "数学")
        repos.review.insert(oldItem)
        try repos.review.saveContext()
        #expect(try repos.review.totalCount() == 1)

        // 准备新 payload
        let newPayload = BackupPayload(
            reviewItems: [
                ReviewItemBackupDTO(
                    id: UUID(), content: "新题目 A", imagePath: nil,
                    createdAt: Date(), lastReviewedAt: .distantPast, nextReviewAt: .distantPast,
                    subject: "物理", source: "其他", tagNames: [], answerText: nil,
                    answerImagePath: nil, difficulty: 1, grade: "", easeFactor: 2.5,
                    interval: 0, repetitions: 0
                ),
                ReviewItemBackupDTO(
                    id: UUID(), content: "新题目 B", imagePath: nil,
                    createdAt: Date(), lastReviewedAt: .distantPast, nextReviewAt: .distantPast,
                    subject: "化学", source: "其他", tagNames: ["重点"], answerText: nil,
                    answerImagePath: nil, difficulty: 3, grade: "高一", easeFactor: 2.5,
                    interval: 0, repetitions: 0
                )
            ],
            subjects: [SubjectBackupDTO(id: UUID(), name: "物理", icon: "bolt", colorHex: "#FF0000", sortOrder: 0)],
            sources: [],
            grades: [GradeBackupDTO(id: UUID(), name: "高一", sortOrder: 0)],
            tags: [TagBackupDTO(id: UUID(), name: "重点", colorHex: "#00FF00")]
        )

        // 恢复（应替换旧数据）
        try await repos.restoreFromPayload(newPayload)

        let items = try repos.review.fetchAllModels()
        #expect(items.count == 2)
        #expect(items.contains(where: { $0.content == "新题目 A" }))
        #expect(items.contains(where: { $0.content == "新题目 B" }))
        // 旧题目应被清除
        #expect(!items.contains(where: { $0.content == "旧题目" }))
    }

    @Test("restoreFromPayload 标签关联正确恢复")
    func restoreTagAssociations() async throws {
        let repos = try createTestContainer()

        let payload = BackupPayload(
            reviewItems: [
                ReviewItemBackupDTO(
                    id: UUID(), content: "多标签题目", imagePath: nil,
                    createdAt: Date(), lastReviewedAt: .distantPast, nextReviewAt: .distantPast,
                    subject: "数学", source: "其他", tagNames: ["易错", "高频", "考前"],
                    answerText: nil, answerImagePath: nil, difficulty: 1, grade: "",
                    easeFactor: 2.5, interval: 0, repetitions: 0
                )
            ],
            subjects: [],
            sources: [],
            grades: [],
            tags: [
                TagBackupDTO(id: UUID(), name: "易错", colorHex: "#FF0000"),
                TagBackupDTO(id: UUID(), name: "高频", colorHex: "#00FF00"),
                TagBackupDTO(id: UUID(), name: "考前", colorHex: "#0000FF")
            ]
        )

        try await repos.restoreFromPayload(payload)

        let items = try repos.review.fetchAllModels()
        #expect(items.count == 1)
        let tagNames = items[0].tags?.map(\.name).sorted() ?? []
        #expect(tagNames == ["考前", "易错", "高频"].sorted())
    }
}
