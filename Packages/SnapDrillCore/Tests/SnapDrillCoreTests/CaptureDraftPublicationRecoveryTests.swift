import Foundation
import Testing
@testable import SnapDrillCore

@Suite("Capture draft uncertain publication recovery", .serialized)
struct CaptureDraftPublicationRecoveryTests {
    @Test("changed content advances from a generation installed by an uncertain publish")
    func transientVerificationReadFailureAdvancesChangedContent() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        let old = try await fixture.service.saveDraft(
            image: nil,
            content: "old",
            category: nil,
            captureID: nil,
            expected: nil
        )
        var files = CaptureDraftFileOperations.live
        let liveRead = files.read
        var readCount = 0
        files.read = { url in
            readCount += 1
            if readCount == 2 {
                throw CocoaError(.fileReadUnknown)
            }
            return try liveRead(url)
        }
        let service = try fixture.makeService(files: files)

        await #expect(throws: CaptureDraftServiceError.publicationOutcomeUncertain) {
            try await service.saveDraft(
                image: nil,
                content: "installed but unverified",
                category: nil,
                captureID: old.captureID,
                expected: old
            )
        }
        let latest = try await service.saveDraft(
            image: nil,
            content: "edited after uncertainty",
            category: nil,
            captureID: old.captureID,
            expected: old
        )

        guard case .recoverable(let recovered) = service.state() else {
            Issue.record("The same editor must regain a usable generation token")
            return
        }
        #expect(recovered.token == latest)
        #expect(recovered.content == "edited after uncertainty")
        #expect(latest.captureID == old.captureID)
    }

    @Test("an unrelated capture cannot claim an uncertain installed generation")
    func unrelatedCaptureCannotClaimPendingPublication() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        let old = try await fixture.service.saveDraft(
            image: nil,
            content: "old",
            category: nil,
            captureID: nil,
            expected: nil
        )
        var files = CaptureDraftFileOperations.live
        let liveRead = files.read
        var readCount = 0
        files.read = { url in
            readCount += 1
            if readCount == 2 {
                throw CocoaError(.fileReadUnknown)
            }
            return try liveRead(url)
        }
        let service = try fixture.makeService(files: files)

        await #expect(throws: CaptureDraftServiceError.publicationOutcomeUncertain) {
            try await service.saveDraft(
                image: nil,
                content: "installed but unverified",
                category: nil,
                captureID: old.captureID,
                expected: old
            )
        }
        await #expect(throws: CaptureDraftServiceError.staleGeneration) {
            try await service.saveDraft(
                image: nil,
                content: "unrelated edit",
                category: nil,
                captureID: UUID(),
                expected: old
            )
        }
        let legitimate = try await service.saveDraft(
            image: nil,
            content: "owner edit",
            category: nil,
            captureID: old.captureID,
            expected: old
        )

        guard case .recoverable(let recovered) = service.state() else {
            Issue.record("The original capture must retain ownership")
            return
        }
        #expect(recovered.token == legitimate)
        #expect(recovered.content == "owner edit")
    }
}
