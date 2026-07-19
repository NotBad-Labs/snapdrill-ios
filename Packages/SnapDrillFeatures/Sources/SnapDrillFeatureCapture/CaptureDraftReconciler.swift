//
//  CaptureDraftReconciler.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import SnapDrillCore
import SnapDrillData

public nonisolated enum CaptureDraftReconciliationResult: Equatable, Sendable {
    case noPendingSettlement
    case committed(CaptureDraftToken)
    case reopened(CaptureDraftToken)
    case deferred(CaptureDraftToken)
}

/// Closes the archive-commit/draft-retire crash window before recovery UI appears.
@MainActor
public enum CaptureDraftReconciler {
    @discardableResult
    public static func reconcile(
        draftService: CaptureDraftServiceProtocol,
        repositories: RepositoryContainer,
        archiveLookup: ((UUID) throws -> Bool)? = nil
    ) -> CaptureDraftReconciliationResult {
        guard let token = draftService.pendingSettlementToken() else {
            return .noPendingSettlement
        }
        let archiveCommitted: Bool
        do {
            if let archiveLookup {
                archiveCommitted = try archiveLookup(token.captureID)
            } else {
                archiveCommitted = try repositories.archive.fetchModel(by: token.captureID) != nil
            }
        } catch {
            // Query failure is fail-closed: retain the exact settlement evidence
            // instead of inferring either commit or absence.
            SnapDrillLogger.capture.error(
                "Capture draft reconciliation query failed: \(error.localizedDescription)"
            )
            return .deferred(token)
        }

        do {
            if archiveCommitted {
                try draftService.reconcileCommittedDraft(token)
                return .committed(token)
            } else {
                try draftService.reconcileUncommittedDraft(token)
                return .reopened(token)
            }
        } catch {
            // Settlement evidence remains guard-visible and recovery stays
            // closed until the exact reconciliation operation can finish.
            SnapDrillLogger.capture.warning(
                "Capture draft reconciliation cleanup deferred: \(error.localizedDescription)"
            )
            return .deferred(token)
        }
    }
}
