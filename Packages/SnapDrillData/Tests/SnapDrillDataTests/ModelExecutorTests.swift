//
//  DataExecutorTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  DataExecutor actor 测试 — 对标 PersistenceControllerTests。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("DataExecutor 测试")
struct DataExecutorTests {

    @Test("in-memory 初始化成功")
    func inMemoryInitSuccess() throws {
        let executor = DataExecutor(inMemory: true)
        #expect(executor.container != nil)
    }

    @Test("container.mainContext 可正常 insert + fetch")
    func containerMainContextWorks() throws {
        let executor = DataExecutor(inMemory: true)
        // container.mainContext 需在 MainActor 访问
        let context = executor.container.mainContext
        let model = ReviewItemModel.mock(content: "测试")
        context.insert(model)
        try context.save()
        let count = try context.fetchCount(FetchDescriptor<ReviewItemModel>())
        #expect(count == 1)
    }

    @Test("container.mainContext 插入后可查询正确内容")
    func insertAndFetchCorrectContent() throws {
        let executor = DataExecutor(inMemory: true)
        let context = executor.container.mainContext
        let model = ReviewItemModel.mock(content: "DataExecutor 测试题")
        context.insert(model)
        try context.save()

        let items = try context.fetch(FetchDescriptor<ReviewItemModel>())
        #expect(items.count == 1)
        #expect(items.first?.content == "DataExecutor 测试题")
    }

    @Test("init(container:) 直接接受已创建的 ModelContainer")
    func initWithExistingContainer() throws {
        let container = try TestModelContainer.create()
        let executor = DataExecutor(container: container)
        #expect(executor.container != nil)
    }

    @Test("isUsingInMemoryFallback 和 initializationError 初始为 false/nil")
    func fallbackAndErrorInitiallyDefault() async throws {
        let executor = DataExecutor(inMemory: true)
        let fallback = await executor.isUsingInMemoryFallback
        let error = await executor.initializationError
        #expect(!fallback)
        #expect(error == nil)
    }

    @Test("createOffMainActor 创建成功且可用 -- #599 死锁消除验证")
    func createOffMainActorWorks() async throws {
        let executor = await DataExecutor.createOffMainActor(inMemory: true)
        #expect(executor.container != nil)
        let fallback = await executor.isUsingInMemoryFallback
        #expect(!fallback)

        // 验证 context 可正常使用
        let context = executor.container.mainContext
        context.insert(ReviewItemModel.mock(content: "OffMainActor"))
        try context.save()
        let count = try context.fetchCount(FetchDescriptor<ReviewItemModel>())
        #expect(count == 1)
    }

    @Test("createOffMainActor 多次并发调用不冲突")
    func concurrentCreateOffMainActor() async {
        let executors = await withTaskGroup(of: DataExecutor?.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await DataExecutor.createOffMainActor(inMemory: true)
                }
            }
            var results: [DataExecutor] = []
            for await e in group {
                if let e = e { results.append(e) }
            }
            return results
        }
        #expect(executors.count == 10)
    }

    @Test("Repository 通过 DataExecutor 构造可正常工作")
    func repositoryViaExecutor() throws {
        let executor = DataExecutor(inMemory: true)
        let repo = ReviewRepository(executor: executor)
        try repo.insertAndSave(ReviewItemModel.mock(content: "via executor"))
        #expect(try repo.totalCount() == 1)
    }

    @Test("RepositoryContainer 通过 DataExecutor 构造可正常工作")
    func repositoryContainerViaExecutor() throws {
        let executor = DataExecutor(inMemory: true)
        let repos = RepositoryContainer(executor: executor, scope: ProfileScope(id: UUID(), name: "Test"), profileDirectory: FileManager.default.temporaryDirectory)
        repos.review.insert(ReviewItemModel.mock(content: "container via executor"))
        try repos.review.saveContext()
        #expect(try repos.review.totalCount() == 1)
    }
}
