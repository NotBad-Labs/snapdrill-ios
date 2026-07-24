//
//  LocalLibraryStartupTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import Testing
@testable import SnapDrillData

@Suite("LocalLibrary fail-closed startup", .serialized)
struct LocalLibraryStartupTests {
    private nonisolated static let generationUUID = UUID(
        uuid: (
            0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF,
            0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF
        )
    )

    @Test("first launch creates one generation and publishes selector only after store opens")
    func firstLaunchPublishesAfterStoreOpen() async throws {
        let fixture = Fixture()
        defer { fixture.remove() }

        let startup = try LocalLibraryStartup.prepare(
            layout: fixture.layout,
            firstGenerationID: Self.generationUUID
        )

        #expect(startup.isFirstLaunch)
        #expect(!FileManager.default.fileExists(atPath: fixture.layout.activeGenerationSelectorURL.path))
        #expect(FileManager.default.fileExists(atPath: startup.selection.imagesDirectoryURL.path))

        _ = try await DataExecutor.openLocalLibraryStore(at: startup.selection.storeURL)
        #expect(FileManager.default.fileExists(atPath: startup.selection.storeURL.path))

        try startup.publishInitialSelection()

        let selector = try Data(contentsOf: fixture.layout.activeGenerationSelectorURL)
        #expect(selector == Data("01234567-89ab-cdef-0123-456789abcdef\n".utf8))

        let reopened = try LocalLibraryStartup.prepare(layout: fixture.layout)
        #expect(!reopened.isFirstLaunch)
        #expect(reopened.selection == startup.selection)
    }

    @Test("first selector cannot publish before a regular store exists")
    func firstSelectorRequiresOpenedStore() throws {
        let fixture = Fixture()
        defer { fixture.remove() }
        let startup = try LocalLibraryStartup.prepare(
            layout: fixture.layout,
            firstGenerationID: Self.generationUUID
        )

        #expect(throws: LocalLibraryStartupError.libraryStoreUnavailable) {
            try startup.publishInitialSelection()
        }
        #expect(!FileManager.default.fileExists(atPath: fixture.layout.activeGenerationSelectorURL.path))
    }

    @Test("malformed selector blocks without choosing a generation")
    func malformedSelectorBlocks() async throws {
        let fixture = Fixture()
        defer { fixture.remove() }
        let startup = try await fixture.makePublishedLibrary()
        let malformed = Data(startup.selection.generationID.uppercased().appending("\n").utf8)
        try malformed.write(to: fixture.layout.activeGenerationSelectorURL, options: .atomic)

        #expect(throws: LocalLibraryStartupError.activeSelectorInvalid) {
            try LocalLibraryStartup.prepare(layout: fixture.layout)
        }
    }

    @Test("missing selector with generation residue blocks instead of creating an empty library")
    func missingSelectorWithGenerationBlocks() async throws {
        let fixture = Fixture()
        defer { fixture.remove() }
        _ = try await fixture.makePublishedLibrary()
        try FileManager.default.removeItem(at: fixture.layout.activeGenerationSelectorURL)

        #expect(throws: LocalLibraryStartupError.activeSelectorInvalid) {
            try LocalLibraryStartup.prepare(layout: fixture.layout)
        }
    }

    @Test("dangling selector blocks instead of creating the selected generation")
    func danglingSelectorBlocks() async throws {
        let fixture = Fixture()
        defer { fixture.remove() }
        let startup = try await fixture.makePublishedLibrary()
        try FileManager.default.removeItem(at: startup.selection.generationDirectoryURL)

        #expect(throws: LocalLibraryStartupError.activeSelectorInvalid) {
            try LocalLibraryStartup.prepare(layout: fixture.layout)
        }
    }

    @Test("selector symlink is rejected without reading its destination")
    func selectorSymlinkBlocks() async throws {
        let fixture = Fixture()
        defer { fixture.remove() }
        let startup = try await fixture.makePublishedLibrary()
        let externalSelector = fixture.rootURL.appendingPathComponent("external-selector")
        try Data(startup.selection.generationID.appending("\n").utf8).write(to: externalSelector)
        try FileManager.default.removeItem(at: fixture.layout.activeGenerationSelectorURL)
        try FileManager.default.createSymbolicLink(
            at: fixture.layout.activeGenerationSelectorURL,
            withDestinationURL: externalSelector
        )

        #expect(throws: LocalLibraryStartupError.activeSelectorInvalid) {
            try LocalLibraryStartup.prepare(layout: fixture.layout)
        }
    }

    @Test("nonterminal transaction blocks ordinary runtime startup")
    func transactionBlocksStartup() async throws {
        let fixture = Fixture()
        defer { fixture.remove() }
        _ = try await fixture.makePublishedLibrary()
        let transaction = fixture.layout.transactionsDirectoryURL
            .appendingPathComponent("01234567-89ab-cdef-0123-456789abcdef", isDirectory: true)
        try FileManager.default.createDirectory(at: transaction, withIntermediateDirectories: false)

        #expect(throws: LocalLibraryStartupError.libraryOperationInProgress) {
            try LocalLibraryStartup.prepare(layout: fixture.layout)
        }
    }

    @Test("recovery incident blocks ordinary runtime startup")
    func recoveryIncidentBlocksStartup() async throws {
        let fixture = Fixture()
        defer { fixture.remove() }
        _ = try await fixture.makePublishedLibrary()
        let incident = fixture.layout.recoveryIncidentsDirectoryURL
            .appendingPathComponent("01234567-89ab-cdef-0123-456789abcdef", isDirectory: true)
        try FileManager.default.createDirectory(at: incident, withIntermediateDirectories: false)

        #expect(throws: LocalLibraryStartupError.libraryOperationInProgress) {
            try LocalLibraryStartup.prepare(layout: fixture.layout)
        }
    }

    @Test("unknown or symlink nodes fail closed")
    func unsafeNodesFailClosed() async throws {
        let fixture = Fixture()
        defer { fixture.remove() }
        _ = try await fixture.makePublishedLibrary()
        try Data("unknown".utf8).write(
            to: fixture.layout.localLibraryDirectoryURL.appendingPathComponent("unexpected")
        )

        #expect(throws: LocalLibraryStartupError.libraryRootUnsafe) {
            try LocalLibraryStartup.prepare(layout: fixture.layout)
        }

        try FileManager.default.removeItem(
            at: fixture.layout.localLibraryDirectoryURL.appendingPathComponent("unexpected")
        )
        let imagesURL = fixture.layout.generationDirectoryURL(
            for: LocalLibraryUUID(Self.generationUUID)
        ).appendingPathComponent("images", isDirectory: true)
        try FileManager.default.removeItem(at: imagesURL)
        try FileManager.default.createSymbolicLink(
            at: imagesURL,
            withDestinationURL: fixture.rootURL
        )

        #expect(throws: LocalLibraryStartupError.libraryRootUnsafe) {
            try LocalLibraryStartup.prepare(layout: fixture.layout)
        }
    }
}

private extension LocalLibraryStartupTests {
    struct Fixture {
        let rootURL: URL
        let layout: LocalLibraryLayout

        init() {
            rootURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("LocalLibraryStartupTests-\(UUID().uuidString)", isDirectory: true)
            layout = LocalLibraryLayout(
                appOwnedRootURL: rootURL.appendingPathComponent("com.snapdrill.global", isDirectory: true)
            )
        }

        func makePublishedLibrary() async throws -> LocalLibraryStartup {
            let startup = try LocalLibraryStartup.prepare(
                layout: layout,
                firstGenerationID: LocalLibraryStartupTests.generationUUID
            )
            _ = try await DataExecutor.openLocalLibraryStore(at: startup.selection.storeURL)
            try startup.publishInitialSelection()
            return startup
        }

        func remove() {
            try? FileManager.default.removeItem(at: rootURL)
        }
    }
}
