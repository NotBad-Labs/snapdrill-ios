//
//  MetricDiagnosticsStore+Publisher.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Darwin
import Foundation

nonisolated extension MetricDiagnosticsStore {
    func publish(
        _ bytes: Data,
        destinationName: String,
        inventory: MetricDiagnosticsInventory,
        directories: MetricDiagnosticsBoundDirectories
    ) throws {
        try verifyPathBinding(directories)
        let stagingDescriptor = try createStagingFile(in: directories.metricKitDescriptor)
        defer { _ = fileSystem.close(stagingDescriptor) }

        var state = MetricDiagnosticsPublicationState(stagingDescriptor: stagingDescriptor)
        do {
            try performPublication(
                bytes,
                destinationName: destinationName,
                inventory: inventory,
                directories: directories,
                state: &state
            )
        } catch let error as MetricDiagnosticsStoreError {
            cleanupFailedPublication(state, in: directories.metricKitDescriptor)
            guard state.enteredRotation || state.renamed else {
                throw error
            }
            throw MetricDiagnosticsStoreError(
                outcome: .persistenceOutcomeUncertain,
                step: error.step,
                code: error.code
            )
        } catch {
            cleanupFailedPublication(state, in: directories.metricKitDescriptor)
            throw MetricDiagnosticsStoreError(
                outcome: state.enteredRotation || state.renamed
                    ? .persistenceOutcomeUncertain
                    : .notPersisted,
                step: .commit,
                code: EIO
            )
        }
    }

    private func performPublication(
        _ bytes: Data,
        destinationName: String,
        inventory: MetricDiagnosticsInventory,
        directories: MetricDiagnosticsBoundDirectories,
        state: inout MetricDiagnosticsPublicationState
    ) throws {
        let initialStagingNode = try inspectRegularDescriptor(
            state.stagingDescriptor,
            expectedDevice: directories.rootIdentity.device,
            expectedByteCount: 0,
            step: .createStaging
        )
        state.stagingIdentity = initialStagingNode.identity
        try verifyFileBinding(
            named: Self.stagingFileName,
            expected: initialStagingNode,
            in: directories.metricKitDescriptor,
            step: .createStaging
        )
        let stagingNode = try prepareStagingFile(
            bytes,
            descriptor: state.stagingDescriptor,
            parent: directories
        )
        try requireMissingDestination(
            named: destinationName,
            in: directories.metricKitDescriptor
        )
        try rotateIfNeeded(
            inventory,
            in: directories.metricKitDescriptor,
            state: &state
        )
        try renameStaging(
            destinationName: destinationName,
            in: directories.metricKitDescriptor
        )
        state.renamed = true
        try synchronize(directories.metricKitDescriptor, step: .synchronizeDirectory)
        try verifyPublishedFile(
            bytes,
            destinationName: destinationName,
            stagingNode: stagingNode,
            directories: directories
        )
    }

    private func rotateIfNeeded(
        _ inventory: MetricDiagnosticsInventory,
        in descriptor: Int32,
        state: inout MetricDiagnosticsPublicationState
    ) throws {
        guard inventory.payloadNames.count == maxStoredFiles,
              let oldest = inventory.payloadNames.min() else {
            return
        }
        do {
            try removeOwnedRegularFile(named: oldest, in: descriptor, step: .rotate)
            state.enteredRotation = true
        } catch let error as MetricDiagnosticsStoreError {
            state.enteredRotation = error.step == .synchronizeDirectory
            throw error
        }
    }

    private func cleanupFailedPublication(
        _ state: MetricDiagnosticsPublicationState,
        in descriptor: Int32
    ) {
        guard !state.renamed, let stagingIdentity = state.stagingIdentity else { return }
        cleanupStagingAfterFailure(
            expectedIdentity: stagingIdentity,
            in: descriptor
        )
    }

    private func createStagingFile(in parentDescriptor: Int32) throws -> Int32 {
        let flags = O_RDWR | O_CREAT | O_EXCL | O_CLOEXEC
            | O_NOFOLLOW_ANY | O_RESOLVE_BENEATH
        let descriptor = fileSystem.createAt(
            parentDescriptor,
            Self.stagingFileName,
            flags,
            S_IRUSR | S_IWUSR
        )
        guard descriptor >= 0 else {
            throw failure(step: .createStaging)
        }
        return descriptor
    }

    private func prepareStagingFile(
        _ bytes: Data,
        descriptor: Int32,
        parent: MetricDiagnosticsBoundDirectories
    ) throws -> MetricDiagnosticsNode {
        try writeAll(bytes, to: descriptor)
        var node = try inspectRegularDescriptor(
            descriptor,
            expectedDevice: parent.rootIdentity.device,
            expectedByteCount: bytes.count,
            step: .writeStaging
        )
        try verifyFileBinding(
            named: Self.stagingFileName,
            expected: node,
            in: parent.metricKitDescriptor,
            step: .writeStaging
        )
        try synchronizeRegularFile(descriptor, step: .synchronizeStaging)
        do {
            try fileAttributes.apply(descriptor)
            try synchronizeRegularFile(descriptor, step: .synchronizeStaging)
            guard try fileAttributes.verify(descriptor) else {
                throw failure(step: .verifyFileAttributes, code: EIO)
            }
        } catch let error as MetricDiagnosticsStoreError {
            throw error
        } catch {
            throw failure(step: .applyFileAttributes, code: EIO)
        }
        node = try inspectRegularDescriptor(
            descriptor,
            expectedDevice: parent.rootIdentity.device,
            expectedByteCount: bytes.count,
            step: .verifyFileAttributes
        )
        try verifyFileBinding(
            named: Self.stagingFileName,
            expected: node,
            in: parent.metricKitDescriptor,
            step: .verifyFileAttributes
        )
        return node
    }

    private func requireMissingDestination(named name: String, in descriptor: Int32) throws {
        var metadata = stat()
        let result = fileSystem.statAt(descriptor, name, &metadata, AT_SYMLINK_NOFOLLOW)
        guard result != 0, errno == ENOENT else {
            throw failure(step: .revalidateDestination, code: result == 0 ? EEXIST : errno)
        }
    }

    private func renameStaging(destinationName: String, in descriptor: Int32) throws {
        let flags = UInt32(RENAME_EXCL | RENAME_NOFOLLOW_ANY | RENAME_RESOLVE_BENEATH)
        guard fileSystem.renameAt(
            descriptor,
            Self.stagingFileName,
            destinationName,
            flags
        ) == 0 else {
            throw failure(step: .commit)
        }
    }

    private func verifyPublishedFile(
        _ expectedBytes: Data,
        destinationName: String,
        stagingNode: MetricDiagnosticsNode,
        directories: MetricDiagnosticsBoundDirectories
    ) throws {
        let flags = O_RDONLY | O_CLOEXEC | O_NOFOLLOW_ANY | O_RESOLVE_BENEATH | O_UNIQUE
        let descriptor = fileSystem.openAt(directories.metricKitDescriptor, destinationName, flags)
        guard descriptor >= 0 else {
            throw failure(step: .verifyPublishedFile)
        }
        defer { _ = fileSystem.close(descriptor) }

        let finalNode = try inspectRegularDescriptor(
            descriptor,
            expectedDevice: directories.rootIdentity.device,
            expectedByteCount: expectedBytes.count,
            step: .verifyPublishedFile
        )
        guard finalNode.identity == stagingNode.identity,
              try fileAttributes.verify(descriptor) else {
            throw failure(step: .verifyPublishedFile, code: EIO)
        }
        try verifyBytes(expectedBytes, from: descriptor)
        try verifyFileBinding(
            named: destinationName,
            expected: finalNode,
            in: directories.metricKitDescriptor,
            step: .verifyPublishedFile
        )
        try verifyPathBinding(directories)
    }

    private func writeAll(_ bytes: Data, to descriptor: Int32) throws {
        try bytes.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            var offset = 0
            while offset < buffer.count {
                let requested = min(buffer.count - offset, Int(Int32.max))
                let result = fileSystem.write(
                    descriptor,
                    baseAddress.advanced(by: offset),
                    requested
                )
                if result > 0, result <= requested {
                    offset += result
                } else if result == 0 || result > requested {
                    throw failure(step: .writeStaging, code: EIO)
                } else if errno != EINTR {
                    throw failure(step: .writeStaging)
                }
            }
        }
    }

    private func verifyBytes(_ expected: Data, from descriptor: Int32) throws {
        var observed = [UInt8](repeating: 0, count: max(1, min(64 * 1_024, expected.count)))
        var offset = 0
        while offset < expected.count {
            let requested = min(observed.count, expected.count - offset)
            let count = observed.withUnsafeMutableBytes {
                fileSystem.read(descriptor, $0.baseAddress, requested)
            }
            guard count > 0, count <= requested else {
                if count < 0, errno == EINTR { continue }
                throw failure(step: .verifyPublishedBytes, code: count < 0 ? errno : EIO)
            }
            let matches = expected.withUnsafeBytes { expectedBuffer in
                observed.withUnsafeBytes { observedBuffer in
                    memcmp(
                        expectedBuffer.baseAddress?.advanced(by: offset),
                        observedBuffer.baseAddress,
                        count
                    ) == 0
                }
            }
            guard matches else {
                throw failure(step: .verifyPublishedBytes, code: EIO)
            }
            offset += count
        }
        var extraByte: UInt8 = 0
        while true {
            let count = fileSystem.read(descriptor, &extraByte, 1)
            if count == 0 { return }
            if count < 0, errno == EINTR { continue }
            throw failure(step: .verifyPublishedBytes, code: count < 0 ? errno : EIO)
        }
    }

    private func inspectRegularDescriptor(
        _ descriptor: Int32,
        expectedDevice: dev_t,
        expectedByteCount: Int,
        step: MetricDiagnosticsStoreError.Step
    ) throws -> MetricDiagnosticsNode {
        var metadata = stat()
        guard fileSystem.stat(descriptor, &metadata) == 0 else {
            throw failure(step: step)
        }
        let node = MetricDiagnosticsNode(metadata: metadata)
        guard node.isOwnedRegularFile,
              node.identity.device == expectedDevice,
              UInt64(node.byteCount) == UInt64(expectedByteCount) else {
            throw failure(step: step, code: EINVAL)
        }
        return node
    }

    private func verifyFileBinding(
        named name: String,
        expected: MetricDiagnosticsNode,
        in descriptor: Int32,
        step: MetricDiagnosticsStoreError.Step
    ) throws {
        let observed = try inspectOwnedRegularFile(named: name, in: descriptor, step: step)
        guard observed.identity == expected.identity,
              observed.byteCount == expected.byteCount else {
            throw failure(step: step, code: EBUSY)
        }
    }

    private func synchronizeRegularFile(
        _ descriptor: Int32,
        step: MetricDiagnosticsStoreError.Step
    ) throws {
        while fileSystem.fullSynchronize(descriptor) != 0 {
            let code = errno
            if code == EINTR { continue }
            guard code == ENOTSUP || code == EINVAL else {
                throw failure(step: step, code: code)
            }
            try synchronize(descriptor, step: step)
            return
        }
    }
}

nonisolated private struct MetricDiagnosticsPublicationState {
    let stagingDescriptor: Int32
    var stagingIdentity: MetricDiagnosticsIdentity?
    var enteredRotation = false
    var renamed = false
}
