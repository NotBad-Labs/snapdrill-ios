//
//  ArchiveRepositoryTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ArchiveRepository CRUD / 边界 / 并发 单元测试。
//

import Testing
import SwiftData

import Foundation

@testable import SnapDrillData

@Suite("ArchiveRepository 单元测试")
final class ArchiveRepositoryTests {

    private let container: ModelContainer
    private let repo: ArchiveRepository

    init() throws {
        container = try TestModelContainer.create()
        repo = ArchiveRepository(modelContext: container.mainContext)
    }

    // MARK: - Helpers

    private func makeDummyModel(
        id: UUID = UUID(),
        content: String? = "Test"
    ) -> ArchiveItemModel {
        ArchiveItemModel(
            id: id,
            content: content,
            imagePath: nil,
            answerText: "测试答案"
        )
    }

    // MARK: - 基础 CRUD

    @Test("正常保存、Upsert 与删除流程")
    func basicCRUDFlow() async throws {
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

    // L3：原 countByLevel/countByCategory + updateXxxUsage 级联更新测试已删——
    // 这些方法随裸字符串字段移除；动态维度下分类统计走 CategoryValueModel.items?.count、
    // 重命名走单次 value.name 赋值（关系自动跟随），相关守护在 S7 维度值测试覆盖。

    // MARK: - 并发防线测试

    @Test("高并发写入下的仓库可靠性（50 个并发任务）")
    func concurrentInsertReliability() async throws {
        let itemCount = 50

        // 所有 Task 都调度到 MainActor 串行执行，验证无竞态崩溃
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<itemCount {
                group.addTask {
                    await MainActor.run {
                        let model = self.makeDummyModel(content: "Concurrent \(i)")
                        try? self.repo.insertAndSave(model)
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
        let model = makeDummyModel(content: nil)

        try repo.insertAndSave(model)
        #expect(try repo.totalItemCount() == 1)

        let fetched = try repo.fetchModel(by: model.id)
        #expect(fetched?.content == nil)
    }

    // MARK: - 极限数据边界（Issue #57）

    @Test("超大文本（5 万字）写入后内容可完整检索")
    func largeTextContentRoundTrip() throws {
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
        // 数学符号 + 换行 + 制表符 + 零宽字符
        let specialAnswer = "∫₀^∞ e⁻ˣ dx = 1\n换行\t制表符\u{200B}零宽空格"
        let model = makeDummyModel()
        let savedId = model.id
        model.answerText = specialAnswer
        try repo.insertAndSave(model)

        let fetched = try repo.fetchAllModels().first(where: { $0.id == savedId })
        #expect(fetched?.answerText == specialAnswer, "含特殊字符的 answerText 应完整保留")
    }

    // MARK: - 软删 pending 排除（Fix 4 / GAP-R1）

    @Test("fetchDueModels/Count/SmartSelection 的 excluding 排除软删 pending 题")
    func fetchDue_excludesPendingDeletion() async throws {
        let keepID = UUID()
        let pendingID = UUID()
        let keep = makeDummyModel(id: keepID, content: "保留题")
        keep.nextReviewAt = Date(timeIntervalSinceNow: -3600)
        let pending = makeDummyModel(id: pendingID, content: "待删题")
        pending.nextReviewAt = Date(timeIntervalSinceNow: -3600)
        try repo.insertAndSave(keep)
        try repo.insertAndSave(pending)

        // 无排除：两题都到期
        #expect(try repo.fetchDueModels().count == 2)
        #expect(try repo.fetchDueCount() == 2)
        #expect(try repo.fetchSmartSelection(limit: 10).count == 2)

        // 排除 pendingID（模拟 5 秒撤销窗口内的软删题）
        let due = try repo.fetchDueModels(excluding: [pendingID])
        #expect(due.count == 1)
        #expect(due.first?.id == keepID)
        #expect(try repo.fetchDueCount(excluding: [pendingID]) == 1)
        let smart = try repo.fetchSmartSelection(limit: 10, excluding: [pendingID])
        #expect(smart.count == 1)
        #expect(smart.first?.id == keepID)
    }
}
