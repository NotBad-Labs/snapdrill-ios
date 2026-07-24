//
//  LocalLibraryRuntimeTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import Testing
import UIKit
@testable import SnapDrillData

@Suite("LocalLibrary concrete runtime", .serialized)
@MainActor
struct LocalLibraryRuntimeTests {
    @Test("first launch returns one complete runtime and publishes its selector")
    func firstLaunchReturnsCompleteRuntime() async throws {
        let fixture = Fixture()
        defer { fixture.remove() }

        let runtime = try await LocalLibraryRuntime.open(appOwnedRootURL: fixture.appOwnedRootURL)
        let selection = try #require(runtime.selection)

        #expect(FileManager.default.fileExists(atPath: selection.storeURL.path))
        #expect(FileManager.default.fileExists(atPath: selection.imagesDirectoryURL.path))
        #expect(
            try Data(contentsOf: fixture.layout.activeGenerationSelectorURL)
                == Data(selection.generationID.appending("\n").utf8)
        )
    }

    @Test("repositories and ImageStorage share the selected generation")
    func repositoriesShareImageStorage() async throws {
        let fixture = Fixture()
        defer { fixture.remove() }
        let runtime = try await LocalLibraryRuntime.open(appOwnedRootURL: fixture.appOwnedRootURL)

        let path = try await runtime.imageStorage.saveImage(Self.makeImage())
        let item = ArchiveItemModel(content: "shared runtime", imagePath: path)
        runtime.repositories.archive.insert(item)
        try runtime.repositories.archive.saveContext()

        #expect(runtime.imageStorage.imageFileURL(path: path) != nil)
        try await runtime.repositories.deleteAllData()
        #expect(runtime.imageStorage.imageFileURL(path: path) == nil)
    }

    @Test("corrupt selected store fails without returning a partial runtime or mutating bytes")
    func corruptStoreFailsWithoutMutation() async throws {
        let fixture = Fixture()
        defer { fixture.remove() }
        let startup = try LocalLibraryStartup.prepare(
            layout: fixture.layout,
            firstGenerationID: Fixture.generationUUID
        )
        let originalBytes = Data("not a sqlite store".utf8)
        try originalBytes.write(to: startup.selection.storeURL)
        try startup.publishInitialSelection()
        let childrenBefore = try Set(
            FileManager.default.contentsOfDirectory(atPath: startup.selection.generationDirectoryURL.path)
        )

        do {
            _ = try await LocalLibraryRuntime.open(appOwnedRootURL: fixture.appOwnedRootURL)
            Issue.record("corrupt LocalLibrary store must not produce a runtime")
        } catch {
            #expect(error is PersistenceError)
        }

        #expect(try Data(contentsOf: startup.selection.storeURL) == originalBytes)
        #expect(
            try Set(
                FileManager.default.contentsOfDirectory(atPath: startup.selection.generationDirectoryURL.path)
            ) == childrenBefore
        )
    }

    @Test("in-memory runtime is explicit and has no production selector")
    func inMemoryRuntimeIsExplicit() throws {
        let fixture = Fixture()
        defer { fixture.remove() }

        let runtime = LocalLibraryRuntime.makeInMemoryForTesting(imageRootURL: fixture.rootURL)
        runtime.repositories.archive.insert(ArchiveItemModel(content: "in-memory"))
        try runtime.repositories.archive.saveContext()

        #expect(runtime.selection == nil)
        #expect(try runtime.repositories.archive.totalCount() == 1)
        #expect(!FileManager.default.fileExists(atPath: fixture.layout.activeGenerationSelectorURL.path))
    }

    private static func makeImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64))
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
        }
    }
}

private extension LocalLibraryRuntimeTests {
    struct Fixture {
        static let generationUUID = UUID(
            uuid: (
                0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF,
                0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF
            )
        )

        let rootURL: URL
        let appOwnedRootURL: URL
        let layout: LocalLibraryLayout

        init() {
            rootURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("LocalLibraryRuntimeTests-\(UUID().uuidString)", isDirectory: true)
            appOwnedRootURL = rootURL.appendingPathComponent("com.snapdrill.global", isDirectory: true)
            layout = LocalLibraryLayout(appOwnedRootURL: appOwnedRootURL)
        }

        func remove() {
            try? FileManager.default.removeItem(at: rootURL)
        }
    }
}
