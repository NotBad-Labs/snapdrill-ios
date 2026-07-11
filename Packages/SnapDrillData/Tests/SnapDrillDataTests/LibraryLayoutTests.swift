//
//  LibraryLayoutTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import Testing
@testable import SnapDrillData

struct LibraryLayoutTests {
    @Test("single-library paths have no Profile identity")
    func pathsHaveNoProfileIdentity() {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let layout = LibraryLayout(rootURL: root)

        #expect(layout.storeURL == root.appendingPathComponent("default.store"))
        #expect(layout.imagesDirectoryURL == root.appendingPathComponent("images", isDirectory: true))
        #expect(
            layout.corruptedStoresDirectoryURL
                == root.appendingPathComponent("corrupted", isDirectory: true)
        )
        #expect(!layout.storeURL.path.contains("profiles"))
    }

    @Test("prepare creates the library and image directories")
    func prepareDirectories() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let layout = LibraryLayout(rootURL: root)
        defer { try? FileManager.default.removeItem(at: root) }

        try layout.prepareDirectories()

        var isDirectory: ObjCBool = false
        #expect(FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory))
        #expect(isDirectory.boolValue)
        #expect(FileManager.default.fileExists(atPath: layout.imagesDirectoryURL.path))
    }
}
