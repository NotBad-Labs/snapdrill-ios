import Foundation
import Testing
@testable import SnapDrillCore

@Suite("Capture draft relaunch safety", .serialized)
struct CaptureDraftRelaunchSafetyTests {
    @Test("fresh service completes directory durability before exposing an uncertain publish")
    func relaunchSynchronizesUncertainPublicationBeforeRecovery() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        let old = try await fixture.service.saveDraft(
            image: nil,
            content: "old",
            category: nil,
            captureID: nil,
            expected: nil
        )
        let uncertain = try fixture.makeService(
            publisher: postRenameSyncFailingOncePublisher()
        )
        await #expect(throws: CaptureDraftServiceError.publicationOutcomeUncertain) {
            try await uncertain.saveDraft(
                image: nil,
                content: "new",
                category: nil,
                captureID: old.captureID,
                expected: old
            )
        }
        let installed = try CaptureDraftEnvelopeCodec()
            .decode(Data(contentsOf: fixture.store.currentURL))

        var files = CaptureDraftFileOperations.live
        let liveSync = files.synchronizeDirectory
        var syncCount = 0
        files.synchronizeDirectory = { url in
            syncCount += 1
            if syncCount == 1 {
                throw CocoaError(.fileWriteUnknown)
            }
            try liveSync(url)
        }
        let reopened = try fixture.makeService(files: files)

        guard case .durabilityPending(let revision) = reopened.state() else {
            Issue.record("Recovery must stay hidden until the relaunch sync succeeds")
            return
        }
        #expect(revision == .generation(installed.token))
        guard case .recoverable(let recovered) = reopened.state() else {
            Issue.record("A later successful directory sync should reopen exact recovery")
            return
        }
        #expect(recovered.token == installed.token)
        #expect(syncCount == 5)
    }

    @Test("relaunch derives settlement pending state from durable evidence")
    func relaunchHidesSettlementUntilArchiveAbsenceIsReconciled() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        let token = try await fixture.service.saveDraft(
            image: nil,
            content: "pending",
            category: nil,
            captureID: nil,
            expected: nil
        )
        _ = try await fixture.service.beginSettlement(
            captureID: token.captureID,
            expected: token
        )

        let reopened = try fixture.makeService()
        guard case .settlementPending(let pending) = reopened.state() else {
            Issue.record("A durable settlement marker must hide editable recovery")
            return
        }
        #expect(pending == token)

        try reopened.reconcileUncommittedDraft(token)
        guard case .recoverable(let recovered) = reopened.state() else {
            Issue.record("Durable marker abort should reopen the exact draft")
            return
        }
        #expect(recovered.token == token)
        #expect(reopened.pendingSettlementToken() == nil)
    }

    @Test("transient marker read failure stays closed until exact evidence is readable")
    func unreadableSettlementMarkerRetriesWithoutExposingRecovery() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        let token = try await fixture.service.saveDraft(
            image: nil,
            content: "pending",
            category: nil,
            captureID: nil,
            expected: nil
        )
        _ = try await fixture.service.beginSettlement(
            captureID: token.captureID,
            expected: token
        )

        var files = CaptureDraftFileOperations.live
        let liveRead = files.read
        var shouldFailMarkerRead = true
        files.read = { url in
            if url.lastPathComponent == "settlement.v1", shouldFailMarkerRead {
                shouldFailMarkerRead = false
                throw CocoaError(.fileReadUnknown)
            }
            return try liveRead(url)
        }
        let reopened = try fixture.makeService(files: files)

        guard case .durabilityPending(let revision) = reopened.state() else {
            Issue.record("Unreadable settlement evidence must not expose recovery")
            return
        }
        #expect(revision == .generation(token))
        guard case .settlementPending(let pending) = reopened.state() else {
            Issue.record("A later successful read must restore exact settlement state")
            return
        }
        #expect(pending == token)
    }

    @Test("corrupt marker stays closed until exact uncommitted reconciliation")
    func corruptSettlementMarkerReopensExactDraft() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        let token = try await fixture.service.saveDraft(
            image: nil,
            content: "pending",
            category: nil,
            captureID: nil,
            expected: nil
        )
        _ = try await fixture.service.beginSettlement(
            captureID: token.captureID,
            expected: token
        )
        try Data("corrupt marker".utf8).write(to: fixture.store.settlementURL)
        let reopened = try fixture.makeService()

        guard case .durabilityPending(let revision) = reopened.state() else {
            Issue.record("Corrupt settlement evidence must keep recovery closed")
            return
        }
        #expect(revision == .generation(token))
        #expect(reopened.pendingSettlementToken() == token)

        try reopened.reconcileUncommittedDraft(token)

        guard case .recoverable(let draft) = reopened.state() else {
            Issue.record("An absent archive must reopen the exact current draft")
            return
        }
        #expect(draft.token == token)
        #expect(!FileManager.default.fileExists(atPath: fixture.store.settlementURL.path))
    }

    @Test("corrupt marker and committed archive retire the exact draft")
    func corruptSettlementMarkerRetiresCommittedDraft() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        let token = try await fixture.service.saveDraft(
            image: nil,
            content: "committed",
            category: nil,
            captureID: nil,
            expected: nil
        )
        _ = try await fixture.service.beginSettlement(
            captureID: token.captureID,
            expected: token
        )
        try Data("corrupt marker".utf8).write(to: fixture.store.settlementURL)
        let reopened = try fixture.makeService()

        #expect(reopened.pendingSettlementToken() == token)
        try reopened.reconcileCommittedDraft(token)

        guard case .none = reopened.state() else {
            Issue.record("A committed archive must retire the guarded draft")
            return
        }
        #expect(!FileManager.default.fileExists(atPath: fixture.store.settlementURL.path))
    }

    @Test("relaunch keeps a retired tombstone guard-visible and can restore it")
    func relaunchRestoresUncommittedRetirementTombstone() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        let token = try await fixture.service.saveDraft(
            image: nil,
            content: "restore me",
            category: nil,
            captureID: nil,
            expected: nil
        )
        var files = CaptureDraftFileOperations.live
        let liveSync = files.synchronizeDirectory
        var failNextSync = false
        files.synchronizeDirectory = { url in
            if failNextSync {
                failNextSync = false
                throw CocoaError(.fileWriteUnknown)
            }
            try liveSync(url)
        }
        let service = try fixture.makeService(files: files)
        let settlement = try await service.beginSettlement(
            captureID: token.captureID,
            expected: token
        )
        failNextSync = true
        #expect(throws: CaptureDraftServiceError.discardFailed) {
            try service.retireCommittedDraft(settlement)
        }

        let reopened = try fixture.makeService()
        guard case .settlementPending(let pending) = reopened.state() else {
            Issue.record("Marker plus draft tombstone must remain a persistent guard")
            return
        }
        #expect(pending == token)

        try reopened.reconcileUncommittedDraft(token)
        guard case .recoverable(let recovered) = reopened.state() else {
            Issue.record("An absent archive must restore the retired draft before reopening")
            return
        }
        #expect(recovered.token == token)
    }
}
