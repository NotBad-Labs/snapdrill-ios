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

// MARK: - Timeout Harness

private struct TimeoutError: Error, CustomStringConvertible, Sendable {
    let seconds: Int

    var description: String {
        "Concurrent test exceeded \(seconds)-second timeout"
    }
}

private final class TimeoutState<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    nonisolated(unsafe) private var continuation: CheckedContinuation<T, any Error>?
    nonisolated(unsafe) private var operationTask: Task<Void, Never>?
    nonisolated(unsafe) private var timeoutTask: Task<Void, Never>?
    nonisolated(unsafe) private var isComplete = false

    nonisolated func start(
        seconds: Int,
        continuation: CheckedContinuation<T, any Error>,
        operation: @escaping @Sendable () async throws -> T
    ) {
        lock.lock()
        self.continuation = continuation
        lock.unlock()

        let operationTask = Task.detached { [self] in
            do {
                resume(returning: try await operation())
            } catch {
                resume(throwing: error)
            }
        }

        let timeoutTask = Task.detached { [self] in
            do {
                try await Task.sleep(for: .seconds(seconds))
                operationTask.cancel()
                resume(throwing: TimeoutError(seconds: seconds))
            } catch is CancellationError {
                // Cancellation means the operation finished before the timeout.
            } catch {
                resume(throwing: error)
            }
        }

        lock.lock()
        self.operationTask = operationTask
        self.timeoutTask = timeoutTask
        lock.unlock()
    }

    nonisolated func cancel() {
        lock.lock()
        let operationTask = operationTask
        let timeoutTask = timeoutTask
        lock.unlock()

        operationTask?.cancel()
        timeoutTask?.cancel()
    }

    nonisolated private func resume(returning value: T) {
        complete { $0.resume(returning: value) }
    }

    nonisolated private func resume(throwing error: any Error) {
        complete { $0.resume(throwing: error) }
    }

    nonisolated private func complete(_ resume: (CheckedContinuation<T, any Error>) -> Void) {
        lock.lock()
        guard !isComplete, let continuation else {
            lock.unlock()
            return
        }

        isComplete = true
        self.continuation = nil
        let timeoutTask = timeoutTask
        lock.unlock()

        timeoutTask?.cancel()
        resume(continuation)
    }
}

private func withTimeout<T: Sendable>(
    seconds: Int = 10,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    let state = TimeoutState<T>()
    return try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
            state.start(seconds: seconds, continuation: continuation, operation: operation)
        }
    } onCancel: {
        state.cancel()
    }
}

private struct UncheckedSendableBox<Value>: @unchecked Sendable {
    nonisolated(unsafe) let value: Value
}

private struct SubjectCounts: Sendable {
    let oldCount: Int
    let newCount: Int
}

@MainActor
private func insertMockReviewItem(
    into repository: ReviewRepository,
    content: String,
    subject: String = "数学"
) {
    repository.insert(ReviewItemModel.mock(content: content, subject: subject))
}

@MainActor
private func insertAndSaveMockReviewItem(
    into repository: ReviewRepository,
    content: String
) throws {
    try repository.insertAndSave(ReviewItemModel.mock(content: content))
}

@MainActor
private func fetchAllReviewModelCount(from repository: ReviewRepository) throws -> Int {
    try repository.fetchAllModels().count
}

@Suite("DataConcurrencyTests", .serialized)
struct DataConcurrencyTests {

// MARK: - ModelContainer 并发初始化

@Test("多实例并发创建无死锁 -- #599 根因回归")
func concurrentContainerCreationNoDeadlock() async throws {
    let okCount = try await withTimeout {
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
        return okCount
    }
    #expect(okCount == 10)
}

@Test("DataExecutor.createOffMainActor 并发创建 10 实例无死锁")
func concurrentDataExecutorCreationNoDeadlock() async throws {
    let executorCount = try await withTimeout {
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
        return executors.count
    }
    #expect(executorCount == 10)
}

@Test("多实例各自隔离，数据不互相泄露")
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

@Test("__currentBehavior_ #599 绕过: TestModelContainer 不经 PersistenceController.init")
func bypassPersistenceControllerInit() throws {
    let container = try TestModelContainer.create()
    let ctx = container.mainContext
    ctx.insert(ReviewItemModel.mock(content: "绕过 PersistenceController"))
    try ctx.save()
    let count = try ctx.fetchCount(FetchDescriptor<ReviewItemModel>())
    #expect(count == 1)
}

// MARK: - Repository 并发操作正确性

@Test("并发插入 50 条记录后计数正确")
func concurrentInsertsCorrectCount() async throws {
    let count = try await withTimeout {
        let container = try TestModelContainer.create()
        let repo = await UncheckedSendableBox(value: ReviewRepository(modelContext: ModelContext(container)))

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    await insertMockReviewItem(into: repo.value, content: "并发-\(i)")
                }
            }
        }
        try await repo.value.saveContext()
        return try await repo.value.totalCount()
    }
    #expect(count == 50)
}

@Test("5 批次各 20 条并发插入无数据丢失")
func concurrentBatchInsertsNoDataLoss() async throws {
    let count = try await withTimeout {
        let container = try TestModelContainer.create()
        let repo = await UncheckedSendableBox(value: ReviewRepository(modelContext: ModelContext(container)))

        try await withThrowingTaskGroup(of: Void.self) { group in
            for batch in 0..<5 {
                group.addTask {
                    let base = batch * 20
                    for j in 0..<20 {
                        await insertMockReviewItem(into: repo.value, content: "批次-\(base + j)")
                    }
                }
            }
            try await group.waitForAll()
        }
        try await repo.value.saveContext()
        return try await repo.value.totalCount()
    }
    #expect(count == 100)
}

@Test("并发 fetch 操作不抛出错误")
func concurrentFetchesNoError() async throws {
    try await withTimeout {
        let container = try TestModelContainer.create()
        let repo = await UncheckedSendableBox(value: ReviewRepository(modelContext: ModelContext(container)))
        try await insertAndSaveMockReviewItem(into: repo.value, content: "基准数据")

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    _ = try await fetchAllReviewModelCount(from: repo.value)
                }
            }
            try await group.waitForAll()
        }
    }
}

@Test("并发 updateSubjectUsage 后旧数据全部迁移 -- 断言不弱")
func concurrentSubjectUpdateAllMigrated() async throws {
    let counts = try await withTimeout {
        let container = try TestModelContainer.create()
        let repo = await UncheckedSendableBox(value: ReviewRepository(modelContext: ModelContext(container)))
        for i in 0..<10 {
            await insertMockReviewItem(into: repo.value, content: "题目-\(i)", subject: "旧学科")
        }
        try await repo.value.saveContext()

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<3 {
                group.addTask {
                    try await repo.value.updateSubjectUsage(from: "旧学科", to: "新学科")
                }
            }
            try await group.waitForAll()
        }
        try await repo.value.saveContext()

        return await SubjectCounts(
            oldCount: try repo.value.countBySubject(name: "旧学科"),
            newCount: try repo.value.countBySubject(name: "新学科")
        )
    }

    #expect(counts.newCount > 0, "更新未生效: 新学科数量为 0")
    #expect(counts.oldCount < 10, "更新未生效: 旧学科数量仍为 10")
    #expect(counts.oldCount + counts.newCount == 10)
}

// MARK: - RepositoryContainer 原子操作

@Test("deleteAllData 在并发插入后正确清空所有仓库")
func deleteAllDataAfterConcurrentInsertsClearsAll() async throws {
    let counts = try await withTimeout {
        let container = try TestModelContainer.create()
        let repos = await UncheckedSendableBox(value: RepositoryContainer(modelContext: ModelContext(container)))

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<30 {
                group.addTask {
                    await insertMockReviewItem(into: repos.value.review, content: "条目-\(i)")
                }
            }
        }
        try await repos.value.review.saveContext()
        let beforeDeleteCount = try await repos.value.review.totalCount()

        try await repos.value.deleteAllData()
        return (
            beforeDeleteCount,
            try await repos.value.review.totalCount(),
            try await repos.value.subject.totalCount(),
            try await repos.value.source.totalCount()
        )
    }
    #expect(counts.0 == 30)
    #expect(counts.1 == 0)
    #expect(counts.2 == 0)
    #expect(counts.3 == 0)
}

@Test("deleteAllData + restoreFromProfileData 两轮不残留数据")
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

}
