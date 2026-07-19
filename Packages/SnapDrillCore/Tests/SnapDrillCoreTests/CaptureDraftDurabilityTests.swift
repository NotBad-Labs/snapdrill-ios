import Foundation
import Testing
@testable import SnapDrillCore

@Suite("Capture draft durable control state", .serialized)
struct CaptureDraftDurabilityTests {
    @Test("first publication synchronizes the complete new directory chain")
    func firstPublicationRequiresDurableDirectoryChain() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        var files = CaptureDraftFileOperations.live
        let liveSynchronizeDirectory = files.synchronizeDirectory
        let applicationSupportURL = fixture.applicationSupportURL.standardizedFileURL
        var shouldFailApplicationSupportSync = true
        var synchronizedDirectories: [URL] = []
        files.synchronizeDirectory = { url in
            synchronizedDirectories.append(url.standardizedFileURL)
            if shouldFailApplicationSupportSync,
               url.standardizedFileURL == applicationSupportURL {
                throw CocoaError(.fileWriteUnknown)
            }
            try liveSynchronizeDirectory(url)
        }
        let service = try fixture.makeService(files: files)

        await #expect(throws: CaptureDraftServiceError.publicationOutcomeUncertain) {
            try await service.saveDraft(
                image: nil,
                content: "first publication",
                category: nil,
                captureID: nil,
                expected: nil
            )
        }

        shouldFailApplicationSupportSync = false
        _ = try await service.saveDraft(
            image: nil,
            content: "first publication",
            category: nil,
            captureID: nil,
            expected: nil
        )

        #expect(synchronizedDirectories.contains(applicationSupportURL))
        #expect(
            synchronizedDirectories.contains(
                applicationSupportURL.deletingLastPathComponent()
            )
        )
        guard case .recoverable = service.state() else {
            Issue.record("A retry after full directory synchronization must publish")
            return
        }
    }

    @Test("settlement publishes exact reconciliation evidence across relaunch")
    func settlementEvidenceSurvivesRelaunch() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        let token = try await fixture.service.saveDraft(
            image: nil,
            content: "draft",
            category: nil,
            captureID: nil,
            expected: nil
        )

        _ = try await fixture.service.beginSettlement(
            captureID: token.captureID,
            expected: token
        )

        #expect(try fixture.makeService().pendingSettlementToken() == token)
    }

    @Test("uncertain settlement marker publication requires an exact retry")
    func uncertainSettlementMarkerRequiresExactRetry() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        let token = try await fixture.service.saveDraft(
            image: nil,
            content: "draft",
            category: nil,
            captureID: nil,
            expected: nil
        )
        let service = try fixture.makeService(
            publisher: postRenameSyncFailingOncePublisher()
        )

        await #expect(throws: CaptureDraftServiceError.publicationOutcomeUncertain) {
            try await service.beginSettlement(
                captureID: token.captureID,
                expected: token
            )
        }
        let settlement = try await service.beginSettlement(
            captureID: token.captureID,
            expected: token
        )

        #expect(service.pendingSettlementToken() == token)
        try service.abortSettlement(settlement)
    }

    @Test("abort retries the exact marker retirement after directory sync failure")
    func abortRetriesUncertainMarkerRetirement() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        var files = CaptureDraftFileOperations.live
        let liveSynchronizeDirectory = files.synchronizeDirectory
        var shouldFailSync = false
        files.synchronizeDirectory = { url in
            if shouldFailSync {
                shouldFailSync = false
                throw CocoaError(.fileWriteUnknown)
            }
            try liveSynchronizeDirectory(url)
        }
        let service = try fixture.makeService(files: files)
        let token = try await service.saveDraft(
            image: nil,
            content: "draft",
            category: nil,
            captureID: nil,
            expected: nil
        )
        let settlement = try await service.beginSettlement(
            captureID: token.captureID,
            expected: token
        )

        shouldFailSync = true
        #expect(throws: CaptureDraftServiceError.discardFailed) {
            try service.abortSettlement(settlement)
        }
        try service.abortSettlement(settlement)

        #expect(service.pendingSettlementToken() == nil)
        let replacement = try await service.saveDraft(
            image: nil,
            content: "retry",
            category: nil,
            captureID: token.captureID,
            expected: token
        )
        #expect(replacement.captureID == token.captureID)
    }

    @Test("discard does not report success before the parent directory is synchronized")
    func discardRequiresDurableDirectorySync() async throws {
        let fixture = try CaptureDraftTestFixture()
        defer { fixture.cleanup() }
        let token = try await fixture.service.saveDraft(
            image: nil,
            content: "discard me",
            category: nil,
            captureID: nil,
            expected: nil
        )
        var files = CaptureDraftFileOperations.live
        files.synchronizeDirectory = { _ in
            throw CocoaError(.fileWriteUnknown)
        }
        let service = try fixture.makeService(files: files)

        #expect(throws: CaptureDraftServiceError.discardFailed) {
            try service.discard(.generation(token))
        }
        guard case .none = service.state() else {
            Issue.record("An atomically retired file must not remain visible in-process")
            return
        }
    }
}
