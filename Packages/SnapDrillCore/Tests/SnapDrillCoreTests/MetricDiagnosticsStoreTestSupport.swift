//
//  MetricDiagnosticsStoreTestSupport.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Darwin
import Foundation
import Testing
@testable import SnapDrillCore

extension MetricDiagnosticsStoreTests {
    struct Fixture {
        let container: URL
        let root: URL

        init(createRoot: Bool = false, createContainer: Bool = true) throws {
            container = FileManager.default.temporaryDirectory
                .appendingPathComponent("MetricDiagnostics-\(UUID().uuidString)", isDirectory: true)
            root = container.appendingPathComponent(AppOwnedStorage.directoryName, isDirectory: true)
            if createContainer {
                try FileManager.default.createDirectory(at: container, withIntermediateDirectories: false)
            }
            if createRoot {
                try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            }
        }

        var diagnosticsURL: URL {
            root.appendingPathComponent("Diagnostics", isDirectory: true)
        }

        var metricKitURL: URL {
            diagnosticsURL.appendingPathComponent("MetricKit", isDirectory: true)
        }

        var stagingURL: URL {
            metricKitURL.appendingPathComponent(MetricDiagnosticsStore.stagingFileName)
        }

        func store(
            maxStoredFiles: Int = 30,
            fileSystem: MetricDiagnosticsFileSystem = .live,
            fileAttributes: MetricDiagnosticsDirectoryAttributes = .live,
            makeIdentifier: @escaping @Sendable () -> UUID = UUID.init
        ) -> MetricDiagnosticsStore {
            MetricDiagnosticsStore(
                rootURL: root,
                maxStoredFiles: maxStoredFiles,
                fileSystem: fileSystem,
                fileAttributes: fileAttributes,
                makeIdentifier: makeIdentifier
            )
        }

        func prepareMetricDirectory() throws {
            try FileManager.default.createDirectory(at: metricKitURL, withIntermediateDirectories: true)
        }

        func entryNames() throws -> [String] {
            try FileManager.default.contentsOfDirectory(atPath: metricKitURL.path).sorted()
        }

        func payloadFiles() throws -> [URL] {
            try FileManager.default.contentsOfDirectory(
                at: metricKitURL,
                includingPropertiesForKeys: nil
            ).filter { MetricDiagnosticsStore.isPayloadFileName($0.lastPathComponent) }
        }

        func protectionClass(at url: URL) throws -> UInt32 {
            let descriptor = Darwin.open(url.path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW)
            guard descriptor >= 0 else {
                throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
            }
            defer { Darwin.close(descriptor) }

            var attributes = attrlist()
            attributes.bitmapcount = UInt16(ATTR_BIT_MAP_COUNT)
            attributes.commonattr = UInt32(ATTR_CMN_DATA_PROTECT_FLAGS)
            var result = ProtectionClassResult()
            guard Darwin.fgetattrlist(
                descriptor,
                &attributes,
                &result,
                MemoryLayout.size(ofValue: result),
                0
            ) == 0 else {
                throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
            }
            guard result.length == UInt32(MemoryLayout.size(ofValue: result)) else {
                throw POSIXError(.EIO)
            }
            return result.protectionClass
        }

        func makeSiblingSentinels() throws -> [URL: Data] {
            let urls = [
                root.appendingPathComponent("LocalLibrary/sentinel"),
                root.appendingPathComponent("Drafts/sentinel"),
                root.appendingPathComponent("RecoveryIncidents/sentinel"),
                container.appendingPathComponent("Caches/com.snapdrill.global/sentinel"),
                container.appendingPathComponent("tmp/com.snapdrill.global/sentinel")
            ]
            var sentinels: [URL: Data] = [:]
            for (index, url) in urls.enumerated() {
                let bytes = Data("sentinel-\(index)".utf8)
                try FileManager.default.createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try bytes.write(to: url)
                sentinels[url] = bytes
            }
            return sentinels
        }

        func expectSentinelsUnchanged(_ sentinels: [URL: Data]) throws {
            for (url, expected) in sentinels {
                #expect(try Data(contentsOf: url) == expected)
            }
        }

        func remove() {
            try? FileManager.default.removeItem(at: container)
        }
    }

    private struct ProtectionClassResult {
        var length: UInt32 = 0
        var protectionClass: UInt32 = 0
    }

    enum HostileEntry: String, CaseIterable, CustomTestStringConvertible {
        case symlink
        case hardLink
        case directory
        case fifo
        case unknownRegularFile

        var testDescription: String { rawValue }

        func install(in directory: URL, sentinel: URL) throws {
            let target = directory.appendingPathComponent("hostile")
            switch self {
            case .symlink:
                try FileManager.default.createSymbolicLink(at: target, withDestinationURL: sentinel)
            case .hardLink:
                try FileManager.default.linkItem(at: sentinel, to: target)
            case .directory:
                try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false)
            case .fifo:
                guard Darwin.mkfifo(target.path, S_IRUSR | S_IWUSR) == 0 else {
                    throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
                }
            case .unknownRegularFile:
                try Data("unknown".utf8).write(to: target)
            }
        }
    }

    enum FixedNodeAttack: String, CaseIterable, CustomTestStringConvertible {
        case applicationSupportSymlink
        case rootSymlink
        case diagnosticsFile
        case diagnosticsSymlink
        case metricKitFile
        case metricKitSymlink

        var testDescription: String { rawValue }

        func install(in fixture: Fixture, outside: URL) throws {
            switch self {
            case .applicationSupportSymlink:
                try FileManager.default.removeItem(at: fixture.container)
                try FileManager.default.createSymbolicLink(
                    at: fixture.container,
                    withDestinationURL: outside
                )
            case .rootSymlink:
                try FileManager.default.createSymbolicLink(at: fixture.root, withDestinationURL: outside)
            case .diagnosticsFile:
                try FileManager.default.createDirectory(at: fixture.root, withIntermediateDirectories: false)
                try Data("file".utf8).write(to: fixture.diagnosticsURL)
            case .diagnosticsSymlink:
                try FileManager.default.createDirectory(at: fixture.root, withIntermediateDirectories: false)
                try FileManager.default.createSymbolicLink(
                    at: fixture.diagnosticsURL,
                    withDestinationURL: outside
                )
            case .metricKitFile:
                try FileManager.default.createDirectory(at: fixture.diagnosticsURL, withIntermediateDirectories: true)
                try Data("file".utf8).write(to: fixture.metricKitURL)
            case .metricKitSymlink:
                try FileManager.default.createDirectory(at: fixture.diagnosticsURL, withIntermediateDirectories: true)
                try FileManager.default.createSymbolicLink(
                    at: fixture.metricKitURL,
                    withDestinationURL: outside
                )
            }
        }
    }

    enum HostileStaging: String, CaseIterable, CustomTestStringConvertible {
        case symlink
        case hardLink

        var testDescription: String { rawValue }

        nonisolated func install(at stagingURL: URL, sentinel: URL) throws {
            switch self {
            case .symlink:
                try FileManager.default.createSymbolicLink(at: stagingURL, withDestinationURL: sentinel)
            case .hardLink:
                try FileManager.default.linkItem(at: sentinel, to: stagingURL)
            }
        }
    }

    nonisolated final class IdentifierSequence: @unchecked Sendable {
        private let identifiers: [UUID]
        private let lock = NSLock()
        private var index = 0

        init(count: Int) {
            identifiers = (0..<count).map { index in
                UUID(uuid: (
                    0, 0, 0, 0,
                    0, 0, 0, 0,
                    0, 0, 0, 0,
                    0, 0, 0, UInt8(index + 1)
                ))
            }
        }

        func next() -> UUID {
            lock.withLock {
                precondition(index < identifiers.count)
                defer { index += 1 }
                return identifiers[index]
            }
        }
    }

    nonisolated final class DirectoryRebindTrigger: @unchecked Sendable {
        private let source: URL
        private let destination: URL
        private let replacementMetricKit: URL
        private let lock = NSLock()
        private var hasRun = false
        private var recordedErrorDescription: String?

        init(source: URL, destination: URL, replacementMetricKit: URL) {
            self.source = source
            self.destination = destination
            self.replacementMetricKit = replacementMetricKit
        }

        var didRun: Bool {
            lock.withLock { hasRun }
        }

        var errorDescription: String? {
            lock.withLock { recordedErrorDescription }
        }

        func next() -> UUID {
            lock.withLock {
                guard !hasRun else { return }
                hasRun = true
                do {
                    try FileManager.default.moveItem(at: source, to: destination)
                    try FileManager.default.createDirectory(
                        at: replacementMetricKit,
                        withIntermediateDirectories: true
                    )
                } catch {
                    recordedErrorDescription = String(describing: error)
                }
            }
            return UUID(uuid: (
                0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 1
            ))
        }
    }

    nonisolated final class PayloadReplacementTrigger: @unchecked Sendable {
        private let source: URL
        private let displaced: URL
        private let sentinel: URL
        private let attack: HostileStaging
        private let lock = NSLock()
        private var hasRun = false
        private var recordedErrorDescription: String?

        init(source: URL, displaced: URL, sentinel: URL, attack: HostileStaging) {
            self.source = source
            self.displaced = displaced
            self.sentinel = sentinel
            self.attack = attack
        }

        var didRun: Bool {
            lock.withLock { hasRun }
        }

        var errorDescription: String? {
            lock.withLock { recordedErrorDescription }
        }

        func next() -> UUID {
            lock.withLock {
                guard !hasRun else { return }
                hasRun = true
                do {
                    try FileManager.default.moveItem(at: source, to: displaced)
                    try attack.install(at: source, sentinel: sentinel)
                } catch {
                    recordedErrorDescription = String(describing: error)
                }
            }
            return UUID(uuid: (
                0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 2
            ))
        }
    }

    nonisolated final class InvocationGate: @unchecked Sendable {
        private let target: Int
        private let lock = NSLock()
        private var count = 0

        init(target: Int) {
            self.target = target
        }

        func isTargetInvocation() -> Bool {
            lock.withLock {
                count += 1
                return count == target
            }
        }
    }
}
