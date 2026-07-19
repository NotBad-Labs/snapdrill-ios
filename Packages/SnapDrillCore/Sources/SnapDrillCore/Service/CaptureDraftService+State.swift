//
//  CaptureDraftService+State.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation

extension CaptureDraftService {
    public func state() -> CaptureDraftState {
        guard let store else {
            return .none
        }
        let storedState = store.state()
        if let guardState = persistentGuardState(
            storedState: storedState,
            store: store
        ) {
            return guardState
        }
        if let revision = storedState.revision,
           suppressedRevisions.contains(revision) {
            return .none
        }
        if case .none = storedState,
           let token = pendingRetirementTokens.first,
           store.pendingRetiredDraftRevision() == .generation(token) {
            return .committedPendingRetirement(token)
        }
        return resolvedState(storedState, store: store)
    }

    public func pendingSettlementToken() -> CaptureDraftToken? {
        if let store {
            let storedState = store.state()
            switch store.settlementGuard(
                currentRevision: storedState.revision
            ) {
            case .pending(let token):
                return token
            case .unresolved(.generation(let token)):
                // Reconcile unreadable control bytes against this exact generation.
                return token
            case .none, .unresolved(.corruptFingerprint):
                break
            }
        }
        guard let store,
              let token = pendingRetirementTokens.first,
              store.pendingRetiredDraftRevision() == .generation(token) else {
            return nil
        }
        return token
    }
}

private extension CaptureDraftService {
    func persistentGuardState(
        storedState: CaptureDraftStoreState,
        store: CaptureDraftStore
    ) -> CaptureDraftState? {
        switch store.settlementGuard(currentRevision: storedState.revision) {
        case .none:
            return nil
        case .unresolved(let revision):
            if case .unrecoverable(let failure) = storedState {
                return .unrecoverable(failure)
            }
            return .durabilityPending(revision)
        case .pending(let token):
            if pendingRetirementTokens.contains(token)
                || committedCaptureIDs.contains(token.captureID) {
                return .committedPendingRetirement(token)
            }
            return .settlementPending(token)
        }
    }

    func resolvedState(
        _ storedState: CaptureDraftStoreState,
        store: CaptureDraftStore
    ) -> CaptureDraftState {
        switch storedState {
        case .none:
            return .none
        case .durabilityPending(let revision):
            return .durabilityPending(revision)
        case .unrecoverable(let failure):
            return .unrecoverable(failure)
        case .recoverable(let stored):
            if pendingRetirementTokens.contains(stored.token) {
                return .committedPendingRetirement(stored.token)
            }
            guard now() < stored.timestamp.addingTimeInterval(Self.lifetime) else {
                retireExpiredDraft(stored, store: store)
                return .none
            }
            return .recoverable(CaptureDraftPayload.makeDraft(from: stored))
        }
    }

    func retireExpiredDraft(
        _ stored: StoredCaptureDraft,
        store: CaptureDraftStore
    ) {
        let revision = CaptureDraftRevision.generation(stored.token)
        do {
            try store.discard(revision)
        } catch {
            suppressedRevisions.insert(revision)
            SnapDrillLogger.capture.warning(
                "Expired Capture draft retirement failed: \(error.localizedDescription)"
            )
        }
    }
}
