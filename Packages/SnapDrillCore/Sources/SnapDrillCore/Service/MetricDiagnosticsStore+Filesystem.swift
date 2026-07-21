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
        guard rootURL.isFileURL else {
            throw failure(step: .resolveRoot, code: EINVAL)
        }
        if createIfMissing {
            do {
                try fileSystem.createDirectoryTree(rootURL)
            } catch let error as MetricDiagnosticsPOSIXError {
                throw failure(step: .createDirectory, code: error.code)
            } catch {
                throw failure(step: .createDirectory, code: EIO)
            }
        }

        let rootFlags = O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
        let rootDescriptor = fileSystem.open(rootURL.path, rootFlags)
        guard rootDescriptor >= 0 else {
            throw failure(step: .openDirectory)
        }

        do {
            let rootIdentity = try inspectDirectory(
                rootDescriptor,
                expectedDevice: nil,
                step: .inspectDirectory
            )
            let diagnostics = try openChildDirectory(
                named: Self.diagnosticsDirectoryName,
                in: rootDescriptor,
                rootDevice: rootIdentity.device,
                createIfMissing: createIfMissing
            )
            do {
                let metricKit = try openChildDirectory(
                    named: Self.metricKitDirectoryName,
                    in: diagnostics.descriptor,
                    rootDevice: rootIdentity.device,
                    createIfMissing: createIfMissing
                )
                return MetricDiagnosticsBoundDirectories(
                    rootURL: rootURL,
                    rootDescriptor: rootDescriptor,
                    rootIdentity: rootIdentity,
                    diagnosticsDescriptor: diagnostics.descriptor,
                    diagnosticsIdentity: diagnostics.identity,
                    metricKitDescriptor: metricKit.descriptor,
                    metricKitIdentity: metricKit.identity
                )
            } catch {
                _ = fileSystem.close(diagnostics.descriptor)
                throw error
            }
        } catch {
            _ = fileSystem.close(rootDescriptor)
            throw error
        }
    }

    func openChildDirectory(
        named name: String,
        in parentDescriptor: Int32,
        rootDevice: dev_t,
        createIfMissing: Bool
    ) throws -> MetricDiagnosticsOpenedDirectory {
        if createIfMissing {
            let result = fileSystem.makeDirectoryAt(parentDescriptor, name, S_IRWXU)
            if result != 0, errno != EEXIST {
                throw failure(step: .createDirectory)
            }
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
        guard observed.rootIdentity == expected.rootIdentity,
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
        guard fileSystem.unlinkAt(descriptor, name) == 0 else {
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

nonisolated struct MetricDiagnosticsBoundDirectories {
    let rootURL: URL
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

nonisolated struct MetricDiagnosticsFileSystem: @unchecked Sendable {
    var createDirectoryTree: (_ url: URL) throws -> Void
    var makeDirectoryAt: (_ parent: Int32, _ name: String, _ mode: mode_t) -> Int32
    var open: (_ path: String, _ flags: Int32) -> Int32
    var openAt: (_ parent: Int32, _ name: String, _ flags: Int32) -> Int32
    var createAt: (_ parent: Int32, _ name: String, _ flags: Int32, _ mode: mode_t) -> Int32
    var close: (_ descriptor: Int32) -> Int32
    var write: (_ descriptor: Int32, _ buffer: UnsafeRawPointer?, _ count: Int) -> Int
    var read: (_ descriptor: Int32, _ buffer: UnsafeMutableRawPointer?, _ count: Int) -> Int
    var stat: (_ descriptor: Int32, _ metadata: UnsafeMutablePointer<Darwin.stat>) -> Int32
    var statAt: (
        _ parent: Int32,
        _ name: String,
        _ metadata: UnsafeMutablePointer<Darwin.stat>,
        _ flags: Int32
    ) -> Int32
    var unlinkAt: (_ parent: Int32, _ name: String) -> Int32
    var renameAt: (_ parent: Int32, _ oldName: String, _ newName: String, _ flags: UInt32) -> Int32
    var fullSynchronize: (_ descriptor: Int32) -> Int32
    var synchronize: (_ descriptor: Int32) -> Int32
    var listNames: (_ descriptor: Int32) throws -> [String]

    static var live: Self {
        Self(
            createDirectoryTree: { url in
                do {
                    try FileManager.default.createDirectory(
                        at: url,
                        withIntermediateDirectories: true,
                        attributes: [.posixPermissions: NSNumber(value: S_IRWXU)]
                    )
                } catch {
                    throw MetricDiagnosticsPOSIXError(code: MetricDiagnosticsPOSIX.code(for: error))
                }
            },
            makeDirectoryAt: { parent, name, mode in
                MetricDiagnosticsPOSIX.restoringErrno(name) { Darwin.mkdirat(parent, $0, mode) }
            },
            open: { path, flags in
                MetricDiagnosticsPOSIX.restoringErrno(path) { Darwin.open($0, flags) }
            },
            openAt: { parent, name, flags in
                MetricDiagnosticsPOSIX.restoringErrno(name) { Darwin.openat(parent, $0, flags) }
            },
            createAt: { parent, name, flags, mode in
                MetricDiagnosticsPOSIX.restoringErrno(name) {
                    Darwin.openat(parent, $0, flags, mode)
                }
            },
            close: { Darwin.close($0) },
            write: { Darwin.write($0, $1, $2) },
            read: { Darwin.read($0, $1, $2) },
            stat: { Darwin.fstat($0, $1) },
            statAt: { parent, name, metadata, flags in
                MetricDiagnosticsPOSIX.restoringErrno(name) {
                    Darwin.fstatat(parent, $0, metadata, flags)
                }
            },
            unlinkAt: { parent, name in
                MetricDiagnosticsPOSIX.restoringErrno(name) { Darwin.unlinkat(parent, $0, 0) }
            },
            renameAt: { parent, oldName, newName, flags in
                MetricDiagnosticsPOSIX.restoringErrno(oldName, newName) { oldPath, newPath in
                    Darwin.renameatx_np(parent, oldPath, parent, newPath, flags)
                }
            },
            fullSynchronize: { Darwin.fcntl($0, F_FULLFSYNC) },
            synchronize: { Darwin.fsync($0) },
            listNames: Self.readNames
        )
    }

    private static func readNames(from descriptor: Int32) throws -> [String] {
        let iteratorDescriptor = Darwin.dup(descriptor)
        guard iteratorDescriptor >= 0 else {
            throw MetricDiagnosticsPOSIXError(code: errno)
        }
        guard let directory = Darwin.fdopendir(iteratorDescriptor) else {
            let code = errno
            _ = Darwin.close(iteratorDescriptor)
            throw MetricDiagnosticsPOSIXError(code: code)
        }
        defer { Darwin.closedir(directory) }

        var names: [String] = []
        while true {
            errno = 0
            guard let entry = Darwin.readdir(directory) else {
                if errno != 0 {
                    throw MetricDiagnosticsPOSIXError(code: errno)
                }
                return names
            }
            let name = withUnsafePointer(to: &entry.pointee.d_name) {
                $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXNAMLEN) + 1) {
                    String(cString: $0)
                }
            }
            if name != ".", name != ".." {
                names.append(name)
            }
        }
    }
}

nonisolated private enum MetricDiagnosticsPOSIX {
    static func call<Result>(
        _ text: String,
        operation: (UnsafePointer<CChar>) -> Result
    ) -> (value: Result, code: Int32) {
        text.withCString { pointer in
            let value = operation(pointer)
            return (value, errno)
        }
    }

    static func restoringErrno<Result>(
        _ text: String,
        operation: (UnsafePointer<CChar>) -> Result
    ) -> Result {
        let result = call(text, operation: operation)
        errno = result.code
        return result.value
    }

    static func restoringErrno<Result>(
        _ first: String,
        _ second: String,
        operation: (UnsafePointer<CChar>, UnsafePointer<CChar>) -> Result
    ) -> Result {
        let result = first.withCString { firstPointer in
            second.withCString { secondPointer in
                let value = operation(firstPointer, secondPointer)
                return (value: value, code: errno)
            }
        }
        errno = result.code
        return result.value
    }

    static func code(for error: Error) -> Int32 {
        let cocoaError = error as NSError
        if cocoaError.domain == NSPOSIXErrorDomain {
            return Int32(cocoaError.code)
        }
        if let underlying = cocoaError.userInfo[NSUnderlyingErrorKey] as? NSError,
           underlying.domain == NSPOSIXErrorDomain {
            return Int32(underlying.code)
        }
        return EIO
    }
}
