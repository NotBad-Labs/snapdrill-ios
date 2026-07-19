//
//  DurableRegularFilePublisherTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Darwin
import Foundation
import Testing
@testable import SnapDrillCore
@Suite("Durable regular-file publication", .serialized)
struct DurableRegularFilePublisherTests {
    @Test("Live publication atomically replaces bytes and verifies required attributes")
    func livePublicationReplacesBytesAndAttributes() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        try publish(fixture, using: DurableRegularFilePublisher())
        #expect(try Data(contentsOf: fixture.destinationURL) == fixture.newBytes)
        #expect(!FileManager.default.fileExists(atPath: fixture.stagingURL.path))
        let attributes = try FileManager.default.attributesOfItem(atPath: fixture.destinationURL.path)
        let protection = attributes[.protectionKey] as? FileProtectionType
        #if targetEnvironment(simulator)
        #expect(protection == nil || protection == .completeUntilFirstUserAuthentication)
        #else
        #expect(protection == .completeUntilFirstUserAuthentication)
        #endif
        let values = try fixture.destinationURL.resourceValues(forKeys: [.isExcludedFromBackupKey])
        #expect(values.isExcludedFromBackup == false)
    }

    @Test("Backup exclusion is applied before publication and retained afterward")
    func excludedFromBackupIsRetained() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        try publish(fixture, using: DurableRegularFilePublisher(), isExcludedFromBackup: true)
        let values = try fixture.destinationURL.resourceValues(forKeys: [.isExcludedFromBackupKey])
        #expect(values.isExcludedFromBackup == true)
    }

    @Test("Short writes and EINTR are retried without exposing partial bytes")
    func shortWriteAndEINTRAreRetried() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        var calls = DurableRegularFileSystemCalls.live
        let liveWrite = calls.write
        var writeCalls = 0
        calls.write = { descriptor, buffer, count in
            writeCalls += 1
            if writeCalls == 1 {
                errno = EINTR
                return -1
            }
            return liveWrite(descriptor, buffer, min(2, count))
        }
        try publish(fixture, using: testPublisher(calls: calls))
        #expect(writeCalls > 2)
        #expect(try Data(contentsOf: fixture.destinationURL) == fixture.newBytes)
    }

    @Test("Zero write and ENOSPC preserve the old destination")
    func writeFailuresPreserveOldDestination() throws {
        for failure in [WriteFailure.zero, .noSpace] {
            let fixture = try Fixture()
            defer { fixture.remove() }
            var calls = DurableRegularFileSystemCalls.live
            calls.write = { _, _, _ in
                if failure == .noSpace {
                    errno = ENOSPC
                    return -1
                }
                return 0
            }
            let error = try publicationError {
                try publish(fixture, using: testPublisher(calls: calls))
            }
            #expect(error.outcome == .notPublished)
            #expect(error.step == .writeStagingBytes)
            #expect(try Data(contentsOf: fixture.destinationURL) == fixture.oldBytes)
            #expect(FileManager.default.fileExists(atPath: fixture.stagingURL.path))
        }
    }

    @Test("Byte sync, attribute application, verification and rename failures preserve old bytes")
    func preRenameFailuresPreserveOldDestination() throws {
        try assertPreRenameFailure(.synchronizeStagingBytes) { calls, _ in
            calls.fullSync = { _ in
                errno = EIO
                return -1
            }
        }
        try assertPreRenameFailure(.applyProtection) { _, attributes in
            attributes.setProtection = { _ in throw CocoaError(.fileWriteUnknown) }
        }
        try assertPreRenameFailure(.applyBackupPolicy) { _, attributes in
            attributes.setBackupExclusion = { _, _ in throw CocoaError(.fileWriteUnknown) }
        }
        try assertPreRenameFailure(.verifyStagingAttributes) { _, attributes in
            attributes.verify = { _, _ in false }
        }
        try assertPreRenameFailure(.rename) { calls, _ in
            calls.renameAt = { _, _, _, _, _ in
                errno = EIO
                return -1
            }
        }
    }

    @Test("Second staged sync failure preserves old bytes")
    func stagedAttributeSyncFailurePreservesOldDestination() throws {
        try assertPreRenameFailure(.synchronizeStagingAttributes) { calls, _ in
            var syncCount = 0
            calls.fullSync = { _ in
                syncCount += 1
                if syncCount == 2 {
                    errno = EIO
                    return -1
                }
                return 0
            }
        }
    }

    @Test("Full sync and fallback sync retry EINTR without changing publication semantics")
    func syncRetriesEINTRAndUsesFallback() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        var calls = DurableRegularFileSystemCalls.live
        let liveSync = calls.sync
        var fullSyncCount = 0
        var syncCount = 0
        calls.fullSync = { _ in
            fullSyncCount += 1
            if fullSyncCount == 1 {
                errno = EINTR
                return -1
            }
            if fullSyncCount == 2 {
                errno = ENOTSUP
                return -1
            }
            return 0
        }
        calls.sync = { descriptor in
            syncCount += 1
            if syncCount == 1 {
                errno = EINTR
                return -1
            }
            return liveSync(descriptor)
        }
        try publish(fixture, using: testPublisher(calls: calls))
        #expect(fullSyncCount >= 3)
        #expect(syncCount >= 4)
        #expect(try Data(contentsOf: fixture.destinationURL) == fixture.newBytes)
    }

    @Test("Post-rename parent and verification failures report uncertain with exact new bytes")
    func postRenameFailuresReportUncertain() throws {
        try assertPostRenameFailure(.synchronizeStagingParent) { calls, _ in
            calls.fullSync = { _ in 0 }
            calls.sync = { _ in
                errno = EIO
                return -1
            }
        }
        try assertPostRenameFailure(.synchronizeDestinationParent) { calls, _ in
            calls.fullSync = { _ in 0 }
            let liveSync = calls.sync
            var syncCount = 0
            calls.sync = { descriptor in
                syncCount += 1
                if syncCount == 2 {
                    errno = EIO
                    return -1
                }
                return liveSync(descriptor)
            }
        }
        try assertPostRenameFailure(.verifyFinalBytes) { calls, _ in
            calls.read = { _, _, _ in
                errno = EIO
                return -1
            }
        }
        try assertPostRenameFailure(.openFinalFile) { calls, _ in
            let liveOpenAt = calls.openAt
            calls.openAt = { parent, path, flags in
                if String(cString: path) == "selector", flags & O_DIRECTORY == 0 {
                    errno = EIO
                    return -1
                }
                return liveOpenAt(parent, path, flags)
            }
        }
        try assertPostRenameFailure(.verifyFinalAttributes) { _, attributes in
            var verificationCount = 0
            attributes.verify = { _, _ in
                verificationCount += 1
                return verificationCount == 1
            }
        }
    }

    @Test("Symlinked roots, parents, destinations and staging names fail closed")
    func symlinksFailClosed() throws {
        try assertSymlinkedRootRejected()
        try assertSymlinkedParentRejected()
        try assertUnsafeDestinationRejected(asDirectory: false)
        try assertUnsafeDestinationRejected(asDirectory: true)
        let fixture = try Fixture()
        defer { fixture.remove() }
        let sibling = fixture.root.appendingPathComponent("sibling")
        try Data("sibling".utf8).write(to: sibling)
        try FileManager.default.createSymbolicLink(
            at: fixture.stagingURL,
            withDestinationURL: sibling
        )
        let error = try publicationError {
            try publish(fixture, using: testPublisher())
        }
        #expect(error.outcome == .notPublished)
        #expect(error.step == .createStagingFile)
        #expect(try Data(contentsOf: fixture.destinationURL) == fixture.oldBytes)
    }

    @Test("Hard-linked destination and staged inode are rejected")
    func hardLinksFailClosed() throws {
        let destinationFixture = try Fixture()
        defer { destinationFixture.remove() }
        let destinationLink = destinationFixture.root.appendingPathComponent("destination-link")
        try FileManager.default.linkItem(
            at: destinationFixture.destinationURL,
            to: destinationLink
        )
        let destinationError = try publicationError {
            try publish(destinationFixture, using: testPublisher())
        }
        #expect(destinationError.step == .inspectDestination)
        #expect(try Data(contentsOf: destinationFixture.destinationURL) == destinationFixture.oldBytes)
        let stagingFixture = try Fixture()
        defer { stagingFixture.remove() }
        var attributes = passingAttributes
        attributes.setProtection = { url in
            try FileManager.default.linkItem(
                at: url,
                to: stagingFixture.root.appendingPathComponent("staging-link")
            )
        }
        let stagingError = try publicationError {
            try publish(stagingFixture, using: testPublisher(attributes: attributes))
        }
        #expect(stagingError.outcome == .notPublished)
        #expect(stagingError.step == .applyProtection)
        #expect(try Data(contentsOf: stagingFixture.destinationURL) == stagingFixture.oldBytes)
    }

    @Test("Input paths reject traversal, separators and control characters")
    func relativeLocationsRejectUnsafeComponents() throws {
        let invalidComponents = ["", ".", "..", "a/b", #"a\b"#, "line\nbreak", "\0"]
        for component in invalidComponents {
            #expect(throws: DurableRegularFileLocationError.invalidComponent) {
                _ = try DurableRegularFilePublisher.RelativeFile(
                    parentComponents: [component],
                    fileName: "file"
                )
            }
            #expect(throws: DurableRegularFileLocationError.invalidComponent) {
                _ = try DurableRegularFilePublisher.RelativeFile(fileName: component)
            }
        }
        let location = try DurableRegularFilePublisher.RelativeFile(
            parentComponents: ["nested", "owned"],
            fileName: "file"
        )
        #expect(location.parentComponents == ["nested", "owned"])
    }
}

private extension DurableRegularFilePublisherTests {
    func publish(
        _ fixture: Fixture,
        using publisher: DurableRegularFilePublisher,
        isExcludedFromBackup: Bool = false
    ) throws {
        try publisher.publish(
            fixture.newBytes,
            staging: fixture.staging,
            destination: fixture.destination,
            beneath: fixture.root,
            isExcludedFromBackup: isExcludedFromBackup
        )
    }

    func assertPreRenameFailure(
        _ expectedStep: DurableRegularFilePublicationError.Step,
        configure: (inout DurableRegularFileSystemCalls, inout DurableRegularFileAttributes) -> Void
    ) throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        var calls = DurableRegularFileSystemCalls.live
        var attributes = passingAttributes
        configure(&calls, &attributes)

        let error = try publicationError {
            try publish(
                fixture,
                using: testPublisher(calls: calls, attributes: attributes)
            )
        }

        #expect(error.outcome == .notPublished)
        #expect(error.step == expectedStep)
        #expect(try Data(contentsOf: fixture.destinationURL) == fixture.oldBytes)
        #expect(FileManager.default.fileExists(atPath: fixture.stagingURL.path))
    }

    func assertPostRenameFailure(
        _ expectedStep: DurableRegularFilePublicationError.Step,
        configure: (inout DurableRegularFileSystemCalls, inout DurableRegularFileAttributes) -> Void
    ) throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        var calls = DurableRegularFileSystemCalls.live
        var attributes = passingAttributes
        configure(&calls, &attributes)

        let error = try publicationError {
            try publish(
                fixture,
                using: testPublisher(calls: calls, attributes: attributes)
            )
        }

        #expect(error.outcome == .publicationOutcomeUncertain)
        #expect(error.step == expectedStep)
        #expect(try Data(contentsOf: fixture.destinationURL) == fixture.newBytes)
        #expect(!FileManager.default.fileExists(atPath: fixture.stagingURL.path))
    }

    func assertSymlinkedRootRejected() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let linkedRoot = fixture.root.deletingLastPathComponent()
            .appendingPathComponent("linked-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: linkedRoot) }
        try FileManager.default.createSymbolicLink(at: linkedRoot, withDestinationURL: fixture.root)

        let error = try publicationError {
            try testPublisher().publish(
                fixture.newBytes,
                staging: fixture.staging,
                destination: fixture.destination,
                beneath: linkedRoot,
                isExcludedFromBackup: false
            )
        }
        #expect(error.outcome == .notPublished)
        #expect(error.step == .openStagingParent)
        #expect(try Data(contentsOf: fixture.destinationURL) == fixture.oldBytes)
    }

    func assertSymlinkedParentRejected() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let realParent = fixture.root.appendingPathComponent("real-stage", isDirectory: true)
        try FileManager.default.createDirectory(at: realParent, withIntermediateDirectories: false)
        try FileManager.default.removeItem(at: fixture.stagingURL.deletingLastPathComponent())
        try FileManager.default.createSymbolicLink(
            at: fixture.stagingURL.deletingLastPathComponent(),
            withDestinationURL: realParent
        )

        let error = try publicationError {
            try publish(fixture, using: testPublisher())
        }
        #expect(error.outcome == .notPublished)
        #expect(error.step == .openStagingParent)
        #expect(try Data(contentsOf: fixture.destinationURL) == fixture.oldBytes)
    }

    func assertUnsafeDestinationRejected(asDirectory: Bool) throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        try FileManager.default.removeItem(at: fixture.destinationURL)
        if asDirectory {
            try FileManager.default.createDirectory(
                at: fixture.destinationURL,
                withIntermediateDirectories: false
            )
        } else {
            let target = fixture.root.appendingPathComponent("target")
            try Data("target".utf8).write(to: target)
            try FileManager.default.createSymbolicLink(
                at: fixture.destinationURL,
                withDestinationURL: target
            )
        }

        let error = try publicationError {
            try publish(fixture, using: testPublisher())
        }
        #expect(error.outcome == .notPublished)
        #expect(error.step == .inspectDestination)
    }

    func publicationError(
        _ operation: () throws -> Void
    ) throws -> DurableRegularFilePublicationError {
        do {
            try operation()
            Issue.record("Expected publication to fail")
            throw TestFailure.missingPublicationError
        } catch let error as DurableRegularFilePublicationError {
            return error
        }
    }

    func testPublisher(
        calls: DurableRegularFileSystemCalls = .live,
        attributes: DurableRegularFileAttributes? = nil
    ) -> DurableRegularFilePublisher {
        DurableRegularFilePublisher(
            systemCalls: calls,
            fileAttributes: attributes ?? passingAttributes
        )
    }

    var passingAttributes: DurableRegularFileAttributes {
        DurableRegularFileAttributes(
            setProtection: { _ in },
            setBackupExclusion: { _, _ in },
            verify: { _, _ in true }
        )
    }
}

private nonisolated enum WriteFailure {
    case zero
    case noSpace
}

private nonisolated enum TestFailure: Error {
    case missingPublicationError
}

private nonisolated struct Fixture {
    let root: URL
    let staging: DurableRegularFilePublisher.RelativeFile
    let destination: DurableRegularFilePublisher.RelativeFile
    let oldBytes = Data("old-selector\n".utf8)
    let newBytes = Data("new-selector\n".utf8)

    init() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("DurablePublisher-\(UUID().uuidString)", isDirectory: true)
        staging = try DurableRegularFilePublisher.RelativeFile(
            parentComponents: ["staging"],
            fileName: "selector.next"
        )
        destination = try DurableRegularFilePublisher.RelativeFile(
            parentComponents: ["published"],
            fileName: "selector"
        )
        try FileManager.default.createDirectory(
            at: stagingURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: destinationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try oldBytes.write(to: destinationURL)
    }

    var stagingURL: URL {
        root.appendingPathComponent("staging", isDirectory: true)
            .appendingPathComponent("selector.next")
    }

    var destinationURL: URL {
        root.appendingPathComponent("published", isDirectory: true)
            .appendingPathComponent("selector")
    }

    func remove() {
        try? FileManager.default.removeItem(at: root)
    }
}
