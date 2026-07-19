//
//  DurableRegularFilePublisherBindingTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Darwin
import Foundation
import Testing
@testable import SnapDrillCore

@Suite("Durable regular-file identity binding", .serialized)
struct DurableRegularFilePublisherBindingTests {
    @Test("Rename receives the complete no-follow and beneath flag set")
    func renameUsesStrictFlags() throws {
        let fixture = try BindingFixture()
        defer { fixture.remove() }
        var calls = DurableRegularFileSystemCalls.live
        let liveRename = calls.renameAt
        var observedFlags: UInt32?
        calls.renameAt = { oldParent, oldPath, newParent, newPath, flags in
            observedFlags = flags
            return liveRename(oldParent, oldPath, newParent, newPath, flags)
        }

        try publish(fixture, using: testPublisher(calls: calls))

        let expectedFlags = UInt32(RENAME_NOFOLLOW_ANY | RENAME_RESOLVE_BENEATH)
        #expect(observedFlags == expectedFlags)
        #expect(try Data(contentsOf: fixture.destinationURL) == fixture.newBytes)
    }

    @Test("Destination inode substitution is rejected before rename")
    func destinationIdentitySubstitutionIsRejected() throws {
        let fixture = try BindingFixture()
        defer { fixture.remove() }
        var calls = DurableRegularFileSystemCalls.live
        let liveStatAt = calls.statAt
        var destinationInspections = 0
        calls.statAt = { parent, path, metadata, flags in
            let result = liveStatAt(parent, path, metadata, flags)
            if result == 0, String(cString: path) == "selector" {
                destinationInspections += 1
                if destinationInspections == 2 {
                    metadata.pointee.st_ino &+= 1
                }
            }
            return result
        }

        let error = try publicationError {
            try publish(fixture, using: testPublisher(calls: calls))
        }

        #expect(error.outcome == .notPublished)
        #expect(error.step == .revalidateDestination)
        #expect(try Data(contentsOf: fixture.destinationURL) == fixture.oldBytes)
    }

    @Test("Final inode substitution reports an uncertain publication")
    func finalIdentitySubstitutionIsUncertain() throws {
        let fixture = try BindingFixture()
        defer { fixture.remove() }
        var calls = DurableRegularFileSystemCalls.live
        let liveRename = calls.renameAt
        let liveStat = calls.stat
        var didRename = false
        calls.renameAt = { oldParent, oldPath, newParent, newPath, flags in
            let result = liveRename(oldParent, oldPath, newParent, newPath, flags)
            didRename = result == 0
            return result
        }
        calls.stat = { descriptor, metadata in
            let result = liveStat(descriptor, metadata)
            if result == 0, didRename {
                metadata.pointee.st_ino &+= 1
            }
            return result
        }

        let error = try publicationError {
            try publish(fixture, using: testPublisher(calls: calls))
        }

        #expect(error.outcome == .publicationOutcomeUncertain)
        #expect(error.step == .verifyFinalNode)
        #expect(try Data(contentsOf: fixture.destinationURL) == fixture.newBytes)
    }

    @Test("Parent rebind before the first attribute call is blocked")
    func preOperationParentRebindIsBlocked() throws {
        let fixture = try BindingFixture()
        defer { fixture.remove() }
        let stagingParent = fixture.stagingURL.deletingLastPathComponent()
        let movedParent = fixture.root.appendingPathComponent(
            "staging-precheck-original",
            isDirectory: true
        )
        var calls = DurableRegularFileSystemCalls.live
        let liveOpenAt = calls.openAt
        var stagingParentOpenCount = 0
        var rebindFailure: String?
        calls.openAt = { parent, path, flags in
            if String(cString: path) == "staging", flags & O_DIRECTORY != 0 {
                stagingParentOpenCount += 1
                if stagingParentOpenCount == 2 {
                    do {
                        try FileManager.default.moveItem(at: stagingParent, to: movedParent)
                        try FileManager.default.createDirectory(
                            at: stagingParent,
                            withIntermediateDirectories: false
                        )
                    } catch {
                        rebindFailure = String(describing: error)
                        errno = EIO
                        return -1
                    }
                }
            }
            return liveOpenAt(parent, path, flags)
        }
        var attributeCallCount = 0
        var attributes = passingAttributes
        attributes.setProtection = { _ in attributeCallCount += 1 }

        let error = try publicationError {
            try publish(
                fixture,
                using: testPublisher(calls: calls, attributes: attributes)
            )
        }

        #expect(rebindFailure == nil)
        #expect(attributeCallCount == 0)
        #expect(error.outcome == .notPublished)
        #expect(error.step == .applyProtection)
        #expect(try Data(contentsOf: fixture.destinationURL) == fixture.oldBytes)
    }

    @Test("Staging parent rebind is rejected after a Foundation attribute write")
    func stagingParentRebindIsRejected() throws {
        let fixture = try BindingFixture()
        defer { fixture.remove() }
        let stagingParent = fixture.stagingURL.deletingLastPathComponent()
        let movedParent = fixture.root.appendingPathComponent(
            "staging-original",
            isDirectory: true
        )
        var attributes = passingAttributes
        attributes.setProtection = { _ in
            try FileManager.default.moveItem(at: stagingParent, to: movedParent)
            try FileManager.default.createDirectory(
                at: stagingParent,
                withIntermediateDirectories: false
            )
        }

        let error = try publicationError {
            try publish(fixture, using: testPublisher(attributes: attributes))
        }

        #expect(error.outcome == .notPublished)
        #expect(error.step == .applyProtection)
        #expect(try Data(contentsOf: fixture.destinationURL) == fixture.oldBytes)
        #expect(
            FileManager.default.fileExists(
                atPath: movedParent.appendingPathComponent("selector.next").path
            )
        )
    }

    @Test("Staging regular-file substitution is rejected after an attribute write")
    func stagingFileSubstitutionIsRejected() throws {
        let fixture = try BindingFixture()
        defer { fixture.remove() }
        let originalStaging = fixture.root.appendingPathComponent("staging-original-file")
        var attributes = passingAttributes
        attributes.setProtection = { _ in
            try FileManager.default.moveItem(
                at: fixture.stagingURL,
                to: originalStaging
            )
            try fixture.newBytes.write(to: fixture.stagingURL)
        }

        let error = try publicationError {
            try publish(fixture, using: testPublisher(attributes: attributes))
        }

        #expect(error.outcome == .notPublished)
        #expect(error.step == .applyProtection)
        #expect(try Data(contentsOf: fixture.destinationURL) == fixture.oldBytes)
        #expect(try Data(contentsOf: originalStaging) == fixture.newBytes)
    }

    @Test("Root rebind during final readback reports an uncertain publication")
    func finalRootRebindIsUncertain() throws {
        let fixture = try BindingFixture()
        let movedRoot = fixture.root.deletingLastPathComponent()
            .appendingPathComponent("publisher-original-\(UUID().uuidString)", isDirectory: true)
        defer {
            fixture.remove()
            try? FileManager.default.removeItem(at: movedRoot)
        }
        var attributes = passingAttributes
        var verificationCount = 0
        attributes.verify = { _, _ in
            verificationCount += 1
            if verificationCount == 2 {
                try FileManager.default.moveItem(at: fixture.root, to: movedRoot)
                try FileManager.default.createDirectory(
                    at: fixture.root.appendingPathComponent("published", isDirectory: true),
                    withIntermediateDirectories: true
                )
            }
            return true
        }

        let error = try publicationError {
            try publish(fixture, using: testPublisher(attributes: attributes))
        }
        let movedDestination = movedRoot.appendingPathComponent("published", isDirectory: true)
            .appendingPathComponent("selector")

        #expect(error.outcome == .publicationOutcomeUncertain)
        #expect(error.step == .verifyFinalAttributes)
        #expect(try Data(contentsOf: movedDestination) == fixture.newBytes)
    }
}

private extension DurableRegularFilePublisherBindingTests {
    func publish(
        _ fixture: BindingFixture,
        using publisher: DurableRegularFilePublisher
    ) throws {
        try publisher.publish(
            fixture.newBytes,
            staging: fixture.staging,
            destination: fixture.destination,
            beneath: fixture.root,
            isExcludedFromBackup: false
        )
    }

    func publicationError(
        _ operation: () throws -> Void
    ) throws -> DurableRegularFilePublicationError {
        do {
            try operation()
            Issue.record("Expected publication to fail")
            throw BindingTestFailure.missingPublicationError
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

private nonisolated enum BindingTestFailure: Error {
    case missingPublicationError
}

private nonisolated struct BindingFixture {
    let root: URL
    let staging: DurableRegularFilePublisher.RelativeFile
    let destination: DurableRegularFilePublisher.RelativeFile
    let oldBytes = Data("old-selector\n".utf8)
    let newBytes = Data("new-selector\n".utf8)

    init() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("DurableBinding-\(UUID().uuidString)", isDirectory: true)
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
