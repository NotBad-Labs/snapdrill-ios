//
//  MetricDiagnosticsStore+Filesystem.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Darwin
import Foundation

nonisolated extension MetricDiagnosticsStore {
    func openBoundDirectories(
        beneath rootURL: URL,
        createIfMissing: Bool
    ) throws -> MetricDiagnosticsBoundDirectories {
        let path = try resolveStoragePath(rootURL)
        let rootFlags = O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
        let anchorDescriptor = fileSystem.open(path.anchorURL.path, rootFlags)
        guard anchorDescriptor >= 0 else {
            throw failure(step: .openDirectory)
        }

        var openedDirectories: [MetricDiagnosticsOpenedDirectory] = []
        do {
            let anchorIdentity = try inspectDirectory(
                anchorDescriptor,
                expectedDevice: nil,
                step: .inspectDirectory
            )
            let applicationSupport = try openChildDirectory(
                named: path.applicationSupportName,
                in: anchorDescriptor,
                rootDevice: anchorIdentity.device,
                createIfMissing: createIfMissing
            )
            openedDirectories.append(applicationSupport)
            let root = try openChildDirectory(
                named: path.rootName,
                in: applicationSupport.descriptor,
                rootDevice: anchorIdentity.device,
                createIfMissing: createIfMissing
            )
            openedDirectories.append(root)
            let diagnostics = try openChildDirectory(
                named: Self.diagnosticsDirectoryName,
                in: root.descriptor,
                rootDevice: anchorIdentity.device,
                createIfMissing: createIfMissing
            )
            openedDirectories.append(diagnostics)
            let metricKit = try openChildDirectory(
                named: Self.metricKitDirectoryName,
                in: diagnostics.descriptor,
                rootDevice: anchorIdentity.device,
                createIfMissing: createIfMissing
            )
            return MetricDiagnosticsBoundDirectories(
                rootURL: rootURL,
                anchorDescriptor: anchorDescriptor,
                anchorIdentity: anchorIdentity,
                applicationSupportDescriptor: applicationSupport.descriptor,
                applicationSupportIdentity: applicationSupport.identity,
                rootDescriptor: root.descriptor,
                rootIdentity: root.identity,
                diagnosticsDescriptor: diagnostics.descriptor,
                diagnosticsIdentity: diagnostics.identity,
                metricKitDescriptor: metricKit.descriptor,
                metricKitIdentity: metricKit.identity
            )
        } catch {
            for directory in openedDirectories.reversed() {
                _ = fileSystem.close(directory.descriptor)
            }
            _ = fileSystem.close(anchorDescriptor)
            throw error
        }
    }

    func resolveStoragePath(_ rootURL: URL) throws -> MetricDiagnosticsStoragePath {
        let applicationSupportURL = rootURL.deletingLastPathComponent()
        let path = MetricDiagnosticsStoragePath(
            anchorURL: applicationSupportURL.deletingLastPathComponent(),
            applicationSupportName: applicationSupportURL.lastPathComponent,
            rootName: rootURL.lastPathComponent
        )
        guard rootURL.isFileURL,
              !path.applicationSupportName.isEmpty,
              !path.rootName.isEmpty else {
            throw failure(step: .resolveRoot, code: EINVAL)
        }
        return path
    }

    func openChildDirectory(
        named name: String,
        in parentDescriptor: Int32,
        rootDevice: dev_t,
        createIfMissing: Bool
    ) throws -> MetricDiagnosticsOpenedDirectory {
        var wasCreated = false
        if createIfMissing {
            let result = fileSystem.makeDirectoryAt(parentDescriptor, name, S_IRWXU)
            if result != 0, errno != EEXIST {
                throw failure(step: .createDirectory)
            }
            wasCreated = result == 0
        }
        let flags = O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW_ANY | O_RESOLVE_BENEATH
        let descriptor = fileSystem.openAt(parentDescriptor, name, flags)
        guard descriptor >= 0 else {
            throw failure(step: .openDirectory)
        }
        do {
            let identity = try inspectDirectory(
                descriptor,
                expectedDevice: rootDevice,
                step: .inspectDirectory
            )
            if wasCreated {
                try synchronize(parentDescriptor, step: .synchronizeDirectory)
            }
            return MetricDiagnosticsOpenedDirectory(descriptor: descriptor, identity: identity)
        } catch {
            _ = fileSystem.close(descriptor)
            throw error
        }
    }

    func inspectDirectory(
        _ descriptor: Int32,
        expectedDevice: dev_t?,
        step: MetricDiagnosticsStoreError.Step
    ) throws -> MetricDiagnosticsIdentity {
        var metadata = stat()
        guard fileSystem.stat(descriptor, &metadata) == 0 else {
            throw failure(step: step)
        }
        let node = MetricDiagnosticsNode(metadata: metadata)
        guard node.isDirectory,
              expectedDevice == nil || node.identity.device == expectedDevice else {
            throw failure(step: step, code: EXDEV)
        }
        return node.identity
    }

    func applyAndVerifyDirectoryAttributes(
        _ directories: MetricDiagnosticsBoundDirectories
    ) throws {
        try verifyPathBinding(directories)
        do {
            try fileAttributes.apply(directories.diagnosticsDescriptor)
            try fileAttributes.apply(directories.metricKitDescriptor)
        } catch let error as MetricDiagnosticsPOSIXError {
            throw failure(step: .applyDirectoryAttributes, code: error.code)
        } catch {
            throw failure(step: .applyDirectoryAttributes, code: EIO)
        }
        try verifyPathBinding(directories)
        do {
            guard try fileAttributes.verify(directories.diagnosticsDescriptor),
                  try fileAttributes.verify(directories.metricKitDescriptor) else {
                throw failure(step: .verifyDirectoryAttributes, code: EIO)
            }
        } catch let error as MetricDiagnosticsStoreError {
            throw error
        } catch let error as MetricDiagnosticsPOSIXError {
            throw failure(step: .verifyDirectoryAttributes, code: error.code)
        } catch {
            throw failure(step: .verifyDirectoryAttributes, code: EIO)
        }
        try verifyPathBinding(directories)
        try synchronize(directories.diagnosticsDescriptor, step: .synchronizeDirectory)
        try synchronize(directories.metricKitDescriptor, step: .synchronizeDirectory)
    }

    func verifyPathBinding(_ expected: MetricDiagnosticsBoundDirectories) throws {
        let observed = try openBoundDirectories(
            beneath: expected.rootURL,
            createIfMissing: false
        )
        defer { observed.close(using: fileSystem) }
        guard observed.anchorIdentity == expected.anchorIdentity,
              observed.applicationSupportIdentity == expected.applicationSupportIdentity,
              observed.rootIdentity == expected.rootIdentity,
              observed.diagnosticsIdentity == expected.diagnosticsIdentity,
              observed.metricKitIdentity == expected.metricKitIdentity else {
            throw failure(step: .verifyBinding, code: EBUSY)
        }
    }

    func inspectOwnedRegularFile(
        named name: String,
        in descriptor: Int32,
        step: MetricDiagnosticsStoreError.Step
    ) throws -> MetricDiagnosticsNode {
        var metadata = stat()
        guard fileSystem.statAt(descriptor, name, &metadata, AT_SYMLINK_NOFOLLOW) == 0 else {
            throw failure(step: step)
        }
        let node = MetricDiagnosticsNode(metadata: metadata)
        guard node.isOwnedRegularFile else {
            throw failure(step: step, code: EINVAL)
        }
        return node
    }

    func removeOwnedRegularFile(
        named name: String,
        in descriptor: Int32,
        step: MetricDiagnosticsStoreError.Step
    ) throws {
        _ = try inspectOwnedRegularFile(named: name, in: descriptor, step: step)
        guard fileSystem.unlinkAt(descriptor, name, Self.secureUnlinkFlags) == 0 else {
            throw failure(step: step)
        }
        try synchronize(descriptor, step: .synchronizeDirectory)
    }

    func synchronize(
        _ descriptor: Int32,
        step: MetricDiagnosticsStoreError.Step
    ) throws {
        while fileSystem.synchronize(descriptor) != 0 {
            if errno != EINTR {
                throw failure(step: step)
            }
        }
    }
}

nonisolated struct MetricDiagnosticsIdentity: Equatable {
    let device: dev_t
    let inode: ino_t
}

nonisolated struct MetricDiagnosticsNode {
    let identity: MetricDiagnosticsIdentity
    let mode: mode_t
    let linkCount: nlink_t
    let byteCount: off_t

    init(metadata: stat) {
        identity = MetricDiagnosticsIdentity(device: metadata.st_dev, inode: metadata.st_ino)
        mode = metadata.st_mode
        linkCount = metadata.st_nlink
        byteCount = metadata.st_size
    }

    var isDirectory: Bool { mode & S_IFMT == S_IFDIR }

    var isOwnedRegularFile: Bool {
        mode & S_IFMT == S_IFREG && linkCount == 1 && byteCount >= 0
    }
}

nonisolated struct MetricDiagnosticsOpenedDirectory {
    let descriptor: Int32
    let identity: MetricDiagnosticsIdentity
}

nonisolated struct MetricDiagnosticsStoragePath {
    let anchorURL: URL
    let applicationSupportName: String
    let rootName: String
}

nonisolated struct MetricDiagnosticsBoundDirectories {
    let rootURL: URL
    let anchorDescriptor: Int32
    let anchorIdentity: MetricDiagnosticsIdentity
    let applicationSupportDescriptor: Int32
    let applicationSupportIdentity: MetricDiagnosticsIdentity
    let rootDescriptor: Int32
    let rootIdentity: MetricDiagnosticsIdentity
    let diagnosticsDescriptor: Int32
    let diagnosticsIdentity: MetricDiagnosticsIdentity
    let metricKitDescriptor: Int32
    let metricKitIdentity: MetricDiagnosticsIdentity

    func close(using fileSystem: MetricDiagnosticsFileSystem) {
        _ = fileSystem.close(metricKitDescriptor)
        _ = fileSystem.close(diagnosticsDescriptor)
        _ = fileSystem.close(rootDescriptor)
        _ = fileSystem.close(applicationSupportDescriptor)
        _ = fileSystem.close(anchorDescriptor)
    }
}

nonisolated struct MetricDiagnosticsPOSIXError: Error, Equatable, Sendable {
    let code: Int32
}

nonisolated struct MetricDiagnosticsDirectoryAttributes: @unchecked Sendable {
    var apply: (_ descriptor: Int32) throws -> Void
    var verify: (_ descriptor: Int32) throws -> Bool

    static var live: Self {
        return Self(
            apply: Self.applyLive,
            verify: Self.verifyLive
        )
    }
}

nonisolated extension MetricDiagnosticsDirectoryAttributes {
    private static let protectionClassC: UInt32 = 3
    private static let backupExclusionAttribute = "com.apple.metadata:com_apple_backup_excludeItem"

    private static func applyLive(_ descriptor: Int32) throws {
        var attributes = protectionAttributeList()
        var protectionClass = protectionClassC
        guard Darwin.fsetattrlist(
            descriptor,
            &attributes,
            &protectionClass,
            MemoryLayout.size(ofValue: protectionClass),
            0
        ) == 0 else {
            throw MetricDiagnosticsPOSIXError(code: errno)
        }
        let value = try backupExclusionValue()
        let call = value.withUnsafeBytes { buffer in
            MetricDiagnosticsPOSIX.call(backupExclusionAttribute) { name in
                Darwin.fsetxattr(descriptor, name, buffer.baseAddress, buffer.count, 0, 0)
            }
        }
        guard call.value == 0 else {
            throw MetricDiagnosticsPOSIXError(code: call.code)
        }
    }

    private static func verifyLive(_ descriptor: Int32) throws -> Bool {
        var attributes = protectionAttributeList()
        var result = MetricDiagnosticsProtectionClassResult()
        guard Darwin.fgetattrlist(
            descriptor,
            &attributes,
            &result,
            MemoryLayout.size(ofValue: result),
            0
        ) == 0 else {
            throw MetricDiagnosticsPOSIXError(code: errno)
        }
        guard result.length == UInt32(MemoryLayout.size(ofValue: result)),
              result.protectionClass == protectionClassC else {
            return false
        }
        return try readBackupExclusionValue(descriptor) == backupExclusionValue()
    }

    private static func protectionAttributeList() -> attrlist {
        var attributes = attrlist()
        attributes.bitmapcount = UInt16(ATTR_BIT_MAP_COUNT)
        attributes.commonattr = UInt32(ATTR_CMN_DATA_PROTECT_FLAGS)
        return attributes
    }

    private static func backupExclusionValue() throws -> Data {
        try PropertyListSerialization.data(
            fromPropertyList: "com.apple.backupd",
            format: .binary,
            options: 0
        )
    }

    private static func readBackupExclusionValue(_ descriptor: Int32) throws -> Data {
        let lengthCall = MetricDiagnosticsPOSIX.call(backupExclusionAttribute) { name in
            Darwin.fgetxattr(descriptor, name, nil, 0, 0, 0)
        }
        guard lengthCall.value >= 0 else {
            throw MetricDiagnosticsPOSIXError(code: lengthCall.code)
        }
        let length = lengthCall.value
        var bytes = [UInt8](repeating: 0, count: length)
        let readCall = bytes.withUnsafeMutableBytes { buffer in
            MetricDiagnosticsPOSIX.call(backupExclusionAttribute) { name in
                Darwin.fgetxattr(descriptor, name, buffer.baseAddress, buffer.count, 0, 0)
            }
        }
        guard readCall.value == length else {
            throw MetricDiagnosticsPOSIXError(code: readCall.value < 0 ? readCall.code : EIO)
        }
        return Data(bytes)
    }
}

nonisolated private struct MetricDiagnosticsProtectionClassResult {
    var length: UInt32 = 0
    var protectionClass: UInt32 = 0
}
