//
//  CaptureDraftServiceAdversarialTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Darwin
import Foundation
import Testing
@testable import SnapDrillCore

@Suite("CaptureDraftService adversarial lifecycle", .serialized)
struct CaptureDraftServiceAdversarialTests {
    @Test("final generation closes writes until exact settlement completes")
    func finalGenerationClosesWriteAdmission() async throws {
        let fixture = try AdversarialDraftFixture()
        defer { fixture.remove() }
        let first = try await fixture.service.saveDraft(
            image: nil,
            content: "editing",
            category: nil,
            expectedToken: nil
        )
        let final = try await fixture.service.saveDraftAndBeginSettlement(
            image: nil,
            content: "final",
            category: nil,
            expectedToken: first
        )

        await expectAdversarialDraftError(.settlementInProgress) {
            _ = try await fixture.service.saveDraft(
                image: nil,
                content: "late writer",
                category: nil,
                expectedToken: final
            )
        }
        await expectAdversarialDraftError(.settlementInProgress) {
            try await fixture.service.discardDraft(expectedToken: final)
        }

        try await fixture.service.completeSettlement(expectedToken: final)
        #expect(isAdversarialNone(await fixture.service.loadDraftState()))
    }

    @Test("failed final publication does not close write admission")
    func failedFinalPublicationDoesNotLatch() async throws {
        let fixture = try AdversarialDraftFixture()
        defer { fixture.remove() }
        let first = try await fixture.service.saveDraft(
            image: nil,
            content: "old",
            category: nil,
            expectedToken: nil
        )
        let publisher = SwitchingDraftPublisher(shouldFail: true)
        let service = fixture.makeService { bytes, staging, destination, root in
            try publisher.publish(bytes, staging: staging, destination: destination, root: root)
        }

        await expectAdversarialDraftError(.storageFailure) {
            _ = try await service.saveDraftAndBeginSettlement(
                image: nil,
                content: "failed final",
                category: nil,
                expectedToken: first
            )
        }
        publisher.setShouldFail(false)
        let replacement = try await service.saveDraft(
            image: nil,
            content: "retry",
            category: nil,
            expectedToken: first
        )
        #expect(recoverableAdversarialDraft(await service.loadDraftState())?.token == replacement)
    }

    @Test("relaunch reconciliation retires a DB-committed capture ID")
    func relaunchReconcilesCommittedCaptureID() async throws {
        let fixture = try AdversarialDraftFixture()
        defer { fixture.remove() }
        let final = try await fixture.service.saveDraftAndBeginSettlement(
            image: nil,
            content: "committed before crash",
            category: nil,
            expectedToken: nil
        )

        let relaunched = fixture.makeService()
        let recovered = try #require(
            recoverableAdversarialDraft(await relaunched.loadDraftState())
        )
        #expect(recovered.token.captureID == final.captureID)
        await expectAdversarialDraftError(.draftChanged) {
            try await relaunched.completeSettlement(expectedToken: recovered.token)
        }

        let committedItemIDs = Set([final.captureID])
        #expect(committedItemIDs.contains(recovered.token.captureID))
        try await relaunched.discardDraft(expectedToken: recovered.token)
        #expect(isAdversarialNone(await relaunched.loadDraftState()))
    }

    @Test("an empty directory at current.v1 can be explicitly discarded")
    func directoryDraftNodeCanBeDiscarded() async throws {
        let fixture = try AdversarialDraftFixture()
        defer { fixture.remove() }
        try fixture.prepareDraftsDirectory()
        try FileManager.default.createDirectory(at: fixture.draftURL, withIntermediateDirectories: false)

        let failure = try #require(
            unrecoverableAdversarialFailure(await fixture.service.loadDraftState())
        )
        try await fixture.service.discardUnrecoverableDraft(
            expectedToken: try #require(failure.discardToken)
        )
        #expect(isAdversarialNone(await fixture.service.loadDraftState()))
    }

    @Test("file nodes occupying Drafts or its root can be reset explicitly")
    func malformedDirectoryNodesCanBeReset() async throws {
        let draftsFixture = try AdversarialDraftFixture()
        defer { draftsFixture.remove() }
        try FileManager.default.createDirectory(
            at: draftsFixture.root,
            withIntermediateDirectories: true
        )
        try Data("not-a-directory".utf8).write(to: draftsFixture.draftsURL)
        let draftsFailure = try #require(
            unrecoverableAdversarialFailure(await draftsFixture.service.loadDraftState())
        )
        try await draftsFixture.service.discardUnrecoverableDraft(
            expectedToken: try #require(draftsFailure.discardToken)
        )
        _ = try await draftsFixture.service.saveDraft(
            image: nil,
            content: "recovered",
            category: nil,
            expectedToken: nil
        )

        let rootFixture = try AdversarialDraftFixture()
        defer { rootFixture.remove() }
        try Data("not-a-directory".utf8).write(to: rootFixture.root)
        let rootFailure = try #require(
            unrecoverableAdversarialFailure(await rootFixture.service.loadDraftState())
        )
        try await rootFixture.service.discardUnrecoverableDraft(
            expectedToken: try #require(rootFailure.discardToken)
        )
        _ = try await rootFixture.service.saveDraft(
            image: nil,
            content: "recovered",
            category: nil,
            expectedToken: nil
        )
    }

    @Test("first load removes only publisher-shaped staging residue")
    func firstLoadSweepsStagingResidue() async throws {
        let fixture = try AdversarialDraftFixture()
        defer { fixture.remove() }
        try fixture.prepareDraftsDirectory()
        let staging = fixture.draftsURL.appendingPathComponent(
            "current.\(UUID().uuidString.lowercased()).next"
        )
        let unrelated = fixture.draftsURL.appendingPathComponent("current.not-a-uuid.next")
        try Data("stale".utf8).write(to: staging)
        try Data("keep".utf8).write(to: unrelated)

        #expect(isAdversarialNone(await fixture.service.loadDraftState()))
        #expect(!FileManager.default.fileExists(atPath: staging.path))
        #expect(FileManager.default.fileExists(atPath: unrelated.path))
    }

    @Test("oversized writes are rejected before publication")
    func oversizedWriteIsRejected() async throws {
        let fixture = try AdversarialDraftFixture()
        defer { fixture.remove() }
        let store = CaptureDraftFileStore(trustRootURL: fixture.root)
        let oversizedBytes = Data(count: CaptureDraftFileStore.maximumByteCount + 1)

        await expectAdversarialDraftError(.envelopeTooLarge) {
            _ = try await store.replace(oversizedBytes, expectedRevision: nil)
        }
        #expect(isAdversarialNone(await fixture.service.loadDraftState()))
    }

    @Test("oversized stored artifacts fail closed without being read")
    func oversizedStoredArtifactIsUnrecoverable() async throws {
        let fixture = try AdversarialDraftFixture()
        defer { fixture.remove() }
        try fixture.prepareDraftsDirectory()
        #expect(FileManager.default.createFile(atPath: fixture.draftURL.path, contents: nil))
        let handle = try FileHandle(forWritingTo: fixture.draftURL)
        try handle.truncate(atOffset: UInt64(CaptureDraftFileStore.maximumByteCount + 1))
        try handle.close()

        let failure = try #require(
            unrecoverableAdversarialFailure(await fixture.service.loadDraftState())
        )
        #expect(failure.reason == .storageUnavailable)
        try await fixture.service.discardUnrecoverableDraft(
            expectedToken: try #require(failure.discardToken)
        )
        #expect(isAdversarialNone(await fixture.service.loadDraftState()))
    }

    @Test("compare-and-delete rejects bytes changed after token observation")
    func compareAndDeleteRejectsMutatedArtifact() async throws {
        let fixture = try AdversarialDraftFixture()
        defer { fixture.remove() }
        let token = try await fixture.service.saveDraft(
            image: nil,
            content: "observed",
            category: nil,
            expectedToken: nil
        )
        try Data("mutated".utf8).write(to: fixture.draftURL)

        await expectAdversarialDraftError(.draftChanged) {
            try await fixture.service.discardDraft(expectedToken: token)
        }
        #expect(FileManager.default.fileExists(atPath: fixture.draftURL.path))
    }
}

private struct AdversarialDraftFixture {
    let root: URL
    let service: CaptureDraftService

    var draftsURL: URL {
        root.appendingPathComponent(CaptureDraftFileStore.directoryName, isDirectory: true)
    }

    var draftURL: URL {
        draftsURL.appendingPathComponent(CaptureDraftFileStore.fileName)
    }

    init() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("capture-draft-adversarial-\(UUID().uuidString)")
        service = CaptureDraftService(
            fileStore: CaptureDraftFileStore(trustRootURL: root)
        )
    }

    func makeService(
        publish: @escaping CaptureDraftFileStore.Publish = { bytes, staging, destination, root in
            try DurableRegularFilePublisher().publish(
                bytes,
                staging: staging,
                destination: destination,
                beneath: root,
                isExcludedFromBackup: true
            )
        }
    ) -> CaptureDraftService {
        CaptureDraftService(
            fileStore: CaptureDraftFileStore(trustRootURL: root, publish: publish)
        )
    }

    func prepareDraftsDirectory() throws {
        try FileManager.default.createDirectory(at: draftsURL, withIntermediateDirectories: true)
    }

    func remove() {
        try? FileManager.default.removeItem(at: root)
    }
}

private nonisolated final class SwitchingDraftPublisher: @unchecked Sendable {
    private let lock = NSLock()
    private var shouldFail: Bool

    init(shouldFail: Bool) {
        self.shouldFail = shouldFail
    }

    func setShouldFail(_ value: Bool) {
        lock.withLock { shouldFail = value }
    }

    func publish(
        _ bytes: Data,
        staging: DurableRegularFilePublisher.RelativeFile,
        destination: DurableRegularFilePublisher.RelativeFile,
        root: URL
    ) throws {
        let fails = lock.withLock { shouldFail }
        if fails {
            throw DurableRegularFilePublicationError(
                outcome: .notPublished,
                step: .writeStagingBytes,
                code: EIO
            )
        }
        try DurableRegularFilePublisher().publish(
            bytes,
            staging: staging,
            destination: destination,
            beneath: root,
            isExcludedFromBackup: true
        )
    }
}

private func recoverableAdversarialDraft(_ state: CaptureDraftReadState) -> CaptureDraft? {
    guard case .recoverable(let draft) = state else { return nil }
    return draft
}

private func unrecoverableAdversarialFailure(
    _ state: CaptureDraftReadState
) -> CaptureDraftFailure? {
    guard case .unrecoverable(let failure) = state else { return nil }
    return failure
}

private func isAdversarialNone(_ state: CaptureDraftReadState) -> Bool {
    if case .none = state { return true }
    return false
}

private func expectAdversarialDraftError(
    _ expected: CaptureDraftError,
    operation: () async throws -> Void
) async {
    do {
        try await operation()
        Issue.record("Expected \(expected), but operation succeeded")
    } catch let error as CaptureDraftError {
        #expect(error == expected)
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}
