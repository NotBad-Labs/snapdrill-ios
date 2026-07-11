//
//  LibrarySessionTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import Testing
@testable import SnapDrillData

@MainActor
struct LibrarySessionTests {
    @Test("in-memory session owns one container and repository set")
    func inMemorySession() async {
        let session = await LibrarySession.create(inMemory: true)
        #expect(!session.isUsingInMemoryFallback)
        #expect(session.storeRecoveryEvent == nil)
        #expect((try? session.repositories.archive.totalCount()) == 0)
    }

    @Test("corrupt disk store is isolated and surfaced")
    func corruptStoreRecovery() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let layout = LibraryLayout(rootURL: root)
        defer { try? FileManager.default.removeItem(at: root) }
        try layout.prepareDirectories()
        try Data("not sqlite".utf8).write(to: layout.storeURL)

        let session = await LibrarySession.create(layout: layout)
        let event = try #require(session.storeRecoveryEvent)

        #expect(!session.isUsingInMemoryFallback)
        #expect(event.storeURL == layout.storeURL)
        #expect(event.isolationDirectoryURL.path.hasPrefix(layout.corruptedStoresDirectoryURL.path))
    }
}
