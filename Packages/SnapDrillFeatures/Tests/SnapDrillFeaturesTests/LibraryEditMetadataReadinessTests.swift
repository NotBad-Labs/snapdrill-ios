//
//  LibraryEditMetadataReadinessTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import SwiftData
import Testing
import UIKit
@testable import SnapDrillCore
@testable import SnapDrillData
@testable import SnapDrillFeatureLibrary

private enum ExpectedMetadataError: Error {
    case loadFailed
}

private actor SuspendedInitialImageGate {
    private var didStart = false
    private var startWaiter: CheckedContinuation<Void, Never>?
    private var releaseWaiter: CheckedContinuation<Void, Never>?

    func suspend() async {
        didStart = true
        startWaiter?.resume()
        startWaiter = nil
        await withCheckedContinuation { releaseWaiter = $0 }
    }

    func waitUntilStarted() async {
        guard !didStart else { return }
        await withCheckedContinuation { startWaiter = $0 }
    }

    func release() {
        releaseWaiter?.resume()
        releaseWaiter = nil
    }
}

@Suite("Library edit metadata readiness", .serialized)
final class LibraryEditMetadataReadinessTests {
    private let container: ModelContainer
    private let repos: RepositoryContainer

    init() throws {
        let schema = Schema(SnapDrillSchemaV1.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        repos = RepositoryContainer(modelContext: container.mainContext)
    }

    @Test("save before metadata initialization has zero side effects")
    func saveBeforeMetadataInitializationIsRejected() async throws {
        let value = try seedValue(systemKey: "category", name: "Math")
        let item = try insertItem(content: "Original", values: [value])
        let directory = temporaryDirectory(named: "Uninitialized")
        defer { removeTemporaryDirectory(directory) }
        let storage = ImageStorage(baseDirectory: directory)
        let tracker = AppActivityTracker()
        let viewModel = makeViewModel(item: item, storage: storage, tracker: tracker)
        viewModel.content = "Edited"
        viewModel.displayedImage = createTestImage()

        var notificationCount = 0
        let observer = NotificationCenter.default.addObserver(
            forName: .reviewDataDidChange,
            object: nil,
            queue: .main
        ) { _ in
            notificationCount += 1
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        await viewModel.save()

        #expect(viewModel.metadataLoadState == .loading)
        #expect(!viewModel.isSavedNormally)
        #expect(item.content == "Original")
        #expect(Set((item.categoryValues ?? []).map(\.id)) == Set([value.id]))
        #expect(tracker.activeActivities.isEmpty)
        #expect(await storage.imageDirectorySize() == 0)
        #expect(notificationCount == 0)
    }

    @Test("metadata failure blocks save and retry restores existing selections")
    func metadataFailureBlocksSaveAndRetryRestoresSelection() async throws {
        let value = try seedValue(systemKey: "category", name: "Math")
        let dimensionID = try #require(value.dimension).id
        let item = try insertItem(content: "Original", values: [value])
        let viewModel = makeViewModel(item: item)
        var attempts = 0
        viewModel.metadataLoader = {
            attempts += 1
            guard attempts > 1 else { throw ExpectedMetadataError.loadFailed }
            return try self.repos.dimension.fetchAllModels()
        }

        await viewModel.loadData()
        #expect(viewModel.metadataLoadState == .failed)

        viewModel.content = "Must not persist"
        await viewModel.save()
        #expect(item.content == "Original")
        #expect(Set((item.categoryValues ?? []).map(\.id)) == Set([value.id]))

        await viewModel.loadData()
        #expect(viewModel.metadataLoadState == .ready)
        #expect(viewModel.selectedIds(forDimension: dimensionID).contains(value.id))

        viewModel.content = "Saved after retry"
        await viewModel.save()
        #expect(item.content == "Saved after retry")
        #expect(Set((item.categoryValues ?? []).map(\.id)) == Set([value.id]))
    }

    @Test("metadata becomes ready before suspended image decode and preserves old data")
    func metadataReadyBeforeSuspendedImageDecode() async throws {
        let value = try seedValue(systemKey: "category", name: "Math")
        let dimensionID = try #require(value.dimension).id
        let oldPath = "images/original.jpg"
        let item = try insertItem(content: "Original", imagePath: oldPath, values: [value])
        let viewModel = makeViewModel(item: item)
        let gate = SuspendedInitialImageGate()
        viewModel.initialImageLoader = { _ in
            await gate.suspend()
            return self.makeImage(width: 1)
        }

        let loadTask = Task { await viewModel.loadData() }
        await gate.waitUntilStarted()

        #expect(viewModel.metadataLoadState == .ready)
        #expect(viewModel.selectedIds(forDimension: dimensionID).contains(value.id))
        viewModel.content = "Edited while image loads"
        await viewModel.save()
        #expect(item.imagePath == oldPath)
        #expect(Set((item.categoryValues ?? []).map(\.id)) == Set([value.id]))

        viewModel.displayedImage = makeImage(width: 2)
        await gate.release()
        await loadTask.value
        #expect(viewModel.displayedImage?.size.width == 2)
    }

    @Test("missing initial image still reaches ready and preserves its old path")
    func missingInitialImagePreservesOldPath() async throws {
        let value = try seedValue(systemKey: "category", name: "Math")
        let oldPath = "images/missing.jpg"
        let item = try insertItem(content: "Original", imagePath: oldPath, values: [value])
        let directory = temporaryDirectory(named: "MissingImage")
        defer { removeTemporaryDirectory(directory) }
        let viewModel = makeViewModel(item: item, storage: ImageStorage(baseDirectory: directory))

        await viewModel.loadData()

        #expect(viewModel.metadataLoadState == .ready)
        #expect(viewModel.imageLoadFailed)
        viewModel.content = "Edited without image decode"
        await viewModel.save()
        #expect(item.imagePath == oldPath)
        #expect(Set((item.categoryValues ?? []).map(\.id)) == Set([value.id]))
    }

    @Test("an empty dimension repository is a valid ready state")
    func emptyDimensionsAreReady() async throws {
        let item = try insertItem(content: "Original")
        let viewModel = makeViewModel(item: item)

        await viewModel.loadData()

        #expect(viewModel.metadataLoadState == .ready)
        #expect(viewModel.dimensions.isEmpty)
        #expect(viewModel.valuesByDimension.isEmpty)
        #expect(viewModel.selectedByDimension.isEmpty)
    }

    @Test("repeated load preserves an intentional classification clear")
    func repeatedLoadPreservesIntentionalClear() async throws {
        let category = try seedValue(systemKey: "category", name: "Math")
        let tag = try seedValue(systemKey: "tag", name: "Important")
        let item = try insertItem(content: "Original", values: [category, tag])
        let viewModel = makeViewModel(item: item)
        await viewModel.loadData()
        let categoryID = try #require(category.dimension?.id)

        viewModel.toggleValue(category.id, inDimension: categoryID)
        await viewModel.loadData()
        await viewModel.save()

        #expect(Set((item.categoryValues ?? []).map(\.id)) == Set([tag.id]))
    }

    private func seedValue(systemKey: String, name: String) throws -> CategoryValueModel {
        repos.dimension.seedDefaultsIfNeeded()
        let dimensions = try repos.dimension.fetchAllModels()
        let dimension = try #require(dimensions.first { $0.systemKey == systemKey })
        let value = repos.categoryValue.fetchOrCreate(name: name, in: dimension)
        try repos.categoryValue.saveContext()
        return value
    }

    private func insertItem(
        content: String,
        imagePath: String? = nil,
        values: [CategoryValueModel] = []
    ) throws -> ArchiveItemModel {
        let item = ArchiveItemModel(content: content, imagePath: imagePath)
        item.categoryValues = values
        repos.archive.insert(item)
        try repos.archive.saveContext()
        return item
    }

    private func makeViewModel(
        item: ArchiveItemModel,
        storage: ImageStorage = ImageStorage(baseDirectory: FileManager.default.temporaryDirectory),
        tracker: AppActivityTracker = AppActivityTracker()
    ) -> LibraryEditViewModel {
        LibraryEditViewModel(
            item: item,
            repositories: repos,
            imageStorage: storage,
            ocrService: MockOCRServiceShared(),
            activityTracker: tracker
        )
    }

    private func temporaryDirectory(named name: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("LibraryEditMetadata-\(name)-\(UUID().uuidString)")
    }

    private func removeTemporaryDirectory(_ url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            Issue.record("Failed to remove test directory: \(error.localizedDescription)")
        }
    }

    private func makeImage(width: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: width, height: 1)).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: 1))
        }
    }
}
