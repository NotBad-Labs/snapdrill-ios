//
//  ReviewRepositoryTests.swift
//  SnapDrillDataTests
//
//  Created by SnapDrill Labs on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillData
@testable import SnapDrillCore

@MainActor
struct ReviewRepositoryTests {

    // MARK: - Helper Methods
    
    private func createTestRepository() throws -> ReviewRepository {
        let schema = Schema([ReviewItemModel.self, TagModel.self, SubjectModel.self, SourceModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ReviewRepository(modelContext: container.mainContext)
    }

    private func makeDummyCoreItem(id: UUID = UUID(), content: String = "Test") -> ReviewItem {
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
            difficulty: 3,
            grade: "高一"
        )
    }

    // MARK: - Core CRUD
    
    @Test("验证正常的保存，查询与去重容错逻辑")
    func basicCRUDAndDuplication() throws {
        let repo = try createTestRepository()
        
        let id1 = UUID()
        let item1 = makeDummyCoreItem(id: id1, content: "First")
        let item2 = makeDummyCoreItem(id: id1, content: "Duplicate UUID")
        
        // 正常插入
        try repo.save(item1)
        #expect(try repo.totalItemCount() == 1)
        
        // 主键冲突拦截检查
        #expect(throws: DataError.self) {
            try repo.save(item2)
        }
        
        // 读取验证
        let fetched = try repo.fetchById(id1)
        #expect(fetched?.content == "First", "不应当被带有重复 ID 的对象覆盖数据")
        
        // 删除验证
        if let storedModel = fetched {
            repo.delete(storedModel)
            try repo.save()
        }
        #expect(try repo.totalItemCount() == 0)
    }
    
    @Test("测试更新缺失对象时的错误向上传递路线")
    func updateMissingItemConstraints() throws {
        let repo = try createTestRepository()
        let fakeItem = makeDummyCoreItem(id: UUID())
        
        #expect(throws: DataError.self) {
            try repo.update(fakeItem)
        }
    }

    // MARK: - 边界与复杂查询
    
    @Test("验证 fetchDueCount 在不同时间轴边缘的统计正确性")
    func nextReviewAtBoundaryCounting() throws {
        let repo = try createTestRepository()
        
        let now = Date()
        let past = now.addingTimeInterval(-3600)
        let future = now.addingTimeInterval(3600)
        
        var passedItem1 = makeDummyCoreItem()
        passedItem1.nextReviewAt = past
        try repo.save(passedItem1)
        
        var passedItem2 = makeDummyCoreItem()
        passedItem2.nextReviewAt = past
        try repo.save(passedItem2)
        
        var futureItem = makeDummyCoreItem()
        futureItem.nextReviewAt = future
        try repo.save(futureItem)
        
        var nilItem = makeDummyCoreItem()
        nilItem.nextReviewAt = nil
        try repo.save(nilItem)
        
        let dueCount = try repo.fetchDueCount()
        
        // 应该只有两个在过去的项目符合 requirement
        #expect(dueCount == 2)
    }

    // MARK: - 并发防线测试

    @Test("Swift 6 TaskGroup 高并发写入下的仓库可靠性测试，排查隐蔽的竞态 Crash")
    func concurrentInsertReliability() async throws {
        // 注：由于 Repository 绑定 @MainActor，直接在并发中必须隔离。
        // 测试模拟: 多个外部并发网络任务最终汇聚到持久化前被 Actor 按序化执行，
        // 我们通过 TaskGroup 来高压模拟主线程入队时的安全性。

        let repo = try createTestRepository()
        let itemCount = 50
        
        // 开启 50 个高并发请求，但它们强制调度到主线程的安全隔离域内执行仓库插入
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<itemCount {
                group.addTask {
                    let item = self.makeDummyCoreItem(content: "Concurrent \(i)")
                    // 安全跨过 Actor 边界去执行保存
                    await MainActor.run {
                        try? repo.save(item)
                    }
                }
            }
        }
        
        // 整个 TaskGroup 跑完后应当完美插进 50 条，且没有丢数据或者抛出 CoreData Context 损坏异常
        let count = try repo.totalItemCount()
        #expect(count == itemCount)
    }

    // MARK: - 极值与异常数据测试
    
    @Test("验证保存空内容时的行为（目前允许保存，但应确保不崩溃）")
    func emptyContentHandling() throws {
        let repo = try createTestRepository()
        let emptyItem = makeDummyCoreItem(content: "")
        
        try repo.save(emptyItem)
        #expect(try repo.totalItemCount() == 1)
        let fetched = try repo.fetchById(emptyItem.id)
        #expect(fetched?.content == "")
    }

    @Test("验证删除一个包含关联项目的 Subject 时，系统的引用完整性表现")
    func deleteSubjectWithItems() throws {
        let repo = try createTestRepository()
        let subjectName = "ToDelete"
        
        // 1. 创建项目
        let item = makeDummyCoreItem()
        try repo.save(item, subject: subjectName)
        
        // 2. 查找并删除 Subject
        let descriptor = FetchDescriptor<SubjectModel>(predicate: #Predicate { $0.name == subjectName })
        if let subject = try repo.modelContext.fetch(descriptor).first {
            repo.modelContext.delete(subject)
            try repo.save()
        }
        
        // 3. 验证项目依然存在
        let itemsCount = try repo.totalItemCount()
        #expect(itemsCount == 1)
    }
}
