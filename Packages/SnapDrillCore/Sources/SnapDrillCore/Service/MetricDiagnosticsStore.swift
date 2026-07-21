//
//  MetricDiagnosticsStore.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Darwin
import Foundation

/// Owns the bounded, app-private MetricKit payload directory.
final class MetricDiagnosticsStore: @unchecked Sendable {
    nonisolated static let diagnosticsDirectoryName = "Diagnostics"
    nonisolated static let metricKitDirectoryName = "MetricKit"
    nonisolated static let stagingFileName = ".payload.pending"

    private nonisolated let rootURL: URL?
    nonisolated let maxStoredFiles: Int
    nonisolated let fileSystem: MetricDiagnosticsFileSystem
    nonisolated let fileAttributes: MetricDiagnosticsDirectoryAttributes
    private nonisolated let makeIdentifier: @Sendable () -> UUID
    private nonisolated let lock = NSLock()

    init(
        rootURL: URL?,
        maxStoredFiles: Int = 30,
        fileSystem: MetricDiagnosticsFileSystem = .live,
        fileAttributes: MetricDiagnosticsDirectoryAttributes = .live,
        makeIdentifier: @escaping @Sendable () -> UUID = UUID.init
    ) {
        precondition(maxStoredFiles > 0)
        self.rootURL = rootURL
        self.maxStoredFiles = maxStoredFiles
        self.fileSystem = fileSystem
        self.fileAttributes = fileAttributes
        self.makeIdentifier = makeIdentifier
    }

    static func production(fileManager: FileManager = .default) -> MetricDiagnosticsStore {
        do {
            return try MetricDiagnosticsStore(
                rootURL: AppOwnedStorage(fileManager: fileManager).rootURL
            )
        } catch {
            return MetricDiagnosticsStore(rootURL: nil)
        }
    }

    nonisolated func persist(
        _ bytes: Data,
        kind: MetricPayloadSnapshot.Kind,
        receivedAt: Date
    ) throws {
        try lock.withLock {
            try persistLocked(bytes, kind: kind, receivedAt: receivedAt)
        }
    }

    private nonisolated func persistLocked(
        _ bytes: Data,
        kind: MetricPayloadSnapshot.Kind,
        receivedAt: Date
    ) throws {
        guard let rootURL else {
            throw failure(step: .resolveRoot, code: ENOENT)
        }
        let directories = try openBoundDirectories(beneath: rootURL, createIfMissing: true)
        defer { directories.close(using: fileSystem) }

        let inventory = try prepareForPublication(in: directories)

        let destinationName = try uniqueDestinationName(
            kind: kind,
            receivedAt: receivedAt,
            in: directories.metricKitDescriptor
        )
        try publish(
            bytes,
            destinationName: destinationName,
            inventory: inventory,
            directories: directories
        )
    }

    private nonisolated func prepareForPublication(
        in directories: MetricDiagnosticsBoundDirectories
    ) throws -> MetricDiagnosticsInventory {
        try applyAndVerifyDirectoryAttributes(directories)
        let inventory = try inspectInventory(in: directories.metricKitDescriptor)
        guard inventory.payloadNames.count <= maxStoredFiles else {
            throw failure(step: .validateBound, code: EOVERFLOW)
        }
        if inventory.hasStagingFile {
            try removeOwnedRegularFile(
                named: Self.stagingFileName,
                in: directories.metricKitDescriptor,
                step: .removeStaging
            )
        }
        return inventory
    }

    private nonisolated func inspectInventory(in descriptor: Int32) throws -> MetricDiagnosticsInventory {
        let names: [String]
        do {
            names = try fileSystem.listNames(descriptor)
        } catch let error as MetricDiagnosticsPOSIXError {
            throw failure(step: .enumerate, code: error.code)
        } catch {
            throw failure(step: .enumerate, code: EIO)
        }

        var payloadNames: [String] = []
        var hasStagingFile = false
        for name in names {
            if name == Self.stagingFileName {
                _ = try inspectOwnedRegularFile(named: name, in: descriptor, step: .inspectEntry)
                hasStagingFile = true
            } else if Self.isPayloadFileName(name) {
                _ = try inspectOwnedRegularFile(named: name, in: descriptor, step: .inspectEntry)
                payloadNames.append(name)
            } else {
                throw failure(step: .classifyEntry, code: EINVAL)
            }
        }
        return MetricDiagnosticsInventory(
            payloadNames: payloadNames.sorted(),
            hasStagingFile: hasStagingFile
        )
    }

    private nonisolated func uniqueDestinationName(
        kind: MetricPayloadSnapshot.Kind,
        receivedAt: Date,
        in descriptor: Int32
    ) throws -> String {
        for _ in 0..<4 {
            let name = try Self.payloadFileName(
                kind: kind,
                receivedAt: receivedAt,
                identifier: makeIdentifier()
            )
            var metadata = stat()
            let result = fileSystem.statAt(descriptor, name, &metadata, AT_SYMLINK_NOFOLLOW)
            if result != 0, errno == ENOENT {
                return name
            }
            if result != 0 {
                throw failure(step: .inspectDestination, code: errno)
            }
        }
        throw failure(step: .inspectDestination, code: EEXIST)
    }

    nonisolated func cleanupStagingAfterFailure(
        expectedIdentity: MetricDiagnosticsIdentity,
        in descriptor: Int32
    ) {
        var metadata = stat()
        let result = fileSystem.statAt(
            descriptor,
            Self.stagingFileName,
            &metadata,
            AT_SYMLINK_NOFOLLOW
        )
        guard result == 0 else { return }
        let node = MetricDiagnosticsNode(metadata: metadata)
        guard node.isOwnedRegularFile,
              node.identity == expectedIdentity else {
            return
        }
        guard fileSystem.unlinkAt(descriptor, Self.stagingFileName) == 0 else {
            SnapDrillLogger.generic.warning("MetricKit staging cleanup failed")
            return
        }
        do {
            try synchronize(descriptor, step: .removeStaging)
        } catch {
            SnapDrillLogger.generic.warning("MetricKit staging directory sync failed")
        }
    }

    static nonisolated func isPayloadFileName(_ name: String) -> Bool {
        let parts = name.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              Self.containsExactly(parts[0], count: 20, ranges: [48...57]),
              MetricPayloadSnapshot.Kind(rawValue: String(parts[1])) != nil,
              parts[2].hasSuffix(".json") else {
            return false
        }
        let identifier = parts[2].dropLast(".json".count)
        return Self.containsExactly(
            identifier,
            count: 32,
            ranges: [48...57, 97...102]
        )
    }

    private static nonisolated func payloadFileName(
        kind: MetricPayloadSnapshot.Kind,
        receivedAt: Date,
        identifier: UUID
    ) throws -> String {
        let seconds = receivedAt.timeIntervalSince1970
        let roundedMilliseconds = (seconds * 1_000).rounded(.down)
        guard seconds.isFinite,
              seconds >= 0,
              roundedMilliseconds < Double(UInt64.max) else {
            throw MetricDiagnosticsStoreError(
                outcome: .notPersisted,
                step: .createName,
                code: EINVAL
            )
        }
        let milliseconds = UInt64(roundedMilliseconds)
        let stamp = String(format: "%020llu", milliseconds)
        let suffix = identifier.uuidString
            .replacingOccurrences(of: "-", with: "")
            .lowercased()
        return "\(stamp)-\(kind.rawValue)-\(suffix).json"
    }

    private static nonisolated func containsExactly(
        _ text: some StringProtocol,
        count: Int,
        ranges: [ClosedRange<UInt32>]
    ) -> Bool {
        let scalars = text.unicodeScalars
        return scalars.count == count && scalars.allSatisfy { scalar in
            ranges.contains { $0.contains(scalar.value) }
        }
    }

}

nonisolated struct MetricDiagnosticsInventory {
    var payloadNames: [String]
    var hasStagingFile: Bool
}

nonisolated struct MetricDiagnosticsStoreError: Error, Equatable, Sendable {
    enum Outcome: Equatable, Sendable {
        case notPersisted
        case persistenceOutcomeUncertain
    }

    enum Step: String, Equatable, Sendable {
        case resolveRoot
        case createDirectory
        case openDirectory
        case inspectDirectory
        case applyDirectoryAttributes
        case verifyDirectoryAttributes
        case verifyBinding
        case enumerate
        case classifyEntry
        case inspectEntry
        case removeStaging
        case validateBound
        case createStaging
        case writeStaging
        case synchronizeStaging
        case applyFileAttributes
        case verifyFileAttributes
        case revalidateDestination
        case rotate
        case commit
        case synchronizeDirectory
        case createName
        case inspectDestination
        case verifyPublishedFile
        case verifyPublishedBytes
    }

    let outcome: Outcome
    let step: Step
    let code: Int32
}

nonisolated extension MetricDiagnosticsStore {
    func failure(
        step: MetricDiagnosticsStoreError.Step,
        code: Int32 = errno
    ) -> MetricDiagnosticsStoreError {
        MetricDiagnosticsStoreError(outcome: .notPersisted, step: step, code: code)
    }

}
