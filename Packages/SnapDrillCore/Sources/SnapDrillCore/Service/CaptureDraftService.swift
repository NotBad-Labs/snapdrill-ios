//
//  CaptureDraftService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Single-authority, generation-safe persistence for interrupted Capture work.
//

import Foundation
import UIKit

public final class CaptureDraftService: CaptureDraftServiceProtocol {
    public typealias Draft = CaptureDraft

    static let lifetime: TimeInterval = 7 * 24 * 60 * 60

    let store: CaptureDraftStore?
    let now: () -> Date
    private let makeUUID: () -> UUID
    var suppressedRevisions: Set<CaptureDraftRevision> = []
    private var closedCaptureIDs: Set<UUID> = []
    var committedCaptureIDs: Set<UUID> = []
    var pendingRetirementTokens: Set<CaptureDraftToken> = []
    private var activeSettlements: [UUID: UUID] = [:]
    private var pendingPublication: PendingPublication?

    /// Production composition entry point.
    public init() {
        do {
            let storage = try AppOwnedStorage()
            store = CaptureDraftStore(storage: storage)
        } catch {
            store = nil
            SnapDrillLogger.capture.error(
                "Capture draft storage unavailable: \(error.localizedDescription)"
            )
        }
        now = Date.init
        makeUUID = UUID.init
    }

    init(
        store: CaptureDraftStore,
        now: @escaping () -> Date = Date.init,
        makeUUID: @escaping () -> UUID = UUID.init
    ) {
        self.store = store
        self.now = now
        self.makeUUID = makeUUID
    }

    @discardableResult
    public func saveDraft(
        image: UIImage?,
        content: String,
        category: String?,
        captureID: UUID?,
        expected: CaptureDraftToken?
    ) async throws -> CaptureDraftToken {
        guard let store else {
            throw CaptureDraftServiceError.storageUnavailable
        }

        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let imageJPEG = try CaptureDraftPayload.makeImageJPEG(image)
        guard !trimmedContent.isEmpty || imageJPEG != nil else {
            throw CaptureDraftServiceError.emptyDraft
        }
        let pendingResolution = try reconcilePendingPublication(
            requestedCaptureID: captureID,
            expected: expected,
            content: content,
            category: category,
            imageJPEG: imageJPEG
        )
        if let completedToken = pendingResolution?.completedToken {
            return completedToken
        }
        let effectiveExpected = pendingResolution?.continuationToken ?? expected
        try prepareNewDraftIfNeeded(expected: effectiveExpected, store: store)
        let resolvedCaptureID = try resolveCaptureID(
            requested: captureID,
            expected: effectiveExpected
        )
        guard !closedCaptureIDs.contains(resolvedCaptureID),
              !committedCaptureIDs.contains(resolvedCaptureID) else {
            throw CaptureDraftServiceError.admissionClosed
        }
        try validateReplacement(expected: effectiveExpected)

        let token = CaptureDraftToken(
            captureID: resolvedCaptureID,
            generationID: makeUUID()
        )
        let stored = StoredCaptureDraft(
            token: token,
            timestamp: now(),
            content: content,
            category: category,
            imageJPEG: imageJPEG
        )
        do {
            try store.publish(stored)
            finishPublishedDraft(token, replacing: effectiveExpected, store: store)
            SnapDrillLogger.capture.info(
                "Capture draft generation committed: \(token.generationID)"
            )
            return token
        } catch CaptureDraftStoreError.publicationOutcomeUncertain {
            pendingPublication = PendingPublication(
                draft: stored,
                expected: effectiveExpected
            )
            throw CaptureDraftServiceError.publicationOutcomeUncertain
        } catch {
            throw CaptureDraftServiceError.persistenceFailed
        }
    }

    public func discard(_ revision: CaptureDraftRevision) throws {
        guard let store else {
            throw CaptureDraftServiceError.storageUnavailable
        }
        do {
            try store.discard(revision)
            suppressedRevisions.remove(revision)
            if case .generation(let token) = revision {
                pendingRetirementTokens.remove(token)
                do {
                    try store.discardSettlementMarker(token)
                } catch {
                    SnapDrillLogger.capture.warning(
                        "Capture settlement marker cleanup deferred: \(error.localizedDescription)"
                    )
                }
            }
            do {
                try store.removeOrphanedSettlementEvidence()
            } catch {
                SnapDrillLogger.capture.warning(
                    "Orphaned Capture settlement cleanup deferred: \(error.localizedDescription)"
                )
            }
        } catch CaptureDraftStoreError.staleRevision {
            throw CaptureDraftServiceError.staleGeneration
        } catch {
            throw CaptureDraftServiceError.discardFailed
        }
    }

    public func beginSettlement(
        captureID: UUID,
        expected: CaptureDraftToken?
    ) async throws -> CaptureDraftSettlement {
        guard activeSettlements[captureID] == nil,
              !closedCaptureIDs.contains(captureID),
              !committedCaptureIDs.contains(captureID) else {
            throw CaptureDraftServiceError.admissionClosed
        }

        try validateSettlementAdmission(captureID: captureID, expected: expected)

        if let expected {
            guard let store else {
                throw CaptureDraftServiceError.storageUnavailable
            }
            do {
                try store.markSettlement(expected)
            } catch CaptureDraftStoreError.publicationOutcomeUncertain {
                throw CaptureDraftServiceError.publicationOutcomeUncertain
            } catch {
                throw CaptureDraftServiceError.persistenceFailed
            }
        }

        let settlementID = makeUUID()
        closedCaptureIDs.insert(captureID)
        activeSettlements[captureID] = settlementID
        return CaptureDraftSettlement(
            captureID: captureID,
            token: expected,
            id: settlementID
        )
    }

    public func abortSettlement(_ settlement: CaptureDraftSettlement) throws {
        guard activeSettlements[settlement.captureID] == settlement.id else {
            throw CaptureDraftServiceError.settlementMismatch
        }
        if let token = settlement.token {
            guard let store else {
                throw CaptureDraftServiceError.storageUnavailable
            }
            do {
                try store.abortSettlement(token)
            } catch {
                // Keep admission closed until the durable abort can be retried.
                throw CaptureDraftServiceError.discardFailed
            }
        }
        activeSettlements[settlement.captureID] = nil
        closedCaptureIDs.remove(settlement.captureID)
    }

    public func retireCommittedDraft(_ settlement: CaptureDraftSettlement) throws {
        guard activeSettlements[settlement.captureID] == settlement.id else {
            throw CaptureDraftServiceError.settlementMismatch
        }

        activeSettlements[settlement.captureID] = nil
        committedCaptureIDs.insert(settlement.captureID)
        if let token = settlement.token {
            pendingRetirementTokens.insert(token)
            let revision = CaptureDraftRevision.generation(token)
            do {
                try discard(revision)
            } catch {
                throw CaptureDraftServiceError.discardFailed
            }
        }
    }

    public func reconcileCommittedDraft(_ token: CaptureDraftToken) throws {
        guard pendingSettlementToken() == token else {
            throw CaptureDraftServiceError.staleGeneration
        }
        let revision = CaptureDraftRevision.generation(token)
        committedCaptureIDs.insert(token.captureID)
        pendingRetirementTokens.insert(token)
        do {
            try discard(revision)
        } catch CaptureDraftServiceError.staleGeneration {
            throw CaptureDraftServiceError.staleGeneration
        } catch {
            throw CaptureDraftServiceError.discardFailed
        }
    }

    public func reconcileUncommittedDraft(_ token: CaptureDraftToken) throws {
        guard pendingSettlementToken() == token, let store else {
            throw CaptureDraftServiceError.staleGeneration
        }
        do {
            try store.abortSettlement(token)
        } catch CaptureDraftStoreError.staleRevision {
            throw CaptureDraftServiceError.staleGeneration
        } catch {
            throw CaptureDraftServiceError.discardFailed
        }
        activeSettlements[token.captureID] = nil
        closedCaptureIDs.remove(token.captureID)
        committedCaptureIDs.remove(token.captureID)
        pendingRetirementTokens.remove(token)
    }
}

private extension CaptureDraftService {
    func prepareNewDraftIfNeeded(
        expected: CaptureDraftToken?,
        store: CaptureDraftStore
    ) throws {
        guard expected == nil else {
            return
        }
        do {
            try store.removeOrphanedSettlementEvidence()
        } catch {
            throw CaptureDraftServiceError.persistenceFailed
        }
    }

    func validateSettlementAdmission(
        captureID: UUID,
        expected: CaptureDraftToken?
    ) throws {
        if let expected {
            try validateExpectedSettlement(captureID: captureID, expected: expected)
        } else {
            try validateNewSettlement()
        }
    }

    func validateExpectedSettlement(
        captureID: UUID,
        expected: CaptureDraftToken
    ) throws {
        guard expected.captureID == captureID else {
            throw CaptureDraftServiceError.staleGeneration
        }
        switch state() {
        case .recoverable(let current) where current.token == expected:
            break
        case .settlementPending(let pending) where pending == expected:
            break
        case .none, .recoverable, .durabilityPending, .settlementPending,
             .committedPendingRetirement, .unrecoverable:
            throw CaptureDraftServiceError.staleGeneration
        }
    }

    func validateNewSettlement() throws {
        switch state() {
        case .none, .committedPendingRetirement:
            break
        case .durabilityPending, .settlementPending:
            throw CaptureDraftServiceError.admissionClosed
        case .recoverable, .unrecoverable:
            throw CaptureDraftServiceError.draftAlreadyExists
        }
    }

    private func resolveCaptureID(
        requested: UUID?,
        expected: CaptureDraftToken?
    ) throws -> UUID {
        guard let expected else {
            return requested ?? makeUUID()
        }
        if let requested, requested != expected.captureID {
            throw CaptureDraftServiceError.staleGeneration
        }
        return expected.captureID
    }

    private func validateReplacement(expected: CaptureDraftToken?) throws {
        if let expected {
            guard case .recoverable(let current) = state(),
                  current.token == expected else {
                throw CaptureDraftServiceError.staleGeneration
            }
        } else {
            switch state() {
            case .none, .committedPendingRetirement:
                // A new logical Capture may replace committed cleanup residue.
                break
            case .durabilityPending, .settlementPending:
                throw CaptureDraftServiceError.admissionClosed
            case .recoverable, .unrecoverable:
                throw CaptureDraftServiceError.draftAlreadyExists
            }
        }
    }

    private func reconcilePendingPublication(
        requestedCaptureID: UUID?,
        expected: CaptureDraftToken?,
        content: String,
        category: String?,
        imageJPEG: Data?
    ) throws -> PendingPublicationResolution? {
        guard let pending = pendingPublication else {
            return nil
        }
        guard let store else {
            throw CaptureDraftServiceError.storageUnavailable
        }

        switch store.state() {
        case .recoverable(let current) where current.token == pending.draft.token:
            try makePendingPublicationDurable(pending, store: store)
            if pending.matches(
                requestedCaptureID: requestedCaptureID,
                expected: expected,
                content: content,
                category: category,
                imageJPEG: imageJPEG
            ) {
                completePendingPublication(pending, store: store)
                return .completed(current.token)
            }
            guard expected == current.token
                    || (
                        expected == pending.expected
                            && requestedCaptureID == current.token.captureID
                    ) else {
                throw CaptureDraftServiceError.staleGeneration
            }
            completePendingPublication(pending, store: store)
            return .continueFrom(current.token)
        case .recoverable(let current) where current.token == pending.expected:
            self.pendingPublication = nil
            return nil
        case .none where pending.expected == nil:
            self.pendingPublication = nil
            return nil
        case .durabilityPending, .unrecoverable:
            throw CaptureDraftServiceError.publicationOutcomeUncertain
        case .none, .recoverable:
            self.pendingPublication = nil
            throw CaptureDraftServiceError.staleGeneration
        }
    }

    private func completePendingPublication(
        _ pending: PendingPublication,
        store: CaptureDraftStore
    ) {
        pendingPublication = nil
        finishPublishedDraft(
            pending.draft.token,
            replacing: pending.expected,
            store: store
        )
    }

    private func makePendingPublicationDurable(
        _ pending: PendingPublication,
        store: CaptureDraftStore
    ) throws {
        do {
            try store.publish(pending.draft)
        } catch CaptureDraftStoreError.publicationOutcomeUncertain {
            throw CaptureDraftServiceError.publicationOutcomeUncertain
        } catch {
            throw CaptureDraftServiceError.persistenceFailed
        }
    }

    private func finishPublishedDraft(
        _ token: CaptureDraftToken,
        replacing expected: CaptureDraftToken?,
        store: CaptureDraftStore
    ) {
        suppressedRevisions.removeAll()
        pendingRetirementTokens.removeAll()
        guard let expected else {
            return
        }
        do {
            try store.discardSettlementMarker(expected)
        } catch {
            SnapDrillLogger.capture.warning(
                "Stale Capture settlement marker cleanup deferred: \(error.localizedDescription)"
            )
        }
        SnapDrillLogger.capture.info(
            "Capture draft generation made durable: \(token.generationID)"
        )
    }

}
