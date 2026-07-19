//
//  CaptureDraftFileOperations.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Darwin
import Foundation

struct CaptureDraftFileOperations {
    var createDirectory: (URL) throws -> Void
    var fileExists: (URL) -> Bool
    var read: (URL) throws -> Data
    var remove: (URL) throws -> Void
    var move: (URL, URL) throws -> Void
    var synchronizeDirectory: (URL) throws -> Void
    var contents: (URL) throws -> [URL]
    var attributes: (URL) throws -> [FileAttributeKey: Any]

    static var live: Self {
        let fileManager = FileManager.default
        return Self(
            createDirectory: {
                try fileManager.createDirectory(
                    at: $0,
                    withIntermediateDirectories: true
                )
            },
            fileExists: { fileManager.fileExists(atPath: $0.path) },
            read: { try Data(contentsOf: $0) },
            remove: { try fileManager.removeItem(at: $0) },
            move: { try fileManager.moveItem(at: $0, to: $1) },
            synchronizeDirectory: { try Self.synchronizeDirectory(at: $0) },
            contents: {
                try fileManager.contentsOfDirectory(
                    at: $0,
                    includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
                    options: [.skipsSubdirectoryDescendants]
                )
            },
            attributes: { try fileManager.attributesOfItem(atPath: $0.path) }
        )
    }

    private static func synchronizeDirectory(at url: URL) throws {
        let descriptor = url.path.withCString {
            Darwin.open($0, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        }
        guard descriptor >= 0 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
        }
        defer { _ = Darwin.close(descriptor) }

        while Darwin.fsync(descriptor) != 0 {
            let syncError = errno
            if syncError != EINTR {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(syncError))
            }
        }
    }

    func synchronizeDirectoryChain(
        storage: AppOwnedStorage,
        leafDirectory: URL
    ) throws {
        let applicationSupportParent = storage.applicationSupportDirectory
            .deletingLastPathComponent()
        for directory in [
            leafDirectory,
            storage.rootURL,
            storage.applicationSupportDirectory,
            applicationSupportParent
        ] {
            try synchronizeDirectory(directory)
        }
    }
}
