//
//  CapturePageDraftSession.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import SnapDrillCore
import UIKit

@MainActor
final class CapturePageDraftSession {
    var token: CaptureDraftToken?

    func synchronize(with state: CaptureDraftState) {
        guard let token else {
            return
        }
        switch state {
        case .none:
            self.token = nil
        case .recoverable(let draft) where draft.token.captureID == token.captureID:
            self.token = draft.token
        case .committedPendingRetirement(let pendingToken)
            where pendingToken.captureID == token.captureID:
            self.token = nil
        case .recoverable, .durabilityPending, .settlementPending,
             .committedPendingRetirement, .unrecoverable:
            break
        }
    }

    func saveCheckpoint(
        image: UIImage,
        using draftService: CaptureDraftServiceProtocol
    ) async throws -> CaptureDraftToken {
        synchronize(with: draftService.state())
        let expected = token

        do {
            return try await commitCheckpoint(
                image: image,
                expected: expected,
                using: draftService
            )
        } catch CaptureDraftServiceError.staleGeneration {
            synchronize(with: draftService.state())
            guard let expected,
                  let refreshed = token,
                  refreshed.captureID == expected.captureID,
                  refreshed != expected else {
                throw CaptureDraftServiceError.staleGeneration
            }
            return try await commitCheckpoint(
                image: image,
                expected: refreshed,
                using: draftService
            )
        }
    }

    private func commitCheckpoint(
        image: UIImage,
        expected: CaptureDraftToken?,
        using draftService: CaptureDraftServiceProtocol
    ) async throws -> CaptureDraftToken {
        let committed = try await draftService.saveDraft(
            image: image,
            content: "",
            category: nil,
            captureID: expected?.captureID,
            expected: expected
        )
        token = committed
        return committed
    }
}
