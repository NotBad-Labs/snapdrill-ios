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
import SnapDrillDomain
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

    private func makeDummyCoreItem(id: UUID = UUID(), content: String? = "Test") -> ReviewItem {
        ReviewItem(
            id: id,
            content: content,
            imagePath: nil,
            createdAt: Date(),
            lastReviewedAt: nil,
            nextReviewAt: nil,
            subject: "数学",
            source: "试卷",
            tags: [],
            answerText: "测试答案",
            answerImagePath: nil,
            difficulty: .three,
            grade: "高一"
        )
    }

    // MARK: - 基础 CRUD

    @Test("正常保存、Upsert 与删除流程")
    func basicCRUDFlow() throws {
        let repo = try createTestRepository()

        let id = UUID()
        let item = makeDummyCoreItem(id: id, content: "First")

        // 新增
        try repo.save(item)
        #expect(try repo.totalItemCount() == 1)

        // 读取
        let fetched = try repo.fetchById(id)
        #expect(fetched?.content == "First")

        // 同 UUID 再次保存 = Upsert（更新），不新增
        var updated = item
        updated.content = "Updated"
        try repo.save(updated)
        #expect(try repo.totalItemCount() == 1)

        let fetchedUpdated = try repo.fetchById(id)
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

        var overdueItem1 = makeDummyCoreItem()
        overdueItem1.nextReviewAt = past
        try repo.save(overdueItem1)

        var overdueItem2 = makeDummyCoreItem()
        overdueItem2.nextReviewAt = past
        try repo.save(overdueItem2)

        var futureItem = makeDummyCoreItem()
        futureItem.nextReviewAt = future
        try repo.save(futureItem)

        // nextReviewAt == nil → 视为待复习（从未复习过）
        var nilItem = makeDummyCoreItem()
        nilItem.nextReviewAt = nil
        try repo.save(nilItem)

        // 过去 2 条 + nil 1 条（epoch < now）= 3
        let dueCount = try repo.fetchDueCount()
        #expect(dueCount == 3)
    }

    // MARK: - 年级统计与级联更新

    @Test("countByGrade 统计与 updateGradeUsage 级联更新")
    func gradeCountAndCascadeUpdate() throws {
        let repo = try createTestRepository()

        var item1 = makeDummyCoreItem()
        item1.grade = "高一"
        try repo.save(item1)

        var item2 = makeDummyCoreItem()
        item2.grade = "高一"
        try repo.save(item2)

        var item3 = makeDummyCoreItem()
        item3.grade = "高二"
        try repo.save(item3)

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

        var item1 = makeDummyCoreItem()
        item1.subject = "数学"
        try repo.save(item1)

        var item2 = makeDummyCoreItem()
        item2.subject = "物理"
        try repo.save(item2)

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
                    let item = self.makeDummyCoreItem(content: "Concurrent \(i)")
                    await MainActor.run {
                        try? repo.save(item)
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
        let item = makeDummyCoreItem(content: nil)

        try repo.save(item)
        #expect(try repo.totalItemCount() == 1)

        let fetched = try repo.fetchById(item.id)
        #expect(fetched?.content == nil)
    }

    @Test("difficulty rawValue 正确持久化与读取")
    func difficultyRawValueRoundTrip() throws {
        let repo = try createTestRepository()

        var item = makeDummyCoreItem()
        item.difficulty = .five
        try repo.save(item)

        let fetched = try repo.fetchById(item.id)
        #expect(fetched?.difficulty == .five)
    }
}
