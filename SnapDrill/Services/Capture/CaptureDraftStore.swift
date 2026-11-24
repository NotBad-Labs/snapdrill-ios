import Foundation

/// Persists unfinished Step 1/2/3 capture sessions to Application Support so killing the app never loses cropped drafts (PRD §8.6, AC-09).
actor CaptureDraftStore: CaptureDraftPersisting {
    private let draftFileURL: URL

    init(directoryURL: URL? = nil) {
        let baseDir = directoryURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("SnapDrillDrafts", isDirectory: true)
        self.draftFileURL = baseDir.appendingPathComponent("pending_capture_draft.json")
    }

    func saveDraft(_ session: CaptureSession) async throws {
        guard !session.pages.isEmpty else {
            await clearDraft()
            return
        }
        let dir = draftFileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(session)
        try data.write(to: draftFileURL, options: [.atomic])
    }

    func loadDraft() async -> CaptureSession? {
        guard FileManager.default.fileExists(atPath: draftFileURL.path),
              let data = try? Data(contentsOf: draftFileURL),
              let session = try? JSONDecoder().decode(CaptureSession.self, from: data),
              !session.pages.isEmpty else {
            return nil
        }
        return session
    }

    func clearDraft() async {
        if FileManager.default.fileExists(atPath: draftFileURL.path) {
            try? FileManager.default.removeItem(at: draftFileURL)
        }
    }
}
