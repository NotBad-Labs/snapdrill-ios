//
//  ReviewRepositoryTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ReviewRepository CRUD / 边界 / 并发 单元测试。
//

// TODO: #599 — CI 跳过：ModelContainer 在 Mac mini 模拟器上死锁，待现场排查

import Testing
import SwiftData

import Foundation

import SnapDrillCore
@testable import SnapDrillData

@Suite("ReviewRepository 单元测试")
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
    func basicCRUDFlow() async throws {
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
        try await repo.delete(id: id)
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

        // nextReviewAt == Date.distantPast → 视为待复习（从未复习过，distantPast <= now 恒成立）
        let nilItem = makeDummyModel()
        // 默认值即 Date.distantPast，无需显式赋值
        try repo.insertAndSave(nilItem)

        // 过去 2 条 + distantPast 1 条（distantPast < now）= 3
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

    // MARK: - 极限数据边界（Issue #57）

    @Test("超大文本（5 万字）写入后内容可完整检索")
    func largeTextContentRoundTrip() throws {
        let repo = try createTestRepository()

        // 生成约 5 万字的重复文本（每段 15 字，共 2500 段）
        let largeContent = String(repeating: "这是一段用于边界测试的内容。", count: 2500)
        let model = makeDummyModel(content: largeContent)
        let savedId = model.id
        try repo.insertAndSave(model)

        // fetchAllModels + 内存端 filter 避免 #Predicate many-to-many 崩溃
        let fetched = try repo.fetchAllModels().first(where: { $0.id == savedId })
        #expect(fetched?.content == largeContent, "超大文本写入后应能完整检索，无截断")
    }

    @Test("四字节扩展字符（Zalgo、复杂 Emoji）写入后可正确读回")
    func specialUnicodeContentRoundTrip() throws {
        let repo = try createTestRepository()

        // Zalgo 文本（组合变音符号堆叠）
        let zalgoText = "H̷̡̪̯ͨ͊̽̅̾̎ello̯͜͡W̙ͅo̮ͅr̼̕ld"
        // 多字节复杂 Emoji（家庭+肤色+ZWJ 序列）
        let complexEmoji = "👨‍👩‍👧‍👦🏳️‍🌈🇨🇳"
        let mixedContent = "\(zalgoText) \(complexEmoji)"

        let model = makeDummyModel(content: mixedContent)
        let savedId = model.id
        try repo.insertAndSave(model)

        let fetched = try repo.fetchAllModels().first(where: { $0.id == savedId })
        #expect(fetched?.content == mixedContent, "特殊 Unicode 字符写入后应原样读回")
    }

    @Test("answerText 包含特殊字符时写入与检索正确")
    func specialUnicodeAnswerTextRoundTrip() throws {
        let repo = try createTestRepository()

        // 数学符号 + 换行 + 制表符 + 零宽字符
        let specialAnswer = "∫₀^∞ e⁻ˣ dx = 1\n换行\t制表符\u{200B}零宽空格"
        let model = makeDummyModel()
        let savedId = model.id
        model.answerText = specialAnswer
        try repo.insertAndSave(model)

        let fetched = try repo.fetchAllModels().first(where: { $0.id == savedId })
        #expect(fetched?.answerText == specialAnswer, "含特殊字符的 answerText 应完整保留")
    }
}
