import Darwin
import Foundation
import Testing
import UIKit
@testable import SnapDrillCore

@Suite("Capture draft crash consistency", .serialized)
struct CaptureDraftServiceTests {
    @Test("one envelope round-trips across a fresh service instance")
    func roundTripAcrossRelaunch() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        let token = try await fixture.service.saveDraft(
            image: testImage(.red),
            content: "OCR text",
            category: "Inbox",
            captureID: nil,
            expected: nil
        )

        let reopened = try fixture.makeService()
        guard case .recoverable(let draft) = reopened.state() else {
            Issue.record("Expected a recoverable draft after reopening")
            return
        }
        #expect(draft.token == token)
        #expect(draft.content == "OCR text")
        #expect(draft.category == "Inbox")
        #expect(draft.image != nil)
    }

    @Test("rename failure preserves the prior committed generation byte-for-byte")
    func renameFailurePreservesOldGeneration() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        let old = try await fixture.service.saveDraft(
            image: testImage(.red),
            content: "old",
            category: nil,
            captureID: nil,
            expected: nil
        )
        let oldBytes = try Data(contentsOf: fixture.store.currentURL)
        let failingService = try fixture.makeService(
            publisher: Self.renameFailingPublisher()
        )

        await #expect(throws: CaptureDraftServiceError.persistenceFailed) {
            try await failingService.saveDraft(
                image: testImage(.blue),
                content: "new",
                category: nil,
                captureID: old.captureID,
                expected: old
            )
        }

        #expect(try Data(contentsOf: fixture.store.currentURL) == oldBytes)
        guard case .recoverable(let reopened) = try fixture.makeService().state() else {
            Issue.record("Old generation should remain recoverable")
            return
        }
        #expect(reopened.token == old)
        #expect(reopened.content == "old")
    }

    @Test("post-rename sync failure needs an exact durable retry before success")
    func uncertainPublishRequiresExactDurableRetry() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        let old = try await fixture.service.saveDraft(
            image: testImage(.red),
            content: "old",
            category: nil,
            captureID: nil,
            expected: nil
        )
        let uncertainService = try fixture.makeService(
            publisher: postRenameSyncFailingOncePublisher()
        )

        await #expect(throws: CaptureDraftServiceError.publicationOutcomeUncertain) {
            try await uncertainService.saveDraft(
                image: testImage(.blue),
                content: "new",
                category: nil,
                captureID: old.captureID,
                expected: old
            )
        }

        guard case .recoverable(let reopened) = try fixture.makeService().state() else {
            Issue.record("Atomic rename should expose the uncertain generation")
            return
        }
        let new = try await uncertainService.saveDraft(
            image: testImage(.blue),
            content: "new",
            category: nil,
            captureID: old.captureID,
            expected: old
        )
        #expect(reopened.token == new)
        #expect(reopened.content == "new")
    }

    @Test("transient post-publish read failure returns the exact generation on retry")
    func transientVerificationReadFailureReconcilesExactRetry() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        var files = CaptureDraftFileOperations.live
        let liveRead = files.read
        var shouldFailRead = true
        files.read = { url in
            if shouldFailRead {
                shouldFailRead = false
                throw CocoaError(.fileReadUnknown)
            }
            return try liveRead(url)
        }
        let service = try fixture.makeService(files: files)

        await #expect(throws: CaptureDraftServiceError.publicationOutcomeUncertain) {
            try await service.saveDraft(
                image: nil,
                content: "uncertain",
                category: nil,
                captureID: nil,
                expected: nil
            )
        }
        let committedBytes = try Data(contentsOf: fixture.store.currentURL)
        guard case .recoverable(let reopened) = try fixture.makeService().state() else {
            Issue.record("Atomic publish installed a generation despite transient verification failure")
            return
        }

        let reconciled = try await service.saveDraft(
            image: nil,
            content: "uncertain",
            category: nil,
            captureID: nil,
            expected: nil
        )

        #expect(reconciled == reopened.token)
        #expect(try Data(contentsOf: fixture.store.currentURL) == committedBytes)
    }

    @Test("image encoding failure cannot destroy the prior generation")
    func imageEncodingFailurePreservesOldGeneration() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        let old = try await fixture.service.saveDraft(
            image: testImage(.red),
            content: "old",
            category: nil,
            captureID: nil,
            expected: nil
        )
        let oldBytes = try Data(contentsOf: fixture.store.currentURL)

        await #expect(throws: CaptureDraftServiceError.imageEncodingFailed) {
            try await fixture.service.saveDraft(
                image: UIImage(),
                content: "new",
                category: nil,
                captureID: old.captureID,
                expected: old
            )
        }
        #expect(try Data(contentsOf: fixture.store.currentURL) == oldBytes)
    }

    @Test("late enrichment and discard cannot mutate a newer generation")
    func staleMutationsAreRejected() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        let first = try await fixture.service.saveDraft(
            image: testImage(.red),
            content: "",
            category: nil,
            captureID: nil,
            expected: nil
        )
        let second = try await fixture.service.saveDraft(
            image: testImage(.red),
            content: "enriched",
            category: nil,
            captureID: first.captureID,
            expected: first
        )
        let committedBytes = try Data(contentsOf: fixture.store.currentURL)

        await #expect(throws: CaptureDraftServiceError.staleGeneration) {
            try await fixture.service.saveDraft(
                image: testImage(.blue),
                content: "late",
                category: nil,
                captureID: first.captureID,
                expected: first
            )
        }
        #expect(throws: CaptureDraftServiceError.staleGeneration) {
            try fixture.service.discard(.generation(first))
        }
        #expect(try Data(contentsOf: fixture.store.currentURL) == committedBytes)
        guard case .recoverable(let current) = fixture.service.state() else {
            Issue.record("Newer generation should remain")
            return
        }
        #expect(current.token == second)
    }

    @Test("settlement fences late writes and abort reopens admission")
    func settlementFenceAndAbort() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        let token = try await fixture.service.saveDraft(
            image: testImage(.red),
            content: "draft",
            category: nil,
            captureID: nil,
            expected: nil
        )
        let settlement = try await fixture.service.beginSettlement(
            captureID: token.captureID,
            expected: token
        )

        await #expect(throws: CaptureDraftServiceError.admissionClosed) {
            try await fixture.service.saveDraft(
                image: testImage(.blue),
                content: "late",
                category: nil,
                captureID: token.captureID,
                expected: token
            )
        }

        try fixture.service.abortSettlement(settlement)
        #expect(try fixture.makeService().pendingSettlementToken() == nil)
        let enriched = try await fixture.service.saveDraft(
            image: testImage(.blue),
            content: "retry",
            category: nil,
            captureID: token.captureID,
            expected: token
        )
        #expect(enriched.captureID == token.captureID)
    }

    @Test("committed settlement conditionally retires once and blocks resurrection")
    func committedSettlementRetiresAndStaysClosed() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        let token = try await fixture.service.saveDraft(
            image: testImage(.red),
            content: "draft",
            category: nil,
            captureID: nil,
            expected: nil
        )
        let settlement = try await fixture.service.beginSettlement(
            captureID: token.captureID,
            expected: token
        )
        try fixture.service.retireCommittedDraft(settlement)
        guard case .none = fixture.service.state() else {
            Issue.record("Committed generation should be retired")
            return
        }

        await #expect(throws: CaptureDraftServiceError.admissionClosed) {
            try await fixture.service.saveDraft(
                image: testImage(.blue),
                content: "late",
                category: nil,
                captureID: token.captureID,
                expected: nil
            )
        }
    }

    @Test("mock settlement enforces production capture identity and empty-state rules")
    func mockSettlementMatchesProductionGuards() async throws {
        let draft = CaptureDraft(
            image: nil,
            content: "draft",
            date: Date(),
            category: nil
        )
        let occupied = CaptureDraftServiceMock(initialDraft: draft)

        await #expect(throws: CaptureDraftServiceError.staleGeneration) {
            try await occupied.beginSettlement(
                captureID: UUID(),
                expected: draft.token
            )
        }
        await #expect(throws: CaptureDraftServiceError.draftAlreadyExists) {
            try await occupied.beginSettlement(
                captureID: draft.token.captureID,
                expected: nil
            )
        }

        let empty = CaptureDraftServiceMock()
        _ = try await empty.beginSettlement(
            captureID: UUID(),
            expected: nil
        )
    }

    @Test(
        "expiry boundary is recoverable before seven days and absent at or after",
        arguments: [
            -0.001,
            0,
            0.001
        ]
    )
    func exactExpiryBoundary(offset: TimeInterval) async throws {
        let savedAt = Date(timeIntervalSince1970: 1_800_000_000)
        var observedNow = savedAt
        let fixture = try CaptureDraftTestFixture(now: { observedNow })
        defer { fixture.cleanup() }
        _ = try await fixture.service.saveDraft(
            image: testImage(.red),
            content: "",
            category: nil,
            captureID: nil,
            expected: nil
        )
        observedNow = savedAt.addingTimeInterval(7 * 24 * 60 * 60 + offset)

        if offset < 0 {
            guard case .recoverable = fixture.service.state() else {
                Issue.record("Draft should remain before the exact deadline")
                return
            }
        } else {
            guard case .none = fixture.service.state() else {
                Issue.record("Draft should expire at the exact deadline")
                return
            }
            #expect(FileManager.default.fileExists(atPath: fixture.store.currentURL.path) == false)
        }
    }

    @Test(
        "corrupt envelopes produce typed unrecoverable state",
        arguments: Corruption.allCases
    )
    func corruptionMatrix(corruption: Corruption) async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        _ = try await fixture.service.saveDraft(
            image: testImage(.red),
            content: "valid",
            category: nil,
            captureID: nil,
            expected: nil
        )
        let original = try Data(contentsOf: fixture.store.currentURL)
        try corruption.apply(to: fixture.store.currentURL, original: original)

        guard case .unrecoverable(let failure) = try fixture.makeService().state() else {
            Issue.record("Corrupt bytes must not enter the editor")
            return
        }
        #expect(failure.reason == corruption.expectedReason)
    }

    @Test("unrecoverable discard uses a byte fingerprint CAS")
    func corruptDiscardIsConditional() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        try Data("broken-old".utf8).write(to: fixture.preparedCurrentURL())
        guard case .unrecoverable(let oldFailure) = fixture.service.state() else {
            Issue.record("Expected corrupt state")
            return
        }
        try Data("broken-new".utf8).write(to: fixture.store.currentURL)

        #expect(throws: CaptureDraftServiceError.staleGeneration) {
            try fixture.service.discard(oldFailure.revision)
        }
        #expect(try Data(contentsOf: fixture.store.currentURL) == Data("broken-new".utf8))
    }

    private static func renameFailingPublisher() -> DurableRegularFilePublisher {
        var calls = DurableRegularFileSystemCalls.live
        calls.renameAt = { _, _, _, _, _ in
            errno = EIO
            return -1
        }
        return DurableRegularFilePublisher(systemCalls: calls)
    }

}
