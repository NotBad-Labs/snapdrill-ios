//
//  CaptureDraftServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Darwin
import Foundation
import Testing
import UIKit
@testable import SnapDrillCore

@Suite("CaptureDraftService crash-consistent storage", .serialized)
struct CaptureDraftServiceTests {
    @Test("clean absence is distinct from an unreadable artifact")
    func cleanAbsenceAndUnreadableArtifactAreDistinct() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }

        #expect(isNone(await fixture.service.loadDraftState()))

        try fixture.prepareDraftsDirectory()
        try Data("not-json".utf8).write(to: fixture.draftURL)
        let state = await fixture.service.loadDraftState()
        guard case .unrecoverable(let failure) = state else {
            Issue.record("Malformed bytes must fail closed instead of becoming no draft")
            return
        }
        #expect(failure.reason == .malformedEnvelope)
        #expect(failure.discardToken != nil)
    }

    @Test("image, text, category, IDs, and timestamp round-trip in one generation")
    func completeGenerationRoundTrips() async throws {
        let savedAt = Date(timeIntervalSince1970: 1_800_000_000.123)
        let fixture = try Fixture(now: { savedAt })
        defer { fixture.remove() }

        let token = try await fixture.service.saveDraft(
            image: makeImage(),
            content: "OCR ∫₀^∞",
            category: "数学",
            expectedToken: nil
        )
        let draft = recoverable(await fixture.service.loadDraftState())

        #expect(draft?.token == token)
        #expect(draft?.content == "OCR ∫₀^∞")
        #expect(draft?.category == "数学")
        #expect(draft?.image?.size.width == 12)
        #expect(abs((draft?.date.timeIntervalSince1970 ?? 0) - savedAt.timeIntervalSince1970) < 0.001)
    }

    @Test("an empty generation is rejected before publication")
    func emptyGenerationIsRejected() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }

        await expectDraftError(.emptyDraft) {
            _ = try await fixture.service.saveDraft(
                image: nil,
                content: " \n ",
                category: "category alone is not content",
                expectedToken: nil
            )
        }

        #expect(isNone(await fixture.service.loadDraftState()))
        #expect(!FileManager.default.fileExists(atPath: fixture.draftURL.path))
    }

    @Test("a draft never expires based on age")
    func oldDraftDoesNotExpire() async throws {
        let oldDate = Date(timeIntervalSince1970: 946_684_800)
        let fixture = try Fixture(now: { oldDate })
        defer { fixture.remove() }

        _ = try await fixture.service.saveDraft(
            image: nil,
            content: "keep until save or discard",
            category: nil,
            expectedToken: nil
        )

        let relaunched = fixture.makeService(now: { Date.distantFuture })
        let draft = recoverable(await relaunched.loadDraftState())
        #expect(draft?.content == "keep until save or discard")
        #expect(draft?.date == oldDate)
    }

    @Test("storage is Profile-free and Drafts is excluded from device backup")
    func storageIsProfileFreeAndExcludedFromBackup() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let defaults = UserDefaults.standard
        let originalProfile = defaults.string(forKey: UDKey.activeProfileId)
        defer {
            if let originalProfile {
                defaults.set(originalProfile, forKey: UDKey.activeProfileId)
            } else {
                defaults.removeObject(forKey: UDKey.activeProfileId)
            }
        }

        defaults.set("profile-a", forKey: UDKey.activeProfileId)
        _ = try await fixture.service.saveDraft(
            image: nil,
            content: "one library",
            category: nil,
            expectedToken: nil
        )
        defaults.set("profile-b", forKey: UDKey.activeProfileId)

        #expect(recoverable(await fixture.service.loadDraftState())?.content == "one library")
        #expect(fixture.draftURL.path == fixture.root.appendingPathComponent("Drafts/current.v1").path)
        let values = try fixture.draftsURL.resourceValues(forKeys: [.isExcludedFromBackupKey])
        #expect(values.isExcludedFromBackup == true)
    }

    @Test("stale generations cannot overwrite or discard a newer draft")
    func staleGenerationIsRejected() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let first = try await fixture.service.saveDraft(
            image: nil,
            content: "first",
            category: nil,
            expectedToken: nil
        )
        let second = try await fixture.service.saveDraft(
            image: nil,
            content: "second",
            category: nil,
            expectedToken: first
        )

        await expectDraftError(.draftChanged) {
            _ = try await fixture.service.saveDraft(
                image: nil,
                content: "late OCR",
                category: nil,
                expectedToken: first
            )
        }
        await expectDraftError(.draftChanged) {
            try await fixture.service.discardDraft(expectedToken: first)
        }
        #expect(recoverable(await fixture.service.loadDraftState())?.token == second)
    }

    @Test("a failed pre-rename publication preserves the old generation")
    func preRenameFailurePreservesOldGeneration() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let oldToken = try await fixture.service.saveDraft(
            image: nil,
            content: "old",
            category: nil,
            expectedToken: nil
        )
        let failing = fixture.makeService(publish: { _, _, _, _ in
            throw DurableRegularFilePublicationError(
                outcome: .notPublished,
                step: .writeStagingBytes,
                code: EIO
            )
        })

        await expectDraftError(.storageFailure) {
            _ = try await failing.saveDraft(
                image: nil,
                content: "new",
                category: nil,
                expectedToken: oldToken
            )
        }
        #expect(recoverable(await fixture.service.loadDraftState())?.content == "old")
    }

    @Test("an uncertain post-rename result is reconciled from actual bytes")
    func uncertainPublicationReconcilesCommittedGeneration() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let oldToken = try await fixture.service.saveDraft(
            image: nil,
            content: "old",
            category: nil,
            expectedToken: nil
        )
        let uncertain = fixture.makeService { bytes, _, destination, root in
            let destinationURL = destination.parentComponents.reduce(root) {
                $0.appendingPathComponent($1, isDirectory: true)
            }.appendingPathComponent(destination.fileName)
            try bytes.write(to: destinationURL, options: .atomic)
            throw DurableRegularFilePublicationError(
                outcome: .publicationOutcomeUncertain,
                step: .synchronizeDestinationParent,
                code: EIO
            )
        }

        let newToken = try await uncertain.saveDraft(
            image: nil,
            content: "new",
            category: nil,
            expectedToken: oldToken
        )
        let draft = recoverable(await fixture.service.loadDraftState())
        #expect(draft?.content == "new")
        #expect(draft?.token == newToken)
    }

    @Test("tampered payload reports integrity failure and can be explicitly discarded")
    func tamperedPayloadFailsIntegrityCheck() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        _ = try await fixture.service.saveDraft(
            image: nil,
            content: "trusted",
            category: nil,
            expectedToken: nil
        )
        var object = try #require(
            JSONSerialization.jsonObject(with: Data(contentsOf: fixture.draftURL))
                as? [String: Any]
        )
        object["payload"] = Data("tampered".utf8).base64EncodedString()
        try JSONSerialization.data(withJSONObject: object).write(to: fixture.draftURL)

        guard case .unrecoverable(let failure) = await fixture.service.loadDraftState() else {
            Issue.record("Tampered payload must be unrecoverable")
            return
        }
        #expect(failure.reason == .integrityCheckFailed)
        let token = try #require(failure.discardToken)
        try await fixture.service.discardUnrecoverableDraft(expectedToken: token)
        #expect(isNone(await fixture.service.loadDraftState()))
    }

    @Test("unsupported schema and invalid JPEG remain explicit failures")
    func unsupportedSchemaAndInvalidImageAreExplicit() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        try fixture.prepareDraftsDirectory()

        try fixture.writeEnvelope(schemaVersion: 99, payload: Data())
        #expect(failureReason(await fixture.service.loadDraftState()) == .unsupportedVersion)

        let payload = TestPayload(
            captureID: UUID(),
            generationID: UUID(),
            timestampMilliseconds: 1,
            content: "bad image",
            category: nil,
            imageJPEG: Data("not-an-image".utf8)
        )
        try fixture.writeEnvelope(payload: JSONEncoder.sorted.encode(payload))
        #expect(failureReason(await fixture.service.loadDraftState()) == .imageDecodeFailed)
    }

    @Test("a digest-valid empty payload remains an explicit failure")
    func digestValidEmptyPayloadIsRejected() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        try fixture.prepareDraftsDirectory()
        let payload = TestPayload(
            captureID: UUID(),
            generationID: UUID(),
            timestampMilliseconds: 1,
            content: " \n ",
            category: "metadata only",
            imageJPEG: nil
        )

        try fixture.writeEnvelope(payload: JSONEncoder.sorted.encode(payload))

        #expect(failureReason(await fixture.service.loadDraftState()) == .emptyDraft)
    }

    @Test("declared payload, text, and image lengths must match encoded bytes")
    func mismatchedLengthsFailIntegrityCheck() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        try fixture.prepareDraftsDirectory()
        let payload = TestPayload(
            captureID: UUID(),
            generationID: UUID(),
            timestampMilliseconds: 1,
            content: "资料",
            contentUTF8ByteCount: 1,
            category: nil,
            imageJPEG: nil
        )
        let payloadBytes = try JSONEncoder.sorted.encode(payload)

        try fixture.writeEnvelope(payload: payloadBytes)
        #expect(failureReason(await fixture.service.loadDraftState()) == .integrityCheckFailed)

        try fixture.writeEnvelope(
            payload: payloadBytes,
            payloadByteCount: payloadBytes.count + 1
        )
        #expect(failureReason(await fixture.service.loadDraftState()) == .integrityCheckFailed)
    }

    @Test("settlement blocks late writes, abort preserves, and completion retires exact draft")
    func settlementControlsWriteAdmission() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let first = try await fixture.service.saveDraft(
            image: nil,
            content: "ready",
            category: nil,
            expectedToken: nil
        )
        try await fixture.service.beginSettlement(expectedToken: first)
        await expectDraftError(.settlementInProgress) {
            _ = try await fixture.service.saveDraft(
                image: nil,
                content: "late",
                category: nil,
                expectedToken: first
            )
        }

        await fixture.service.abortSettlement(expectedToken: first)
        let second = try await fixture.service.saveDraft(
            image: nil,
            content: "updated",
            category: nil,
            expectedToken: first
        )
        try await fixture.service.beginSettlement(expectedToken: second)
        try await fixture.service.completeSettlement(expectedToken: second)
        #expect(isNone(await fixture.service.loadDraftState()))
    }

    @Test("discarding a symlink removes only the fixed draft entry")
    func symlinkDiscardDoesNotDeleteTarget() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        try fixture.prepareDraftsDirectory()
        let outside = fixture.root.appendingPathComponent("outside")
        try Data("keep".utf8).write(to: outside)
        try FileManager.default.createSymbolicLink(
            at: fixture.draftURL,
            withDestinationURL: outside
        )

        guard case .unrecoverable(let failure) = await fixture.service.loadDraftState() else {
            Issue.record("A symlinked draft must fail closed")
            return
        }
        let token = try #require(failure.discardToken)
        try await fixture.service.discardUnrecoverableDraft(expectedToken: token)
        #expect(try Data(contentsOf: outside) == Data("keep".utf8))
        #expect(!FileManager.default.fileExists(atPath: fixture.draftURL.path))
    }
}

private struct Fixture {
    let root: URL
    let service: CaptureDraftService

    var draftsURL: URL {
        root.appendingPathComponent(CaptureDraftFileStore.directoryName, isDirectory: true)
    }

    var draftURL: URL {
        draftsURL.appendingPathComponent(CaptureDraftFileStore.fileName)
    }

    init(now: @escaping () -> Date = Date.init) throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("capture-draft-\(UUID().uuidString)", isDirectory: true)
        service = CaptureDraftService(
            fileStore: CaptureDraftFileStore(trustRootURL: root),
            now: now
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
        },
        now: @escaping () -> Date = Date.init
    ) -> CaptureDraftService {
        CaptureDraftService(
            fileStore: CaptureDraftFileStore(trustRootURL: root, publish: publish),
            now: now
        )
    }

    func prepareDraftsDirectory() throws {
        try FileManager.default.createDirectory(at: draftsURL, withIntermediateDirectories: true)
    }

    func writeEnvelope(
        schemaVersion: Int = 1,
        payload: Data,
        payloadByteCount: Int? = nil
    ) throws {
        let envelope = TestEnvelope(
            schemaVersion: schemaVersion,
            payload: payload,
            payloadByteCount: payloadByteCount
        )
        try JSONEncoder.sorted.encode(envelope).write(to: draftURL)
    }

    func remove() {
        try? FileManager.default.removeItem(at: root)
    }
}

private func recoverable(_ state: CaptureDraftReadState) -> CaptureDraft? {
    guard case .recoverable(let draft) = state else { return nil }
    return draft
}

private func failureReason(_ state: CaptureDraftReadState) -> CaptureDraftFailureReason? {
    guard case .unrecoverable(let failure) = state else { return nil }
    return failure.reason
}

private func isNone(_ state: CaptureDraftReadState) -> Bool {
    if case .none = state { return true }
    return false
}

private func expectDraftError(
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

private func makeImage() -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return UIGraphicsImageRenderer(
        size: CGSize(width: 12, height: 8),
        format: format
    ).image { context in
        UIColor.red.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 12, height: 8))
    }
}
