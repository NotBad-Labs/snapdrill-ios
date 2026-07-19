//
//  DurableRegularFilePublisher.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Blocking old-or-new publication for caller-owned regular files.
//

import Darwin
import Foundation
/// Publishes immutable bytes through a caller-owned staging file.
///
/// External coordination must guarantee one writer. The publisher owns neither
/// staging-name allocation nor cleanup. A failure after the atomic rename is
/// deliberately reported as uncertain so callers reconcile instead of retrying.
public nonisolated struct DurableRegularFilePublisher {
    public nonisolated struct RelativeFile: Equatable, Sendable {
        public let parentComponents: [String]
        public let fileName: String

        public init(parentComponents: [String] = [], fileName: String) throws {
            for component in parentComponents {
                guard Self.isValidComponent(component) else {
                    throw DurableRegularFileLocationError.invalidComponent
                }
            }
            guard Self.isValidComponent(fileName) else {
                throw DurableRegularFileLocationError.invalidComponent
            }
            self.parentComponents = parentComponents
            self.fileName = fileName
        }

        private static func isValidComponent(_ component: String) -> Bool {
            guard !component.isEmpty,
                  component != ".",
                  component != "..",
                  !component.contains("/"),
                  !component.contains("\\") else {
                return false
            }
            return component.unicodeScalars.allSatisfy { scalar in
                scalar.value >= 0x20 && scalar.value != 0x7F
            }
        }
    }

    internal let systemCalls: DurableRegularFileSystemCalls
    internal let fileAttributes: DurableRegularFileAttributes
    public init() {
        systemCalls = .live
        fileAttributes = .live
    }

    internal init(
        systemCalls: DurableRegularFileSystemCalls,
        fileAttributes: DurableRegularFileAttributes = .live
    ) {
        self.systemCalls = systemCalls
        self.fileAttributes = fileAttributes
    }

    public func publish(
        _ bytes: Data,
        staging: RelativeFile,
        destination: RelativeFile,
        beneath trustRootURL: URL,
        isExcludedFromBackup: Bool
    ) throws {
        guard trustRootURL.isFileURL, staging != destination else {
            throw failure(step: .validateInput, renamed: false, code: EINVAL)
        }
        let request = PublicationRequest(
            bytes: bytes,
            staging: staging,
            destination: destination,
            root: trustRootURL,
            isExcludedFromBackup: isExcludedFromBackup
        )
        let parents = try openPublicationParents(request)
        defer {
            _ = systemCalls.close(parents.destination.descriptor)
            _ = systemCalls.close(parents.staging.descriptor)
        }

        let previousDestination = try inspectOptionalRegularNode(
            parentDescriptor: parents.destination.descriptor,
            name: destination.fileName,
            expectedDevice: parents.staging.identity.device,
            step: .inspectDestination
        )
        let stagingDescriptor = try createStagingFile(
            parentDescriptor: parents.staging.descriptor,
            name: staging.fileName
        )
        defer { _ = systemCalls.close(stagingDescriptor) }

        let stagingNode = try prepareStagingFile(
            request,
            descriptor: stagingDescriptor,
            parent: parents.staging
        )
        try revalidateDestination(
            previousDestination,
            parentDescriptor: parents.destination.descriptor,
            name: destination.fileName,
            expectedDevice: parents.staging.identity.device
        )
        try commit(
            staging: staging,
            stagingNode: stagingNode,
            destination: destination,
            parents: parents
        )
        try verifyCommittedFile(
            request,
            stagingNode: stagingNode,
            parent: parents.destination
        )
    }
}

nonisolated extension DurableRegularFilePublisher {
    func openPublicationParents(_ request: PublicationRequest) throws -> PublicationParents {
        let stagingParent = try openParent(
            beneath: request.root,
            components: request.staging.parentComponents,
            step: .openStagingParent
        )
        do {
            let destinationParent = try openParent(
                beneath: request.root,
                components: request.destination.parentComponents,
                step: .openDestinationParent
            )
            guard stagingParent.rootIdentity == destinationParent.rootIdentity,
                  stagingParent.identity.device == destinationParent.identity.device else {
                _ = systemCalls.close(destinationParent.descriptor)
                throw failure(step: .verifySameFilesystem, renamed: false, code: EXDEV)
            }
            return PublicationParents(staging: stagingParent, destination: destinationParent)
        } catch {
            _ = systemCalls.close(stagingParent.descriptor)
            throw error
        }
    }

    func prepareStagingFile(
        _ request: PublicationRequest,
        descriptor: Int32,
        parent: OpenedParent
    ) throws -> InspectedNode {
        try writeAll(request.bytes, to: descriptor)
        var node = try inspectRegularDescriptor(
            descriptor,
            expectedDevice: parent.identity.device,
            expectedByteCount: request.bytes.count,
            step: .inspectStagingFile
        )
        try verifyPathIdentity(
            parentDescriptor: parent.descriptor,
            name: request.staging.fileName,
            expected: node,
            step: .inspectStagingFile
        )
        try synchronizeRegularFile(descriptor, step: .synchronizeStagingBytes)
        try applyAndVerifyAttributes(
            request,
            parent: parent,
            expectedNode: node,
            descriptor: descriptor
        )
        node = try inspectRegularDescriptor(
            descriptor,
            expectedDevice: parent.identity.device,
            expectedByteCount: request.bytes.count,
            step: .verifyStagingNode
        )
        try verifyPathIdentity(
            parentDescriptor: parent.descriptor,
            name: request.staging.fileName,
            expected: node,
            step: .verifyStagingNode
        )
        return node
    }

    func commit(
        staging: RelativeFile,
        stagingNode: InspectedNode,
        destination: RelativeFile,
        parents: PublicationParents
    ) throws {
        try verifyPathIdentity(
            parentDescriptor: parents.staging.descriptor,
            name: staging.fileName,
            expected: stagingNode,
            step: .verifyStagingNode
        )
        let result = staging.fileName.withCString { stagingName in
            destination.fileName.withCString { destinationName in
                systemCalls.renameAt(
                    parents.staging.descriptor,
                    stagingName,
                    parents.destination.descriptor,
                    destinationName,
                    Self.strictRenameFlags
                )
            }
        }
        guard result == 0 else {
            throw failure(step: .rename, renamed: false)
        }
        try synchronizeParent(
            parents.staging.descriptor,
            step: .synchronizeStagingParent,
            renamed: true
        )
        try synchronizeParent(
            parents.destination.descriptor,
            step: .synchronizeDestinationParent,
            renamed: true
        )
    }

    func verifyCommittedFile(
        _ request: PublicationRequest,
        stagingNode: InspectedNode,
        parent: OpenedParent
    ) throws {
        let descriptor = try openFinalFile(
            parentDescriptor: parent.descriptor,
            name: request.destination.fileName
        )
        defer { _ = systemCalls.close(descriptor) }

        let finalNode = try inspectRegularDescriptor(
            descriptor,
            expectedDevice: stagingNode.identity.device,
            expectedByteCount: request.bytes.count,
            step: .verifyFinalNode,
            renamed: true
        )
        guard finalNode.identity == stagingNode.identity else {
            throw failure(step: .verifyFinalNode, renamed: true, code: EIO)
        }
        try verifyBytes(request.bytes, from: descriptor)

        let binding = FoundationPathBinding(
            request: request,
            location: request.destination,
            parent: parent,
            expectedNode: finalNode
        )
        let attributesMatch = try withVerifiedFoundationPath(
            binding,
            step: .verifyFinalAttributes,
            renamed: true
        ) {
            try fileAttributes.verify($0, request.isExcludedFromBackup)
        }
        guard attributesMatch else {
            throw failure(step: .verifyFinalAttributes, renamed: true, code: EIO)
        }
    }

    func synchronizeRegularFile(
        _ descriptor: Int32,
        step: DurableRegularFilePublicationError.Step
    ) throws {
        var fullSyncError: Int32
        while true {
            if systemCalls.fullSync(descriptor) == 0 {
                return
            }
            fullSyncError = errno
            if fullSyncError != EINTR {
                break
            }
        }
        guard fullSyncError == ENOTSUP || fullSyncError == EINVAL else {
            throw failure(step: step, renamed: false, code: fullSyncError)
        }
        while systemCalls.sync(descriptor) != 0 {
            let syncError = errno
            if syncError != EINTR {
                throw failure(step: step, renamed: false, code: syncError)
            }
        }
    }

    private func synchronizeParent(
        _ descriptor: Int32,
        step: DurableRegularFilePublicationError.Step,
        renamed: Bool
    ) throws {
        while systemCalls.sync(descriptor) != 0 {
            let syncError = errno
            if syncError != EINTR {
                throw failure(step: step, renamed: renamed, code: syncError)
            }
        }
    }

    func inspectDirectoryDescriptor(
        _ descriptor: Int32,
        expectedDevice: dev_t?,
        step: DurableRegularFilePublicationError.Step,
        renamed: Bool = false
    ) throws -> InspectedNode {
        var metadata = stat()
        guard systemCalls.stat(descriptor, &metadata) == 0 else {
            throw failure(step: step, renamed: renamed)
        }
        guard metadata.st_mode & S_IFMT == S_IFDIR,
              expectedDevice == nil || metadata.st_dev == expectedDevice else {
            throw failure(step: step, renamed: renamed, code: EINVAL)
        }
        return InspectedNode(metadata: metadata)
    }

    private func inspectRegularDescriptor(
        _ descriptor: Int32,
        expectedDevice: dev_t,
        expectedByteCount: Int,
        step: DurableRegularFilePublicationError.Step,
        renamed: Bool = false
    ) throws -> InspectedNode {
        var metadata = stat()
        guard systemCalls.stat(descriptor, &metadata) == 0 else {
            throw failure(step: step, renamed: renamed)
        }
        guard metadata.st_mode & S_IFMT == S_IFREG,
              metadata.st_nlink == 1,
              metadata.st_dev == expectedDevice,
              metadata.st_size >= 0,
              UInt64(metadata.st_size) == UInt64(expectedByteCount) else {
            throw failure(step: step, renamed: renamed, code: EINVAL)
        }
        return InspectedNode(metadata: metadata)
    }

    private func inspectOptionalRegularNode(
        parentDescriptor: Int32,
        name: String,
        expectedDevice: dev_t,
        step: DurableRegularFilePublicationError.Step
    ) throws -> InspectedNode? {
        var metadata = stat()
        let result = name.withCString { fileName in
            systemCalls.statAt(parentDescriptor, fileName, &metadata, Self.strictLookupFlags)
        }
        if result != 0 {
            if errno == ENOENT {
                return nil
            }
            throw failure(step: step, renamed: false)
        }
        guard metadata.st_mode & S_IFMT == S_IFREG,
              metadata.st_nlink == 1,
              metadata.st_dev == expectedDevice else {
            throw failure(step: step, renamed: false, code: EINVAL)
        }
        return InspectedNode(metadata: metadata)
    }

    func verifyPathIdentity(
        parentDescriptor: Int32,
        name: String,
        expected: InspectedNode,
        step: DurableRegularFilePublicationError.Step,
        renamed: Bool = false
    ) throws {
        var metadata = stat()
        let result = name.withCString { fileName in
            systemCalls.statAt(parentDescriptor, fileName, &metadata, Self.strictLookupFlags)
        }
        guard result == 0 else {
            throw failure(step: step, renamed: renamed)
        }
        let observed = InspectedNode(metadata: metadata)
        guard observed.identity == expected.identity,
              observed.isRegularFile,
              observed.linkCount == 1,
              observed.byteCount == expected.byteCount else {
            throw failure(step: step, renamed: renamed, code: EINVAL)
        }
    }

    private func revalidateDestination(
        _ previous: InspectedNode?,
        parentDescriptor: Int32,
        name: String,
        expectedDevice: dev_t
    ) throws {
        let current = try inspectOptionalRegularNode(
            parentDescriptor: parentDescriptor,
            name: name,
            expectedDevice: expectedDevice,
            step: .revalidateDestination
        )
        guard current?.identity == previous?.identity else {
            throw failure(step: .revalidateDestination, renamed: false, code: EBUSY)
        }
    }

    func fileURL(root: URL, location: RelativeFile) -> URL {
        location.parentComponents.reduce(root) { partialURL, component in
            partialURL.appendingPathComponent(component, isDirectory: true)
        }.appendingPathComponent(location.fileName, isDirectory: false)
    }

    static var strictLookupFlags: Int32 {
        AT_SYMLINK_NOFOLLOW_ANY | AT_RESOLVE_BENEATH | AT_UNIQUE
    }

    static var strictRenameFlags: UInt32 {
        UInt32(RENAME_NOFOLLOW_ANY | RENAME_RESOLVE_BENEATH)
    }

    func failure(
        step: DurableRegularFilePublicationError.Step,
        renamed: Bool,
        code: Int32? = nil
    ) -> DurableRegularFilePublicationError {
        DurableRegularFilePublicationError(
            outcome: renamed ? .publicationOutcomeUncertain : .notPublished,
            step: step,
            code: code ?? errno
        )
    }

    func failure(
        step: DurableRegularFilePublicationError.Step,
        renamed: Bool,
        error: Error
    ) -> DurableRegularFilePublicationError {
        let nsError = error as NSError
        return failure(
            step: step,
            renamed: renamed,
            code: Int32(exactly: nsError.code) ?? EIO
        )
    }
}
