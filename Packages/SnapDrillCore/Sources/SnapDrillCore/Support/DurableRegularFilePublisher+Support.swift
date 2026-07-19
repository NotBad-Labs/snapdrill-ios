//
//  DurableRegularFilePublisher+Support.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Darwin
import Foundation

nonisolated extension DurableRegularFilePublisher {
    func openParent(
        beneath trustRootURL: URL,
        components: [String],
        step: DurableRegularFilePublicationError.Step,
        renamed: Bool = false
    ) throws -> OpenedParent {
        let rootFlags = O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
        let rootDescriptor = trustRootURL.path.withCString { systemCalls.open($0, rootFlags) }
        guard rootDescriptor >= 0 else {
            throw failure(step: step, renamed: renamed)
        }

        var currentDescriptor = rootDescriptor
        do {
            let rootNode = try inspectDirectoryDescriptor(
                rootDescriptor,
                expectedDevice: nil,
                step: step,
                renamed: renamed
            )
            var currentNode = rootNode
            let parentFlags = O_RDONLY | O_DIRECTORY | O_CLOEXEC
                | O_NOFOLLOW_ANY | O_RESOLVE_BENEATH
            for component in components {
                let nextDescriptor = component.withCString {
                    systemCalls.openAt(currentDescriptor, $0, parentFlags)
                }
                guard nextDescriptor >= 0 else {
                    throw failure(step: step, renamed: renamed)
                }
                let nextNode: InspectedNode
                do {
                    nextNode = try inspectDirectoryDescriptor(
                        nextDescriptor,
                        expectedDevice: rootNode.identity.device,
                        step: step,
                        renamed: renamed
                    )
                } catch {
                    _ = systemCalls.close(nextDescriptor)
                    throw error
                }
                _ = systemCalls.close(currentDescriptor)
                currentDescriptor = nextDescriptor
                currentNode = nextNode
            }
            return OpenedParent(
                descriptor: currentDescriptor,
                rootIdentity: rootNode.identity,
                identity: currentNode.identity
            )
        } catch {
            _ = systemCalls.close(currentDescriptor)
            throw error
        }
    }

    func createStagingFile(parentDescriptor: Int32, name: String) throws -> Int32 {
        let flags = O_RDWR | O_CREAT | O_EXCL | O_CLOEXEC
            | O_NOFOLLOW_ANY | O_RESOLVE_BENEATH
        let descriptor = name.withCString {
            systemCalls.createAt(parentDescriptor, $0, flags, S_IRUSR | S_IWUSR)
        }
        guard descriptor >= 0 else {
            throw failure(step: .createStagingFile, renamed: false)
        }
        return descriptor
    }

    func openFinalFile(parentDescriptor: Int32, name: String) throws -> Int32 {
        let flags = O_RDONLY | O_CLOEXEC | O_NOFOLLOW_ANY | O_RESOLVE_BENEATH | O_UNIQUE
        let descriptor = name.withCString { systemCalls.openAt(parentDescriptor, $0, flags) }
        guard descriptor >= 0 else {
            throw failure(step: .openFinalFile, renamed: true)
        }
        return descriptor
    }

    func writeAll(_ bytes: Data, to descriptor: Int32) throws {
        try bytes.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else {
                return
            }
            var offset = 0
            while offset < buffer.count {
                let requested = min(buffer.count - offset, Int(Int32.max))
                let result = systemCalls.write(
                    descriptor,
                    baseAddress.advanced(by: offset),
                    requested
                )
                if result > 0, result <= requested {
                    offset += result
                } else if result == 0 || result > requested {
                    throw failure(step: .writeStagingBytes, renamed: false, code: EIO)
                } else if errno != EINTR {
                    throw failure(step: .writeStagingBytes, renamed: false)
                }
            }
        }
    }

    func verifyBytes(_ expected: Data, from descriptor: Int32) throws {
        var buffer = [UInt8](repeating: 0, count: max(1, min(64 * 1024, expected.count)))
        var offset = 0
        while offset < expected.count {
            let requested = min(buffer.count, expected.count - offset)
            let readCount = buffer.withUnsafeMutableBytes {
                systemCalls.read(descriptor, $0.baseAddress, requested)
            }
            if readCount > 0, readCount <= requested {
                let matches = expected.withUnsafeBytes { expectedBuffer in
                    buffer.withUnsafeBytes { observedBuffer in
                        guard let expectedBase = expectedBuffer.baseAddress,
                              let observedBase = observedBuffer.baseAddress else {
                            return false
                        }
                        return memcmp(
                            expectedBase.advanced(by: offset),
                            observedBase,
                            readCount
                        ) == 0
                    }
                }
                guard matches else {
                    throw failure(step: .verifyFinalBytes, renamed: true, code: EIO)
                }
                offset += readCount
            } else if readCount == 0 || readCount > requested {
                throw failure(step: .verifyFinalBytes, renamed: true, code: EIO)
            } else if errno != EINTR {
                throw failure(step: .verifyFinalBytes, renamed: true)
            }
        }

        var extraByte: UInt8 = 0
        while true {
            let readCount = systemCalls.read(descriptor, &extraByte, 1)
            if readCount == 0 {
                return
            }
            if readCount > 0 {
                throw failure(step: .verifyFinalBytes, renamed: true, code: EIO)
            }
            if errno != EINTR {
                throw failure(step: .verifyFinalBytes, renamed: true)
            }
        }
    }

    func applyAndVerifyAttributes(
        _ request: PublicationRequest,
        parent: OpenedParent,
        expectedNode: InspectedNode,
        descriptor: Int32
    ) throws {
        let binding = FoundationPathBinding(
            request: request,
            location: request.staging,
            parent: parent,
            expectedNode: expectedNode
        )
        try withVerifiedFoundationPath(
            binding,
            step: .applyProtection
        ) {
            try fileAttributes.setProtection($0)
        }
        try withVerifiedFoundationPath(
            binding,
            step: .applyBackupPolicy
        ) {
            try fileAttributes.setBackupExclusion($0, request.isExcludedFromBackup)
        }
        try synchronizeRegularFile(descriptor, step: .synchronizeStagingAttributes)
        let attributesMatch = try withVerifiedFoundationPath(
            binding,
            step: .verifyStagingAttributes
        ) {
            try fileAttributes.verify($0, request.isExcludedFromBackup)
        }
        guard attributesMatch else {
            throw failure(step: .verifyStagingAttributes, renamed: false, code: EIO)
        }
    }

    func withVerifiedFoundationPath<Value>(
        _ binding: FoundationPathBinding,
        step: DurableRegularFilePublicationError.Step,
        renamed: Bool = false,
        operation: (URL) throws -> Value
    ) throws -> Value {
        try verifyFoundationPathBinding(
            binding,
            step: step,
            renamed: renamed
        )
        let result: Value
        do {
            result = try operation(
                fileURL(root: binding.request.root, location: binding.location)
            )
        } catch {
            throw failure(step: step, renamed: renamed, error: error)
        }
        try verifyFoundationPathBinding(
            binding,
            step: step,
            renamed: renamed
        )
        return result
    }

    func verifyFoundationPathBinding(
        _ binding: FoundationPathBinding,
        step: DurableRegularFilePublicationError.Step,
        renamed: Bool
    ) throws {
        let reopened = try openParent(
            beneath: binding.request.root,
            components: binding.location.parentComponents,
            step: step,
            renamed: renamed
        )
        defer { _ = systemCalls.close(reopened.descriptor) }
        guard reopened.rootIdentity == binding.parent.rootIdentity,
              reopened.identity == binding.parent.identity else {
            throw failure(step: step, renamed: renamed, code: EBUSY)
        }
        try verifyPathIdentity(
            parentDescriptor: reopened.descriptor,
            name: binding.location.fileName,
            expected: binding.expectedNode,
            step: step,
            renamed: renamed
        )
    }
}

public nonisolated enum DurableRegularFileLocationError: Error, Equatable, Sendable {
    case invalidComponent
}

public nonisolated struct DurableRegularFilePublicationError: Error, Equatable, Sendable {
    public nonisolated enum Outcome: Equatable, Sendable {
        case notPublished
        case publicationOutcomeUncertain
    }

    public nonisolated enum Step: String, Equatable, Sendable {
        case validateInput
        case openStagingParent
        case openDestinationParent
        case verifySameFilesystem
        case inspectDestination
        case createStagingFile
        case writeStagingBytes
        case inspectStagingFile
        case synchronizeStagingBytes
        case applyProtection
        case applyBackupPolicy
        case synchronizeStagingAttributes
        case verifyStagingAttributes
        case verifyStagingNode
        case revalidateDestination
        case rename
        case synchronizeStagingParent
        case synchronizeDestinationParent
        case openFinalFile
        case verifyFinalNode
        case verifyFinalBytes
        case verifyFinalAttributes
    }

    public let outcome: Outcome
    public let step: Step
    public let code: Int32
}

internal nonisolated struct DurableRegularFileSystemCalls {
    var open: (_ path: UnsafePointer<CChar>, _ flags: Int32) -> Int32
    var openAt: (_ parent: Int32, _ path: UnsafePointer<CChar>, _ flags: Int32) -> Int32
    var createAt: (
        _ parent: Int32,
        _ path: UnsafePointer<CChar>,
        _ flags: Int32,
        _ mode: mode_t
    ) -> Int32
    var close: (_ descriptor: Int32) -> Int32
    var write: (_ descriptor: Int32, _ buffer: UnsafeRawPointer?, _ count: Int) -> Int
    var read: (_ descriptor: Int32, _ buffer: UnsafeMutableRawPointer?, _ count: Int) -> Int
    var stat: (_ descriptor: Int32, _ metadata: UnsafeMutablePointer<Darwin.stat>) -> Int32
    var statAt: (
        _ parent: Int32,
        _ path: UnsafePointer<CChar>,
        _ metadata: UnsafeMutablePointer<Darwin.stat>,
        _ flags: Int32
    ) -> Int32
    var fullSync: (_ descriptor: Int32) -> Int32
    var sync: (_ descriptor: Int32) -> Int32
    var renameAt: (
        _ oldParent: Int32,
        _ oldPath: UnsafePointer<CChar>,
        _ newParent: Int32,
        _ newPath: UnsafePointer<CChar>,
        _ flags: UInt32
    ) -> Int32

    static var live: Self {
        Self(
            open: { Darwin.open($0, $1) },
            openAt: { Darwin.openat($0, $1, $2) },
            createAt: { Darwin.openat($0, $1, $2, $3) },
            close: { Darwin.close($0) },
            write: { Darwin.write($0, $1, $2) },
            read: { Darwin.read($0, $1, $2) },
            stat: { Darwin.fstat($0, $1) },
            statAt: { Darwin.fstatat($0, $1, $2, $3) },
            fullSync: { Darwin.fcntl($0, F_FULLFSYNC) },
            sync: { Darwin.fsync($0) },
            renameAt: {
                Darwin.renameatx_np(
                    $0,
                    $1,
                    $2,
                    $3,
                    $4
                )
            }
        )
    }
}

internal nonisolated struct DurableRegularFileAttributes {
    var setProtection: (_ url: URL) throws -> Void
    var setBackupExclusion: (_ url: URL, _ isExcluded: Bool) throws -> Void
    var verify: (_ url: URL, _ isExcluded: Bool) throws -> Bool

    static var live: Self {
        let fileManager = FileManager.default
        return Self(
            setProtection: { url in
                try fileManager.setAttributes(
                    [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                    ofItemAtPath: url.path
                )
            },
            setBackupExclusion: { url, isExcluded in
                var mutableURL = url
                var values = URLResourceValues()
                values.isExcludedFromBackup = isExcluded
                try mutableURL.setResourceValues(values)
            },
            verify: { url, isExcluded in
                let attributes = try fileManager.attributesOfItem(atPath: url.path)
                let protection = attributes[.protectionKey] as? FileProtectionType
                let resourceValues = try url.resourceValues(forKeys: [.isExcludedFromBackupKey])
                #if targetEnvironment(simulator)
                // Simulator does not expose a data-protection readback oracle.
                let protectionMatches = protection == nil
                    || protection == .completeUntilFirstUserAuthentication
                #else
                let protectionMatches = protection == .completeUntilFirstUserAuthentication
                #endif
                return protectionMatches && resourceValues.isExcludedFromBackup == isExcluded
            }
        )
    }
}

internal nonisolated struct FileIdentity: Equatable {
    let device: dev_t
    let inode: ino_t
}

internal nonisolated struct PublicationRequest {
    let bytes: Data
    let staging: DurableRegularFilePublisher.RelativeFile
    let destination: DurableRegularFilePublisher.RelativeFile
    let root: URL
    let isExcludedFromBackup: Bool
}

internal nonisolated struct FoundationPathBinding {
    let request: PublicationRequest
    let location: DurableRegularFilePublisher.RelativeFile
    let parent: OpenedParent
    let expectedNode: InspectedNode
}

internal nonisolated struct PublicationParents {
    let staging: OpenedParent
    let destination: OpenedParent
}

internal nonisolated struct InspectedNode {
    let identity: FileIdentity
    let mode: mode_t
    let linkCount: nlink_t
    let byteCount: off_t

    init(metadata: stat) {
        identity = FileIdentity(device: metadata.st_dev, inode: metadata.st_ino)
        mode = metadata.st_mode
        linkCount = metadata.st_nlink
        byteCount = metadata.st_size
    }

    var isRegularFile: Bool {
        mode & S_IFMT == S_IFREG
    }
}

internal nonisolated struct OpenedParent {
    let descriptor: Int32
    let rootIdentity: FileIdentity
    let identity: FileIdentity
}
