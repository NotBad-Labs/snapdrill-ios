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

    @Test("LocalLibrary strict open 失败时不隔离、不重建且不降级")
    func strictLocalLibraryOpenFailsWithoutMutation() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("DataExecutorStrictOpen_\(UUID().uuidString)")
        let storeURL = root.appendingPathComponent("library.store")
        let originalBytes = Data("not a sqlite store".utf8)
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try originalBytes.write(to: storeURL)
        let childrenBefore = try Set(FileManager.default.contentsOfDirectory(atPath: root.path))

        do {
            _ = try await DataExecutor.openLocalLibraryStore(at: storeURL)
            Issue.record("损坏 LocalLibrary store 不应被打开或降级")
        } catch {
            #expect(error is PersistenceError)
        }

        #expect(try Data(contentsOf: storeURL) == originalBytes)
        #expect(try Set(FileManager.default.contentsOfDirectory(atPath: root.path)) == childrenBefore)
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

    @Test("损坏 store 隔离不会删除未解决恢复材料")
    func corruptStoreIsolationPreservesAllUnresolvedIncidents() async throws {
        let fileManager = FileManager.default
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("DataExecutorStoreRetention_\(UUID().uuidString)")
        let storeURL = root.appendingPathComponent("default.store")
        let walURL = URL(fileURLWithPath: storeURL.path + "-wal")
        let shmURL = URL(fileURLWithPath: storeURL.path + "-shm")
        let corruptedRoot = ProfileVault.corruptedStoresDirectory(forProfileDirectory: root)
        let unrelatedFileURL = root.appendingPathComponent("unrelated.txt")
        let unrelatedDirectoryURL = root.appendingPathComponent("unrelated", isDirectory: true)
        let unrelatedNestedFileURL = unrelatedDirectoryURL.appendingPathComponent("sentinel.bin")
        defer { try? fileManager.removeItem(at: root) }

        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        let existingIncidentNames = [
            "2026-01-01T00-00-00.000Z",
            "2026-02-01T00-00-00.000Z",
            "2026-03-01T00-00-00.000Z"
        ]
        let expectedIncidentFiles = try createIncidentFixtures(
            in: corruptedRoot,
            names: existingIncidentNames,
            fileManager: fileManager
        )

        let newStoreData = Data("new broken store".utf8)
        let newWALData = Data("new broken wal".utf8)
        let newSHMData = Data("new broken shm".utf8)
        try newStoreData.write(to: storeURL)
        try newWALData.write(to: walURL)
        try newSHMData.write(to: shmURL)

        let unrelatedFileData = Data("unrelated file".utf8)
        let unrelatedNestedData = Data("unrelated nested file".utf8)
        try unrelatedFileData.write(to: unrelatedFileURL)
        try fileManager.createDirectory(at: unrelatedDirectoryURL, withIntermediateDirectories: true)
        try unrelatedNestedData.write(to: unrelatedNestedFileURL)

        let executor = DataExecutor(storeURL: storeURL)
        let event = try #require(await executor.storeRecoveryEvent)
        let retained = try fileManager.contentsOfDirectory(
            at: corruptedRoot,
            includingPropertiesForKeys: nil
        )
        .map(\.lastPathComponent)

        #expect(retained.count == 4)
        #expect(retained.contains(event.isolationDirectoryURL.lastPathComponent))
        for name in existingIncidentNames {
            #expect(retained.contains(name))
        }
        for expected in expectedIncidentFiles {
            #expect(try Data(contentsOf: expected.url) == expected.data)
        }

        #expect(try Data(
            contentsOf: event.isolationDirectoryURL.appendingPathComponent("default.store")
        ) == newStoreData)
        #expect(try Data(
            contentsOf: event.isolationDirectoryURL.appendingPathComponent("default.store-wal")
        ) == newWALData)
        #expect(try Data(
            contentsOf: event.isolationDirectoryURL.appendingPathComponent("default.store-shm")
        ) == newSHMData)
        #expect(try Data(contentsOf: unrelatedFileURL) == unrelatedFileData)
        #expect(try Data(contentsOf: unrelatedNestedFileURL) == unrelatedNestedData)
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
        let repos = RepositoryContainer(
            executor: executor,
            imageStorage: ImageStorage(baseDirectory: FileManager.default.temporaryDirectory)
        )
        repos.archive.insert(ArchiveItemModel.mock(content: "container via executor"))
        try repos.archive.saveContext()
        #expect(try repos.archive.totalCount() == 1)
    }

    @Test("RepositoryContainer 与 runtime 共用 ImageStorage")
    func repositoryContainerUsesInjectedImageStorage() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("RepositoryContainerImageStorage_\(UUID().uuidString)", isDirectory: true)
        let imageURL = root.appendingPathComponent("images/injected.jpg")
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(
            at: imageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("fixture".utf8).write(to: imageURL)

        let executor = DataExecutor(inMemory: true)
        let repositories = RepositoryContainer(
            executor: executor,
            imageStorage: ImageStorage(baseDirectory: root)
        )
        let item = ArchiveItemModel.mock(content: "shared image storage")
        item.imagePath = "images/injected.jpg"
        try repositories.archive.insertAndSave(item)

        try await repositories.archive.delete(id: item.id)

        #expect(!FileManager.default.fileExists(atPath: imageURL.path))
    }

    private func createIncidentFixtures(
        in corruptedRoot: URL,
        names: [String],
        fileManager: FileManager
    ) throws -> [(url: URL, data: Data)] {
        var expectedFiles: [(url: URL, data: Data)] = []
        for (incidentIndex, name) in names.enumerated() {
            let incidentDirectory = corruptedRoot.appendingPathComponent(name, isDirectory: true)
            try fileManager.createDirectory(at: incidentDirectory, withIntermediateDirectories: true)
            for fileName in ["default.store", "default.store-wal", "default.store-shm"] {
                let data = Data("incident-\(incidentIndex)-\(fileName)".utf8)
                let fileURL = incidentDirectory.appendingPathComponent(fileName)
                try data.write(to: fileURL)
                expectedFiles.append((fileURL, data))
            }
        }
        return expectedFiles
    }
}
