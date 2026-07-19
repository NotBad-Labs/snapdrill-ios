import Foundation
import Testing
@testable import SnapDrillCore

@Suite("Capture draft retirement", .serialized)
struct CaptureDraftRetirementTests {
    @Test("failed committed retirement is guarded but cannot be recovered again")
    func failedCommittedRetirementIsNotRecoverable() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("CaptureDraftRetirement-\(UUID())", isDirectory: true)
        defer {
            if FileManager.default.fileExists(atPath: root.path) {
                do {
                    try FileManager.default.removeItem(at: root)
                } catch {
                    Issue.record("Fixture cleanup failed: \(error)")
                }
            }
        }
        let storage = try AppOwnedStorage(applicationSupportDirectory: root)
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
        let service = CaptureDraftService(
            store: CaptureDraftStore(storage: storage, files: files)
        )
        let token = try await service.saveDraft(
            image: nil,
            content: "committed",
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
            try service.retireCommittedDraft(settlement)
        }

        guard case .committedPendingRetirement(let remaining) = service.state() else {
            Issue.record("A committed draft awaiting cleanup must not be recoverable")
            return
        }
        #expect(remaining == token)
        #expect(service.state().revision == .generation(token))

        let next = try await service.saveDraft(
            image: nil,
            content: "next capture",
            category: nil,
            captureID: nil,
            expected: nil
        )
        #expect(next.captureID != token.captureID)
        guard case .recoverable(let replacement) = service.state() else {
            Issue.record("Committed cleanup residue must not block a new logical Capture")
            return
        }
        #expect(replacement.token == next)
    }
}
