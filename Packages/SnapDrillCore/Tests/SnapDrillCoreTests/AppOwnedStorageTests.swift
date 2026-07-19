//
//  AppOwnedStorageTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import Testing
@testable import SnapDrillCore

@Suite("App-owned storage root")
struct AppOwnedStorageTests {
    @Test("Injected Application Support URL resolves the exact product root without I/O")
    func injectedRootIsExactAndSideEffectFree() throws {
        let support = FileManager.default.temporaryDirectory
            .appendingPathComponent("missing-\(UUID().uuidString)", isDirectory: true)
        let storage = try AppOwnedStorage(applicationSupportDirectory: support)

        #expect(storage.rootURL == support.appendingPathComponent("com.snapdrill.global", isDirectory: true))
        #expect(!FileManager.default.fileExists(atPath: support.path))
    }

    @Test("FileManager resolution uses the user Application Support directory")
    func fileManagerResolutionUsesApplicationSupport() throws {
        let expectedSupport = try #require(
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        )

        let storage = try AppOwnedStorage(fileManager: .default)

        #expect(storage.applicationSupportDirectory == expectedSupport)
        #expect(storage.rootURL.lastPathComponent == AppOwnedStorage.directoryName)
    }

    @Test("Non-file Application Support URL fails closed")
    func nonFileURLIsRejected() throws {
        let remoteURL = try #require(URL(string: "https://example.com/support"))
        #expect(throws: AppOwnedStorageError.invalidApplicationSupportURL) {
            _ = try AppOwnedStorage(applicationSupportDirectory: remoteURL)
        }
    }
}
