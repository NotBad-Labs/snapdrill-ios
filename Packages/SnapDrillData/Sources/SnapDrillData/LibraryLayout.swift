//
//  LibraryLayout.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation

/// Single-library filesystem contract.
///
/// SnapDrill owns these files on the user's behalf, so the production root is
/// under Application Support rather than the user-facing Documents directory.
nonisolated public struct LibraryLayout: Sendable {
    public let rootURL: URL

    public init(rootURL: URL? = nil) {
        if let rootURL {
            self.rootURL = rootURL
        } else {
            let applicationSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]
            self.rootURL = applicationSupport
                .appendingPathComponent("SnapDrill", isDirectory: true)
                .appendingPathComponent("Library", isDirectory: true)
        }
    }

    public var storeURL: URL {
        rootURL.appendingPathComponent("default.store")
    }

    public var imagesDirectoryURL: URL {
        rootURL.appendingPathComponent("images", isDirectory: true)
    }

    public var corruptedStoresDirectoryURL: URL {
        rootURL.appendingPathComponent("corrupted", isDirectory: true)
    }

    func prepareDirectories(fileManager: FileManager = .default) throws {
        try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: imagesDirectoryURL, withIntermediateDirectories: true)
    }
}
