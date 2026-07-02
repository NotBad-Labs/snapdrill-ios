//
//  DataExecutorTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  DataExecutor actor 测试。
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
        let model = ArchiveItemModel.mock(content: "测试")
        context.insert(model)
        try context.save()
        let count = try context.fetchCount(FetchDescriptor<ArchiveItemModel>())
        #expect(count == 1)
    }

    @Test("container.mainContext 插入后可查询正确内容")
    func insertAndFetchCorrectContent() throws {
        let executor = DataExecutor(inMemory: true)
        let context = executor.container.mainContext
        let model = ArchiveItemModel.mock(content: "DataExecutor 测试题")
        context.insert(model)
        try context.save()

        let items = try context.fetch(FetchDescriptor<ArchiveItemModel>())
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
        context.insert(ArchiveItemModel.mock(content: "OffMainActor"))
        try context.save()
        let count = try context.fetchCount(FetchDescriptor<ArchiveItemModel>())
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
        let repo = ArchiveRepository(executor: executor)
        try repo.insertAndSave(ArchiveItemModel.mock(content: "via executor"))
        #expect(try repo.totalCount() == 1)
    }

    @Test("磁盘 store 打不开时隔离保留原文件并上报恢复事件")
    func diskStoreFailureIsolatesCorruptStoreAndReportsEvent() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("DataExecutorStoreRecovery_\(UUID().uuidString)")
        let storeURL = root.appendingPathComponent("default.store")
        let walURL = URL(fileURLWithPath: storeURL.path + "-wal")
        let shmURL = URL(fileURLWithPath: storeURL.path + "-shm")
        defer { try? FileManager.default.removeItem(at: root) }

        let corruptStoreData = Data("not a sqlite store".utf8)
        let staleWALData = Data("stale wal".utf8)
        let staleSHMData = Data("stale shm".utf8)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try corruptStoreData.write(to: storeURL)
        try staleWALData.write(to: walURL)
        try staleSHMData.write(to: shmURL)

        let executor = DataExecutor(storeURL: storeURL)
        let event = try #require(await executor.storeRecoveryEvent)
        let isolationDirectory = event.isolationDirectoryURL

        #expect(await executor.isUsingInMemoryFallback == false)
        #expect(await executor.initializationError == nil)
        #expect(event.storeURL == storeURL)
        #expect(event.originalErrorDescription.isEmpty == false)
        #expect(event.retryErrorDescription.isEmpty == false)
        #expect(isolationDirectory.path.hasPrefix(ProfileVault.corruptedStoresDirectory(forProfileDirectory: root).path))
        #expect(try Data(contentsOf: isolationDirectory.appendingPathComponent("default.store")) == corruptStoreData)
        #expect(try Data(contentsOf: isolationDirectory.appendingPathComponent("default.store-wal")) == staleWALData)
        #expect(try Data(contentsOf: isolationDirectory.appendingPathComponent("default.store-shm")) == staleSHMData)

        let context = executor.container.mainContext
        #expect(try context.fetchCount(FetchDescriptor<ArchiveItemModel>()) == 0)
        context.insert(ArchiveItemModel.mock(content: "recovered disk store"))
        try context.save()
        #expect((try? Data(contentsOf: storeURL)) != corruptStoreData)
        let count = try context.fetchCount(FetchDescriptor<ArchiveItemModel>())
        #expect(count == 1)
    }

    @Test("损坏 store 隔离目录最多保留最近三份")
    func corruptStoreIsolationRetainsNewestThreeArchives() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("DataExecutorStoreRetention_\(UUID().uuidString)")
        let storeURL = root.appendingPathComponent("default.store")
        let corruptedRoot = ProfileVault.corruptedStoresDirectory(forProfileDirectory: root)
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        for name in [
            "2026-01-01T00-00-00.000Z",
            "2026-02-01T00-00-00.000Z",
            "2026-03-01T00-00-00.000Z"
        ] {
            try FileManager.default.createDirectory(
                at: corruptedRoot.appendingPathComponent(name, isDirectory: true),
                withIntermediateDirectories: true
            )
        }
        try Data("broken".utf8).write(to: storeURL)

        let executor = DataExecutor(storeURL: storeURL)
        let event = try #require(await executor.storeRecoveryEvent)
        let retained = try FileManager.default.contentsOfDirectory(
            at: corruptedRoot,
            includingPropertiesForKeys: nil
        )
        .map(\.lastPathComponent)
        .sorted()

        #expect(retained.count == 3)
        #expect(retained.contains(event.isolationDirectoryURL.lastPathComponent))
        #expect(!retained.contains("2026-01-01T00-00-00.000Z"))
    }

    @Test("健康磁盘 store 打开不创建隔离目录也不上报恢复事件")
    func healthyDiskStoreDoesNotReportRecovery() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("DataExecutorHealthyStore_\(UUID().uuidString)")
        let storeURL = root.appendingPathComponent("default.store")
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let executor = DataExecutor(storeURL: storeURL)
        let context = executor.container.mainContext
        context.insert(ArchiveItemModel.mock(content: "healthy disk store"))
        try context.save()

        #expect(await executor.isUsingInMemoryFallback == false)
        #expect(await executor.initializationError == nil)
        #expect(await executor.storeRecoveryEvent == nil)
        #expect(!FileManager.default.fileExists(
            atPath: ProfileVault.corruptedStoresDirectory(forProfileDirectory: root).path
        ))
    }

    @Test("RepositoryContainer 通过 DataExecutor 构造可正常工作")
    func repositoryContainerViaExecutor() throws {
        let executor = DataExecutor(inMemory: true)
        let repos = RepositoryContainer(executor: executor, scope: ProfileScope(id: UUID(), name: "Test"), profileDirectory: FileManager.default.temporaryDirectory)
        repos.archive.insert(ArchiveItemModel.mock(content: "container via executor"))
        try repos.archive.saveContext()
        #expect(try repos.archive.totalCount() == 1)
    }
}
