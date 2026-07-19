//
//  AppOwnedStorage.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  App-owned storage root resolution without filesystem side effects.
//

import Foundation

/// Resolves the product-owned directory beneath Application Support.
public nonisolated struct AppOwnedStorage: Sendable {
    public static let directoryName = "com.snapdrill.global"

    public let applicationSupportDirectory: URL

    public init(applicationSupportDirectory: URL) throws {
        guard applicationSupportDirectory.isFileURL else {
            throw AppOwnedStorageError.invalidApplicationSupportURL
        }
        self.applicationSupportDirectory = applicationSupportDirectory
    }

    public init(fileManager: FileManager = .default) throws {
        guard let applicationSupportDirectory = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw AppOwnedStorageError.applicationSupportDirectoryUnavailable
        }
        try self.init(applicationSupportDirectory: applicationSupportDirectory)
    }

    public var rootURL: URL {
        applicationSupportDirectory.appendingPathComponent(Self.directoryName, isDirectory: true)
    }
}

public nonisolated enum AppOwnedStorageError: Error, Equatable, Sendable {
    case applicationSupportDirectoryUnavailable
    case invalidApplicationSupportURL
}
