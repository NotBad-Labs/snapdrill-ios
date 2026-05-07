import Testing
import SwiftData
import Foundation
@testable import SnapDrillData
@testable import SnapDrillCore

@Test("PersistenceController init works, no fallback")
func persistenceControllerInMemoryInit() throws {
    let controller = PersistenceController(inMemory: true)
    #expect(!controller.isUsingInMemoryFallback)
    #expect(controller.initializationError == nil)
}

@Test("TestModelContainer.create bypasses PersistenceController")
func testModelContainerBypass() throws {
    let container = try TestModelContainer.create()
    let context = container.mainContext
    let model = ReviewItemModel(id: UUID(), content: "bypass", subject: "math", source: "test")
    context.insert(model)
    try context.save()
    let items = try context.fetch(FetchDescriptor<ReviewItemModel>())
    #expect(items.count == 1)
}

@Test("Concurrent inserts produce correct count", .serialized)
func concurrentInserts() async throws {
    let container = try TestModelContainer.create()
    let repo = ReviewRepository(modelContext: container.mainContext)

    await withTaskGroup(of: Void.self) { group in
        for i in 0..<50 {
            group.addTask { @MainActor in
                let model = ReviewItemModel(
                    id: UUID(), content: "concurrent-\(i)",
                    subject: "math", source: "test"
                )
                repo.insert(model)
            }
        }
    }
    try repo.saveContext()
    #expect(try repo.totalCount() == 50)
}

@Test("Concurrent batch inserts no data loss", .serialized)
func concurrentBatchInserts() async throws {
    let container = try TestModelContainer.create()
    let repo = ReviewRepository(modelContext: container.mainContext)

    try await withThrowingTaskGroup(of: Void.self) { group in
        for batch in 0..<5 {
            group.addTask { @MainActor in
                let base = batch * 20
                for j in 0..<20 {
                    let model = ReviewItemModel(
                        id: UUID(), content: "batch-\(base + j)",
                        subject: "english", source: "test"
                    )
                    repo.insert(model)
                }
            }
        }
        try await group.waitForAll()
    }
    try repo.saveContext()
    #expect(try repo.totalCount() == 100)
}

@Test("Concurrent fetches do not crash", .serialized)
func concurrentFetches() async throws {
    let container = try TestModelContainer.create()
    let repo = ReviewRepository(modelContext: container.mainContext)
    try repo.insertAndSave(ReviewItemModel(id: UUID(), content: "base", subject: "math", source: "test"))

    await withTaskGroup(of: Void.self) { group in
        for _ in 0..<20 {
            group.addTask { @MainActor in
                _ = try? repo.fetchAllModels()
            }
        }
    }
}

@Test("Concurrent subject update consistent", .serialized)
func concurrentSubjectUpdate() async throws {
    let container = try TestModelContainer.create()
    let repo = ReviewRepository(modelContext: container.mainContext)
    for i in 0..<10 {
        repo.insert(ReviewItemModel(id: UUID(), content: "q-\(i)", subject: "old", source: "test"))
    }
    try repo.saveContext()

    await withTaskGroup(of: Void.self) { group in
        for _ in 0..<3 {
            group.addTask { @MainActor in
                try? repo.updateSubjectUsage(from: "old", to: "new")
            }
        }
    }
    try repo.saveContext()
    let oldCount = try repo.countBySubject(name: "old")
    let newCount = try repo.countBySubject(name: "new")
    #expect(oldCount + newCount == 10)
}

@Test("deleteAllData after concurrent inserts clears all", .serialized)
func deleteAllDataAfterConcurrentInserts() async throws {
    let container = try TestModelContainer.create()
    let repos = RepositoryContainer(modelContext: container.mainContext)

    await withTaskGroup(of: Void.self) { group in
        for i in 0..<30 {
            group.addTask { @MainActor in
                let model = ReviewItemModel(
                    id: UUID(), content: "item-\(i)",
                    subject: "math", source: "test"
                )
                repos.review.insert(model)
            }
        }
    }
    try repos.review.saveContext()
    #expect(try repos.review.totalCount() == 30)

    try await repos.deleteAllData()
    #expect(try repos.review.totalCount() == 0)
    #expect(try repos.subject.totalCount() == 0)
}

@Test("restoreFromProfileData round trip", .serialized)
func restoreRoundTrip() async throws {
    let container = try TestModelContainer.create()
    let repos = RepositoryContainer(modelContext: container.mainContext)

    for id in (0..<5).map({ _ in UUID() }) {
        repos.review.insert(ReviewItemModel(id: id, content: "original-\(id)", subject: "math", source: "test"))
    }
    try repos.review.saveContext()
    let backup = try repos.collectProfileBackupData(profileName: "test", profileId: UUID())
    try await repos.restoreFromProfileData(backup)
    #expect(try repos.review.fetchAllModels().count == backup.reviewItems.count)
}

@Test("Multiple ModelContainer instances are isolated", .serialized)
func multipleContainersIsolated() async throws {
    var containers: [ModelContainer] = []
    for _ in 0..<5 {
        containers.append(try TestModelContainer.create())
    }
    for (i, c) in containers.enumerated() {
        let ctx = c.mainContext
        ctx.insert(ReviewItemModel(id: UUID(), content: "c\(i)", subject: "math", source: "test"))
        try ctx.save()
    }
    for (i, c) in containers.enumerated() {
        let count = try c.mainContext.fetchCount(FetchDescriptor<ReviewItemModel>())
        #expect(count == 1, "Container \(i)")
    }
}

@Test("ProfileManager inMemory init accessible")
func profileManagerInMemoryInit() {
    let pm = ProfileManager(inMemory: true)
    #expect(pm.activeRepositories != nil)
    #expect(pm.profiles.count == 1)
    #expect(pm.activeContainer != nil)
}

@Test("__currentBehavior_ PersistenceController init is MainActor synchronous")
func persistenceControllerInitIsMainActorSync() throws {
    let controller = PersistenceController(inMemory: true)
    #expect(controller.container != nil)
    #expect(!controller.isUsingInMemoryFallback)
}
