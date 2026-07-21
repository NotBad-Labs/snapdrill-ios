//
//  CaptureDraftFilesystemMaintenance.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import CryptoKit
import Darwin
import Foundation

nonisolated enum CaptureDraftFilesystemMaintenance {
    static func observedNode(at url: URL, target: String) -> String? {
        var metadata = stat()
        let result = url.path.withCString { Darwin.lstat($0, &metadata) }
        guard result == 0 else { return nil }
        return "\(target):\(nodeObservation(metadata))"
    }

    static func observedNode(
        named name: String,
        in parentDescriptor: Int32,
        target: String
    ) -> String? {
        var metadata = stat()
        let result = name.withCString {
            Darwin.fstatat(parentDescriptor, $0, &metadata, AT_SYMLINK_NOFOLLOW)
        }
        guard result == 0 else { return nil }
        return "\(target):\(nodeObservation(metadata))"
    }

    static func nodeObservation(_ metadata: stat) -> String {
        let identity = "\(metadata.st_dev):\(metadata.st_ino):\(metadata.st_mode):"
            + "\(metadata.st_nlink):\(metadata.st_size):"
            + "\(metadata.st_mtimespec.tv_sec):\(metadata.st_mtimespec.tv_nsec)"
        let digest = SHA256.hash(data: Data(identity.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        return "node:\(digest)"
    }

    static func removeObservedNode(expectedObservation: String, root: URL) throws {
        let target: String
        let name: String
        let parentDescriptor: Int32
        if expectedObservation.hasPrefix("root:") {
            target = "root"
            name = root.lastPathComponent
            parentDescriptor = try openDirectory(root.deletingLastPathComponent())
        } else if expectedObservation.hasPrefix("drafts:") {
            target = "drafts"
            name = CaptureDraftFileStore.directoryName
            parentDescriptor = try openDirectory(root)
        } else {
            target = "current"
            name = CaptureDraftFileStore.fileName
            let rootDescriptor = try openDirectory(root)
            defer { _ = Darwin.close(rootDescriptor) }
            parentDescriptor = try openChildDirectory(
                named: CaptureDraftFileStore.directoryName,
                in: rootDescriptor
            )
        }

        defer { _ = Darwin.close(parentDescriptor) }
        try removeEntry(
            named: name,
            in: parentDescriptor,
            expectedObservation: expectedObservation,
            target: target
        )
        try synchronize(parentDescriptor)
    }

    static func removeStagingFile(named name: String, beneath root: URL) throws {
        guard isStagingName(name) else { throw CaptureDraftError.storageFailure }
        let rootDescriptor = try openDirectory(root)
        defer { _ = Darwin.close(rootDescriptor) }
        let descriptor = try openChildDirectory(
            named: CaptureDraftFileStore.directoryName,
            in: rootDescriptor
        )
        defer { _ = Darwin.close(descriptor) }
        try removeEntry(named: name, in: descriptor, expectedObservation: nil, target: "")
        try synchronize(descriptor)
    }

    static func sweepStagingFiles(beneath root: URL) throws {
        let rootDescriptor: Int32
        do {
            rootDescriptor = try openDirectory(root)
        } catch let error as POSIXError where error.code == .ENOENT {
            return
        }
        defer { _ = Darwin.close(rootDescriptor) }

        let descriptor: Int32
        do {
            descriptor = try openChildDirectory(
                named: CaptureDraftFileStore.directoryName,
                in: rootDescriptor
            )
        } catch let error as POSIXError where error.code == .ENOENT {
            return
        }
        defer { _ = Darwin.close(descriptor) }

        let iteratorDescriptor = Darwin.dup(descriptor)
        guard iteratorDescriptor >= 0, let directory = Darwin.fdopendir(iteratorDescriptor) else {
            if iteratorDescriptor >= 0 { _ = Darwin.close(iteratorDescriptor) }
            throw CaptureDraftError.storageFailure
        }
        defer { Darwin.closedir(directory) }

        var removedAny = false
        while let entry = Darwin.readdir(directory) {
            let name = withUnsafePointer(to: &entry.pointee.d_name) {
                $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXNAMLEN) + 1) {
                    String(cString: $0)
                }
            }
            guard isStagingName(name), isRegularFile(named: name, in: descriptor) else { continue }
            try removeEntry(named: name, in: descriptor, expectedObservation: nil, target: "")
            removedAny = true
        }
        if removedAny { try synchronize(descriptor) }
    }

    private static func openDirectory(_ url: URL) throws -> Int32 {
        let flags = O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
        let (descriptor, openError) = url.path.withCString { path in
            let descriptor = Darwin.open(path, flags)
            return (descriptor, descriptor < 0 ? errno : 0)
        }
        guard descriptor >= 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: openError) ?? .EIO)
        }
        return descriptor
    }

    private static func openChildDirectory(named name: String, in parentDescriptor: Int32) throws -> Int32 {
        let flags = O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW_ANY | O_RESOLVE_BENEATH
        let (descriptor, openError) = name.withCString { pointer in
            let descriptor = Darwin.openat(parentDescriptor, pointer, flags)
            return (descriptor, descriptor < 0 ? errno : 0)
        }
        guard descriptor >= 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: openError) ?? .EIO)
        }
        return descriptor
    }

    private static func removeEntry(
        named name: String,
        in parentDescriptor: Int32,
        expectedObservation: String?,
        target: String
    ) throws {
        var metadata = stat()
        let (result, metadataError) = name.withCString { pointer in
            let result = Darwin.fstatat(parentDescriptor, pointer, &metadata, AT_SYMLINK_NOFOLLOW)
            return (result, result != 0 ? errno : 0)
        }
        if result != 0 {
            if metadataError == ENOENT { return }
            throw CaptureDraftError.storageFailure
        }
        if let expectedObservation,
           expectedObservation.hasPrefix("\(target):"),
           expectedObservation != "\(target):\(nodeObservation(metadata))" {
            throw CaptureDraftError.draftChanged
        }

        let flags = metadata.st_mode & S_IFMT == S_IFDIR ? AT_REMOVEDIR : 0
        let (unlinkResult, unlinkError) = name.withCString { pointer in
            let result = Darwin.unlinkat(parentDescriptor, pointer, flags)
            return (result, result != 0 ? errno : 0)
        }
        if unlinkResult != 0, unlinkError != ENOENT {
            throw CaptureDraftError.storageFailure
        }
    }

    private static func isRegularFile(named name: String, in descriptor: Int32) -> Bool {
        var metadata = stat()
        let result = name.withCString {
            Darwin.fstatat(descriptor, $0, &metadata, AT_SYMLINK_NOFOLLOW)
        }
        return result == 0 && metadata.st_mode & S_IFMT == S_IFREG && metadata.st_nlink == 1
    }

    private static func synchronize(_ descriptor: Int32) throws {
        while Darwin.fsync(descriptor) != 0 {
            if errno != EINTR { throw CaptureDraftError.storageFailure }
        }
    }

    private static func isStagingName(_ name: String) -> Bool {
        guard name.hasPrefix("current."), name.hasSuffix(".next") else { return false }
        let start = name.index(name.startIndex, offsetBy: "current.".count)
        let end = name.index(name.endIndex, offsetBy: -".next".count)
        return UUID(uuidString: String(name[start..<end])) != nil
    }
}
