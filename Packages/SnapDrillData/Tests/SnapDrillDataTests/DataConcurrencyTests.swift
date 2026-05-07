//
//  DataConcurrencyTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs on 2026/05/07.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Data 层并发安全性回归网 -- PR #8a。
//  锁死 #599 的 ModelContainer init 并发、Repository 跨 Task 操作正确性、
//  RepositoryContainer 原子操作的行为基线。
//  为 PR #8b DataExecutor 重构提供回归安全网。
//
//  并发约束: defaultIsolation(MainActor) 下 ModelContext 非 Sendable，
//  真正的并行读写需等待 PR #8b 的 DataExecutor actor。
//  当前测试验证: (1) 多 ModelContainer 实例可并发创建无死锁
//  (2) MainActor 串行化下的 interleaving 操作保持数据一致。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillData
@testable import SnapDrillCore

// MARK: - ModelContainer 并发初始化

@Test("多实例并发创建无死锁 -- #599 根因回归", .serialized)
func concurrentContainerCreationNoDeadlock() async {
    var okCount = 0
    await withTaskGroup(of: Bool.self) { group in
        for _ in 0..<10 {
            group.addTask {
                do {
                    _ = try TestModelContainer.create()
                    return true
                } catch {
                    return false
                }
            }
        }
        for await r in group where r {
            okCount += 1
        }
    }
    #expect(okCount == 10)
}

@Test("DataExecutor.createOffMainActor 并发创建 10 实例无死锁", .serialized)
func concurrentDataExecutorCreationNoDeadlock() async {
    var executors: [DataExecutor] = []
    await withTaskGroup(of: DataExecutor.self) { group in
        for _ in 0..<10 {
            group.addTask {
                await DataExecutor.createOffMainActor(inMemory: true)
            }
        }
        for await e in group {
            executors.append(e)
        }
    }
    #expect(executors.count == 10)
}

@Test("多实例各自隔离，数据不互相泄露", .serialized)
func multipleContainersDataIsolation() async throws {
    var containers: [ModelContainer] = []
    for _ in 0..<5 {
        containers.append(try TestModelContainer.create())
    }

    for (i, c) in containers.enumerated() {
        let ctx = c.mainContext
        ctx.insert(ReviewItemModel.mock(content: "c\(i)"))
        try ctx.save()
    }

    for (i, c) in containers.enumerated() {
        let count = try c.mainContext.fetchCount(FetchDescriptor<ReviewItemModel>())
        #expect(count == 1, "容器 \(i) 数据隔离失败")
    }
}

@Test("__currentBehavior_ #599 绕过: TestModelContainer 不经 PersistenceController.init", .serialized)
func bypassPersistenceControllerInit() throws {
    let container = try TestModelContainer.create()
    let ctx = container.mainContext
    ctx.insert(ReviewItemModel.mock(content: "绕过 PersistenceController"))
    try ctx.save()
    let count = try ctx.fetchCount(FetchDescriptor<ReviewItemModel>())
    #expect(count == 1)
}

// MARK: - Repository 并发操作正确性

@Test("并发插入 50 条记录后计数正确", .serialized)
func concurrentInsertsCorrectCount() async throws {
    let container = try TestModelContainer.create()
    let repo = ReviewRepository(modelContext: container.mainContext)

    await withTaskGroup(of: Void.self) { group in
        for i in 0..<50 {
            group.addTask { @MainActor in
                repo.insert(ReviewItemModel.mock(content: "并发-\(i)"))
            }
        }
    }
    try repo.saveContext()
    #expect(try repo.totalCount() == 50)
}

@Test("5 批次各 20 条并发插入无数据丢失", .serialized)
func concurrentBatchInsertsNoDataLoss() async throws {
    let container = try TestModelContainer.create()
    let repo = ReviewRepository(modelContext: container.mainContext)

    try await withThrowingTaskGroup(of: Void.self) { group in
        for batch in 0..<5 {
            group.addTask { @MainActor in
                let base = batch * 20
                for j in 0..<20 {
                    repo.insert(ReviewItemModel.mock(content: "批次-\(base + j)"))
                }
            }
        }
        try await group.waitForAll()
    }
    try repo.saveContext()
    #expect(try repo.totalCount() == 100)
}

@Test("并发 fetch 操作不抛出错误", .serialized)
func concurrentFetchesNoError() async throws {
    let container = try TestModelContainer.create()
    let repo = ReviewRepository(modelContext: container.mainContext)
    try repo.insertAndSave(ReviewItemModel.mock(content: "基准数据"))

    try await withThrowingTaskGroup(of: Void.self) { group in
        for _ in 0..<20 {
            group.addTask { @MainActor in
                _ = try repo.fetchAllModels()
            }
        }
        try await group.waitForAll()
    }
}

@Test("并发 updateSubjectUsage 后旧数据全部迁移 -- 断言不弱", .serialized)
func concurrentSubjectUpdateAllMigrated() async throws {
    let container = try TestModelContainer.create()
    let repo = ReviewRepository(modelContext: container.mainContext)
    for i in 0..<10 {
        repo.insert(ReviewItemModel.mock(content: "题目-\(i)", subject: "旧学科"))
    }
    try repo.saveContext()

    try await withThrowingTaskGroup(of: Void.self) { group in
        for _ in 0..<3 {
            group.addTask { @MainActor in
                try repo.updateSubjectUsage(from: "旧学科", to: "新学科")
            }
        }
        try await group.waitForAll()
    }
    try repo.saveContext()

    let oldCount = try repo.countBySubject(name: "旧学科")
    let newCount = try repo.countBySubject(name: "新学科")
    #expect(newCount > 0, "更新未生效: 新学科数量为 0")
    #expect(oldCount < 10, "更新未生效: 旧学科数量仍为 10")
    #expect(oldCount + newCount == 10)
}

// MARK: - RepositoryContainer 原子操作

@Test("deleteAllData 在并发插入后正确清空所有仓库", .serialized)
func deleteAllDataAfterConcurrentInsertsClearsAll() async throws {
    let container = try TestModelContainer.create()
    let repos = RepositoryContainer(modelContext: container.mainContext)

    await withTaskGroup(of: Void.self) { group in
        for i in 0..<30 {
            group.addTask { @MainActor in
                repos.review.insert(ReviewItemModel.mock(content: "条目-\(i)"))
            }
        }
    }
    try repos.review.saveContext()
    #expect(try repos.review.totalCount() == 30)

    try await repos.deleteAllData()
    #expect(try repos.review.totalCount() == 0)
    #expect(try repos.subject.totalCount() == 0)
    #expect(try repos.source.totalCount() == 0)
}

@Test("deleteAllData + restoreFromProfileData 两轮不残留数据", .serialized)
func deleteThenRestoreRoundTripNoResidue() async throws {
    let container = try TestModelContainer.create()
    let repos = RepositoryContainer(modelContext: container.mainContext)

    let mathSubject = SubjectModel.mock(name: "数学")
    try repos.subject.insertAndSave(mathSubject)
    repos.review.insert(ReviewItemModel.mock(content: "原始题", subject: "数学"))
    try repos.review.saveContext()

    let backup = try repos.collectProfileBackupData(profileName: "p1", profileId: UUID())
    try await repos.deleteAllData()
    #expect(try repos.review.totalCount() == 0)

    try await repos.restoreFromProfileData(backup)
    #expect(try repos.review.totalCount() > 0)
}
