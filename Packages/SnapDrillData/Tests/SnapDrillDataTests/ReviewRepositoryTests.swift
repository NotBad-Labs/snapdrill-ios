//
//  ReviewRepositoryTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ReviewRepository CRUD / 边界 / 并发 单元测试。
//

import Testing
import SwiftData
import Foundation
import SnapDrillCore
@testable import SnapDrillData

@Suite("ReviewRepository 单元测试")
@MainActor
struct ReviewRepositoryTests {

    // MARK: - Helpers

    private func createTestRepository() throws -> ReviewRepository {
        let schema = Schema([
            ReviewItemModel.self,
            TagModel.self,
            SubjectModel.self,
            SourceModel.self,
            GradeModel.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ReviewRepository(modelContext: container.mainContext)
    }

    private func makeDummyModel(
        id: UUID = UUID(),
        content: String? = "Test"
    ) -> ReviewItemModel {
        ReviewItemModel(
            id: id,
            content: content,
            imagePath: nil,
            subject: "数学",
            source: "试卷",
            answerText: "测试答案",
            difficulty: 3,
            grade: "高一"
        )
    }

    // MARK: - 基础 CRUD

    @Test("正常保存、Upsert 与删除流程")
    func basicCRUDFlow() throws {
        let repo = try createTestRepository()

        let id = UUID()
        let model = makeDummyModel(id: id, content: "First")

        // 新增
        try repo.insertAndSave(model)
        #expect(try repo.totalItemCount() == 1)

        // 读取
        let fetched = try repo.fetchModel(by: id)
        #expect(fetched?.content == "First")

        // 直接修改属性并保存 = Upsert（更新），不新增
        fetched?.content = "Updated"
        try repo.saveContext()
        #expect(try repo.totalItemCount() == 1)

        let fetchedUpdated = try repo.fetchModel(by: id)
        #expect(fetchedUpdated?.content == "Updated")

        // 删除
        try repo.delete(id: id)
        #expect(try repo.totalItemCount() == 0)
    }

    // MARK: - 边界与复杂查询

    @Test("fetchDueCount 在不同时间轴边缘的统计正确性")
    func nextReviewAtBoundaryCounting() throws {
        let repo = try createTestRepository()

        let now = Date()
        let past = now.addingTimeInterval(-3600)
        let future = now.addingTimeInterval(3600)

        let overdueItem1 = makeDummyModel()
        overdueItem1.nextReviewAt = past
        try repo.insertAndSave(overdueItem1)

        let overdueItem2 = makeDummyModel()
        overdueItem2.nextReviewAt = past
        try repo.insertAndSave(overdueItem2)

        let futureItem = makeDummyModel()
        futureItem.nextReviewAt = future
        try repo.insertAndSave(futureItem)

        // nextReviewAt == nil → 视为待复习（从未复习过）
        let nilItem = makeDummyModel()
        nilItem.nextReviewAt = nil
        try repo.insertAndSave(nilItem)

        // 过去 2 条 + nil 1 条（epoch < now）= 3
        let dueCount = try repo.fetchDueCount()
        #expect(dueCount == 3)
    }

    // MARK: - 年级统计与级联更新

    @Test("countByGrade 统计与 updateGradeUsage 级联更新")
    func gradeCountAndCascadeUpdate() throws {
        let repo = try createTestRepository()

        let item1 = makeDummyModel()
        item1.grade = "高一"
        try repo.insertAndSave(item1)

        let item2 = makeDummyModel()
        item2.grade = "高一"
        try repo.insertAndSave(item2)

        let item3 = makeDummyModel()
        item3.grade = "高二"
        try repo.insertAndSave(item3)

        #expect(try repo.countByGrade(name: "高一") == 2)
        #expect(try repo.countByGrade(name: "高二") == 1)

        // 级联重命名
        try repo.updateGradeUsage(from: "高一", to: "高三")
        #expect(try repo.countByGrade(name: "高一") == 0)
        #expect(try repo.countByGrade(name: "高三") == 2)
    }

    // MARK: - 学科统计与级联更新

    @Test("countBySubject 统计与 updateSubjectUsage 级联更新")
    func subjectCountAndCascadeUpdate() throws {
        let repo = try createTestRepository()

        let item1 = makeDummyModel()
        item1.subjectRawValue = "数学"
        try repo.insertAndSave(item1)

        let item2 = makeDummyModel()
        item2.subjectRawValue = "物理"
        try repo.insertAndSave(item2)

        #expect(try repo.countBySubject(name: "数学") == 1)

        try repo.updateSubjectUsage(from: "数学", to: "高数")
        #expect(try repo.countBySubject(name: "数学") == 0)
        #expect(try repo.countBySubject(name: "高数") == 1)
    }

    // MARK: - 并发防线测试

    @Test("高并发写入下的仓库可靠性（50 个并发任务）")
    func concurrentInsertReliability() async throws {
        let repo = try createTestRepository()
        let itemCount = 50

        // 所有 Task 都调度到 MainActor 串行执行，验证无竞态崩溃
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<itemCount {
                group.addTask {
                    await MainActor.run {
                        let model = self.makeDummyModel(content: "Concurrent \(i)")
                        try? repo.insertAndSave(model)
                    }
                }
            }
        }

        let count = try repo.totalItemCount()
        #expect(count == itemCount)
    }

    // MARK: - 极值测试

    @Test("content 为 nil 时依然可以保存（有 imagePath 的场景）")
    func nilContentWithImagePath() throws {
        let repo = try createTestRepository()
        let model = makeDummyModel(content: nil)

        try repo.insertAndSave(model)
        #expect(try repo.totalItemCount() == 1)

        let fetched = try repo.fetchModel(by: model.id)
        #expect(fetched?.content == nil)
    }

    @Test("difficulty rawValue 正确持久化与读取")
    func difficultyRawValueRoundTrip() throws {
        let repo = try createTestRepository()

        let model = makeDummyModel()
        model.difficulty = Difficulty.five.rawValue
        try repo.insertAndSave(model)

        let fetched = try repo.fetchModel(by: model.id)
        #expect(fetched?.difficulty == Difficulty.five.rawValue)
    }
}
