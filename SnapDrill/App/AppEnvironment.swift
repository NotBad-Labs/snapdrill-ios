import Foundation
import Observation
import SwiftData
import UIKit

/// Global application coordinator holding shared services, 5-second undo deletion queue,
/// draft recovery state, and subtle save feedback banners.
@Observable
@MainActor
final class AppEnvironment {
    let preferences: AppPreferencesStore
    let proStore: ProEntitlementStore
    let imageStore: MistakeImageStore
    let capturePipeline: CapturePipelineServing
    let cameraAccess: CameraAccessChecking
    let draftStore: CaptureDraftPersisting
    let saveService: LibrarySaveService
    let pdfService: PDFExportServing

    /// Soft-deleted mistake IDs hidden immediately from UI while awaiting permanent purge after 5s (AC-05).
    private(set) var pendingDeletionIDs: Set<UUID> = []
    private(set) var undoBannerCount: Int = 0
    private var stagedUndoItems: [(id: UUID, context: ModelContext)] = []
    private var undoPurgeTask: Task<Void, Never>?

    /// Gentle post-save toast banner ("Saved! Practice again soon").
    private(set) var savedToastQuestionCount: Int?
    private var toastClearTask: Task<Void, Never>?

    /// Unfinished CaptureSession recovered from disk after an abrupt termination (PRD §8.6, AC-09).
    var recoverableDraft: CaptureSession?

    init(
        preferences: AppPreferencesStore? = nil,
        proStore: ProEntitlementStore? = nil,
        imageStore: MistakeImageStore = MistakeImageStore(),
        capturePipeline: CapturePipelineServing = CapturePipelineFactory.makeLivePipeline(),
        cameraAccess: CameraAccessChecking = CapturePipelineFactory.makeCameraAccessChecker(),
        draftStore: CaptureDraftPersisting = CapturePipelineFactory.makeDraftStore(),
        pdfService: PDFExportServing = PDFExportService()
    ) {
        self.preferences = preferences ?? AppPreferencesStore()
        self.proStore = proStore ?? ProEntitlementStore()
        self.imageStore = imageStore
        self.capturePipeline = capturePipeline
        self.cameraAccess = cameraAccess
        self.draftStore = draftStore
        self.saveService = LibrarySaveService(imageStore: imageStore)
        self.pdfService = pdfService
    }

    // MARK: - 5-Second Undo Delete (PRD §8.3, AC-05)

    func scheduleSoftDelete(_ items: [MistakeItem], in context: ModelContext) {
        guard !items.isEmpty else { return }

        // Commit any older pending deletions immediately before starting a fresh 5-second window
        commitPendingDeletions()

        for item in items {
            pendingDeletionIDs.insert(item.id)
            stagedUndoItems.append((item.id, context))
        }
        undoBannerCount = stagedUndoItems.count

        undoPurgeTask?.cancel()
        undoPurgeTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled, let self else { return }
            self.commitPendingDeletions()
        }
    }

    func undoLastDeletion() {
        undoPurgeTask?.cancel()
        undoPurgeTask = nil
        for entry in stagedUndoItems {
            pendingDeletionIDs.remove(entry.id)
        }
        stagedUndoItems.removeAll()
        undoBannerCount = 0
    }

    func commitPendingDeletions() {
        undoPurgeTask?.cancel()
        undoPurgeTask = nil

        let itemsToDelete = stagedUndoItems
        stagedUndoItems.removeAll()
        undoBannerCount = 0

        for entry in itemsToDelete {
            pendingDeletionIDs.remove(entry.id)
            let targetID = entry.id
            let descriptor = FetchDescriptor<MistakeItem>(predicate: #Predicate { $0.id == targetID })
            if let match = try? entry.context.fetch(descriptor).first {
                try? saveService.permanentlyDeleteMistake(match, in: entry.context)
            }
        }
    }

    // MARK: - Save Toast & Draft Recovery

    func showSavedConfirmation(count: Int) {
        savedToastQuestionCount = count
        toastClearTask?.cancel()
        toastClearTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.8))
            guard !Task.isCancelled, let self else { return }
            self.savedToastQuestionCount = nil
        }
    }

    func checkForRecoverableDraft() async {
        recoverableDraft = await draftStore.loadDraft()
    }

    func discardRecoverableDraft() async {
        recoverableDraft = nil
        await draftStore.clearDraft()
    }
}
