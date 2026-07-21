//
//  CaptureDraftFileStore.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import CryptoKit
import Darwin
import Foundation

nonisolated enum CaptureDraftStorageSnapshot: Sendable {
    case missing
    case bytes(Data, revision: String)
    case unreadable(observation: String?)

    var observation: String? {
        switch self {
        case .missing:
            nil
        case .bytes(_, let revision):
            revision
        case .unreadable(let observation):
            observation
        }
    }
}

/// Serializes publication, compare-and-swap, settlement, and compare-and-delete for one draft.
actor CaptureDraftFileStore {
    typealias Publish = @Sendable (
        _ bytes: Data,
        _ staging: DurableRegularFilePublisher.RelativeFile,
        _ destination: DurableRegularFilePublisher.RelativeFile,
        _ trustRootURL: URL
    ) throws -> Void

    static let directoryName = "Drafts"
    static let fileName = "current.v1"
    static let maximumByteCount = 64 * 1024 * 1024

    private let trustRootURL: URL?
    private let fileManager: FileManager
    private let publish: Publish
    private var settlingRevision: String?
    private var didAttemptStagingSweep = false

    init(
        trustRootURL: URL?,
        publish: @escaping Publish = { bytes, staging, destination, root in
            try DurableRegularFilePublisher().publish(
                bytes,
                staging: staging,
                destination: destination,
                beneath: root,
                isExcludedFromBackup: true
            )
        }
    ) {
        self.trustRootURL = trustRootURL
        fileManager = FileManager()
        self.publish = publish
    }

    func load() -> CaptureDraftStorageSnapshot {
        if !didAttemptStagingSweep, let trustRootURL {
            do {
                try CaptureDraftFilesystemMaintenance.sweepStagingFiles(beneath: trustRootURL)
            } catch {
                SnapDrillLogger.capture.warning(
                    "[DraftStore] Staging cleanup unavailable: \(error.localizedDescription)"
                )
            }
            didAttemptStagingSweep = true
        }
        return readSnapshot()
    }

    func replace(_ bytes: Data, expectedRevision: String?) throws -> String {
        try replace(bytes, expectedRevision: expectedRevision, beginsSettlement: false)
    }

    func replaceAndBeginSettlement(
        _ bytes: Data,
        expectedRevision: String?
    ) throws -> String {
        try replace(bytes, expectedRevision: expectedRevision, beginsSettlement: true)
    }

    private func replace(
        _ bytes: Data,
        expectedRevision: String?,
        beginsSettlement: Bool
    ) throws -> String {
        guard bytes.count <= Self.maximumByteCount else {
            throw CaptureDraftError.envelopeTooLarge
        }
        guard settlingRevision == nil else {
            throw CaptureDraftError.settlementInProgress
        }

        let current = readSnapshot()
        if let expectedRevision {
            guard case .bytes(_, let observedRevision) = current,
                  observedRevision == expectedRevision else {
                throw CaptureDraftError.draftChanged
            }
        } else if case .missing = current {
            // Creating the first generation is allowed only from a clean absence.
        } else {
            throw CaptureDraftError.draftAlreadyExists
        }

        let root = try prepareDirectories()
        let stagingName = "current.\(UUID().uuidString.lowercased()).next"
        let staging = try DurableRegularFilePublisher.RelativeFile(
            parentComponents: [Self.directoryName],
            fileName: stagingName
        )
        let destination = try DurableRegularFilePublisher.RelativeFile(
            parentComponents: [Self.directoryName],
            fileName: Self.fileName
        )

        do {
            try publish(bytes, staging, destination, root)
        } catch let error as DurableRegularFilePublicationError
            where error.outcome == .publicationOutcomeUncertain {
            removeStagingFileAfterFailure(stagingName, beneath: root)
            guard case .bytes(let observed, _) = readSnapshot(), observed == bytes else {
                throw CaptureDraftError.storageFailure
            }
        } catch {
            removeStagingFileAfterFailure(stagingName, beneath: root)
            throw CaptureDraftError.storageFailure
        }

        guard case .bytes(let observed, let revision) = readSnapshot(),
              observed == bytes else {
            throw CaptureDraftError.storageFailure
        }
        if beginsSettlement {
            settlingRevision = revision
        }
        return revision
    }

    func beginSettlement(expectedRevision: String) throws {
        guard settlingRevision == nil else {
            throw CaptureDraftError.settlementInProgress
        }
        guard case .bytes(_, let observedRevision) = readSnapshot() else {
            throw CaptureDraftError.draftMissing
        }
        guard observedRevision == expectedRevision else {
            throw CaptureDraftError.draftChanged
        }
        settlingRevision = expectedRevision
    }

    func completeSettlement(expectedRevision: String) throws {
        guard settlingRevision == expectedRevision else {
            throw CaptureDraftError.draftChanged
        }
        try discard(expectedObservation: expectedRevision, allowsSettlement: true)
        settlingRevision = nil
    }

    func abortSettlement(expectedRevision: String) {
        if settlingRevision == expectedRevision {
            settlingRevision = nil
        }
    }

    func discard(expectedObservation: String) throws {
        try discard(expectedObservation: expectedObservation, allowsSettlement: false)
    }

    private func discard(
        expectedObservation: String,
        allowsSettlement: Bool
    ) throws {
        if !allowsSettlement, settlingRevision != nil {
            throw CaptureDraftError.settlementInProgress
        }
        let snapshot = readSnapshot()
        guard snapshot.observation != nil else {
            throw CaptureDraftError.draftMissing
        }
        guard snapshot.observation == expectedObservation else {
            throw CaptureDraftError.draftChanged
        }
        guard let root = trustRootURL else {
            throw CaptureDraftError.storageFailure
        }
        do {
            try CaptureDraftFilesystemMaintenance.removeObservedNode(
                expectedObservation: expectedObservation,
                root: root
            )
        } catch let error as CaptureDraftError {
            throw error
        } catch {
            throw CaptureDraftError.storageFailure
        }
        guard case .missing = readSnapshot() else {
            throw CaptureDraftError.storageFailure
        }
    }

    private func prepareDirectories() throws -> URL {
        guard let root = trustRootURL else {
            throw CaptureDraftError.storageFailure
        }
        let drafts = root.appendingPathComponent(Self.directoryName, isDirectory: true)
        do {
            try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: drafts, withIntermediateDirectories: false)
        } catch let error as NSError where error.code == NSFileWriteFileExistsError {
            // The secure publisher verifies that existing path components are real directories.
        } catch {
            throw CaptureDraftError.storageFailure
        }

        do {
            var draftsForBackup = drafts
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try draftsForBackup.setResourceValues(values)
        } catch {
            throw CaptureDraftError.storageFailure
        }
        try CaptureDraftFilesystemMaintenance.sweepStagingFiles(beneath: root)
        didAttemptStagingSweep = true
        return root
    }

    private func readSnapshot() -> CaptureDraftStorageSnapshot {
        guard let root = trustRootURL else {
            return .unreadable(observation: nil)
        }

        let rootFlags = O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
        let (rootDescriptor, rootError) = root.path.withCString { path in
            let descriptor = Darwin.open(path, rootFlags)
            return (descriptor, descriptor < 0 ? errno : 0)
        }
        if rootDescriptor < 0 {
            if rootError == ENOENT { return .missing }
            return .unreadable(
                observation: CaptureDraftFilesystemMaintenance.observedNode(
                    at: root,
                    target: "root"
                )
            )
        }
        defer { _ = Darwin.close(rootDescriptor) }

        let directoryFlags = O_RDONLY | O_DIRECTORY | O_CLOEXEC
            | O_NOFOLLOW_ANY | O_RESOLVE_BENEATH
        let (draftsDescriptor, draftsError) = Self.directoryName.withCString { name in
            let descriptor = Darwin.openat(rootDescriptor, name, directoryFlags)
            return (descriptor, descriptor < 0 ? errno : 0)
        }
        if draftsDescriptor < 0 {
            if draftsError == ENOENT { return .missing }
            return .unreadable(
                observation: CaptureDraftFilesystemMaintenance.observedNode(
                    named: Self.directoryName,
                    in: rootDescriptor,
                    target: "drafts"
                )
            )
        }
        defer { _ = Darwin.close(draftsDescriptor) }

        return readSnapshot(in: draftsDescriptor)
    }

    private func readSnapshot(in draftsDescriptor: Int32) -> CaptureDraftStorageSnapshot {
        var pathMetadata = stat()
        let (statResult, statError) = Self.fileName.withCString { name in
            let result = Darwin.fstatat(
                draftsDescriptor,
                name,
                &pathMetadata,
                AT_SYMLINK_NOFOLLOW
            )
            return (result, result != 0 ? errno : 0)
        }
        if statResult != 0 {
            return statError == ENOENT ? .missing : .unreadable(observation: nil)
        }
        let pathObservation = "current:\(CaptureDraftFilesystemMaintenance.nodeObservation(pathMetadata))"
        guard isSupportedRegularFile(pathMetadata) else {
            return .unreadable(observation: pathObservation)
        }

        return readRegularFile(
            in: draftsDescriptor,
            pathMetadata: pathMetadata,
            pathObservation: pathObservation
        )
    }

    private func readRegularFile(
        in draftsDescriptor: Int32,
        pathMetadata: stat,
        pathObservation: String
    ) -> CaptureDraftStorageSnapshot {
        let fileFlags = O_RDONLY | O_CLOEXEC | O_NOFOLLOW_ANY | O_RESOLVE_BENEATH | O_UNIQUE
        let descriptor = Self.fileName.withCString {
            Darwin.openat(draftsDescriptor, $0, fileFlags)
        }
        guard descriptor >= 0 else {
            return .unreadable(observation: pathObservation)
        }
        defer { _ = Darwin.close(descriptor) }

        var openedMetadata = stat()
        guard Darwin.fstat(descriptor, &openedMetadata) == 0,
              sameNode(pathMetadata, openedMetadata),
              isSupportedRegularFile(openedMetadata) else {
            return .unreadable(observation: pathObservation)
        }

        guard let data = readBytes(
            from: descriptor,
            byteCount: Int(openedMetadata.st_size)
        ) else {
            return .unreadable(observation: pathObservation)
        }

        var finalMetadata = stat()
        guard Darwin.fstat(descriptor, &finalMetadata) == 0,
              sameNode(openedMetadata, finalMetadata),
              finalMetadata.st_size == openedMetadata.st_size else {
            return .unreadable(observation: pathObservation)
        }
        return .bytes(data, revision: dataObservation(data))
    }

    private func readBytes(from descriptor: Int32, byteCount: Int) -> Data? {
        var data = Data(count: byteCount)
        let readSucceeded = data.withUnsafeMutableBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return byteCount == 0 }
            var offset = 0
            while offset < byteCount {
                let result = Darwin.read(
                    descriptor,
                    baseAddress.advanced(by: offset),
                    byteCount - offset
                )
                if result > 0 {
                    offset += result
                } else if result == 0 {
                    return false
                } else if errno != EINTR {
                    return false
                }
            }
            var trailingByte: UInt8 = 0
            return Darwin.read(descriptor, &trailingByte, 1) == 0
        }
        return readSucceeded ? data : nil
    }

    private func removeStagingFileAfterFailure(_ name: String, beneath root: URL) {
        do {
            try CaptureDraftFilesystemMaintenance.removeStagingFile(named: name, beneath: root)
        } catch {
            SnapDrillLogger.capture.warning(
                "[DraftStore] Failed to remove staging file: \(error.localizedDescription)"
            )
        }
    }

    private func isSupportedRegularFile(_ metadata: stat) -> Bool {
        metadata.st_mode & S_IFMT == S_IFREG
            && metadata.st_nlink == 1
            && metadata.st_size >= 0
            && metadata.st_size <= Self.maximumByteCount
    }

    private func sameNode(_ lhs: stat, _ rhs: stat) -> Bool {
        lhs.st_dev == rhs.st_dev && lhs.st_ino == rhs.st_ino
    }

    private func dataObservation(_ data: Data) -> String {
        "data:" + sha256(data)
    }

    private func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
