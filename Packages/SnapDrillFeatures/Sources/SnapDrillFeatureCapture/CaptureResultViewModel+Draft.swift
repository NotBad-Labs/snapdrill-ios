//
//  CaptureResultViewModel+Draft.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import SnapDrillCore
import SnapDrillData

extension CaptureResultViewModel {
    /// Saves initial editor input before it depends on a view-disappearance callback.
    public func generateDraftIfNeeded() async {
        guard draftToken == nil else { return }
        do {
            _ = try await checkpointDraftIfNeeded()
        } catch {
            presentDraftPersistenceFailure(
                "Capture draft checkpoint failed",
                error: error
            )
        }
    }

    /// Coalesces frequent edits into a recent crash-recoverable snapshot.
    public func scheduleDraftCheckpoint() {
        guard !isSaved, !isSaving else { return }
        draftAutosaveTask?.cancel()
        draftAutosaveTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(250))
                try Task.checkCancellation()
                _ = try await checkpointDraftIfNeeded()
            } catch is CancellationError {
                return
            } catch {
                presentDraftPersistenceFailure(
                    "Capture draft autosave failed",
                    error: error
                )
            }
        }
    }

    /// Immediately checkpoints the final visible state when the editor exits.
    public func saveDraftOnDisappear() {
        draftAutosaveTask?.cancel()
        draftAutosaveTask = nil
        draftSaveTask = Task {
            do {
                _ = try await checkpointDraftIfNeeded()
            } catch {
                presentDraftPersistenceFailure(
                    "Capture exit checkpoint failed",
                    error: error
                )
            }
        }
    }

    func reconcilePendingSettlementBeforeSave() throws -> Bool {
        guard let pending = draftService.pendingSettlementToken() else {
            return false
        }
        guard pending.captureID == captureID, pending == draftToken else {
            throw CaptureDraftServiceError.admissionClosed
        }
        switch CaptureDraftReconciler.reconcile(
            draftService: draftService,
            repositories: repositories
        ) {
        case .noPendingSettlement:
            return false
        case .committed(let token) where token == pending:
            handleSaveSuccess()
            return true
        case .reopened(let token) where token == pending:
            return false
        case .deferred, .committed, .reopened:
            throw CaptureDraftServiceError.persistenceFailed
        }
    }

    func checkpointDraftIfNeeded() async throws -> CaptureDraftToken? {
        guard !isSaved else {
            return draftToken
        }
        let hasContent = !content.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        guard image != nil || hasContent else {
            return draftToken
        }

        let categoryName = selectedName(forSystemKey: CategorySystemKey.category)
        let committed = try await draftService.saveDraft(
            image: image,
            content: content,
            category: categoryName.isEmpty ? nil : categoryName,
            captureID: captureID,
            expected: draftToken
        )
        draftToken = committed
        return committed
    }

    func selectedName(forSystemKey key: String) -> String {
        guard let dimension = dimensions.first(where: { $0.systemKey == key }),
              let valueID = selectedByDimension[dimension.id]?.first,
              let value = (valuesByDimension[dimension.id] ?? []).first(
                  where: { $0.id == valueID }
              ) else {
            return ""
        }
        return value.name
    }

    private func presentDraftPersistenceFailure(
        _ context: String,
        error: Error
    ) {
        SnapDrillLogger.capture.error(
            "\(context): \(error.localizedDescription)"
        )
        guard !isSaved else {
            return
        }
        errorMessage = L10n.Errors.tryAgainLater
        showErrorAlert = true
    }
}
