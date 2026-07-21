//
//  CaptureDraftServiceProtocol.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import UIKit

/// Identifies one committed draft generation. Callers must return the latest token to mutate it.
public nonisolated struct CaptureDraftToken: Hashable, Sendable {
    public let captureID: UUID
    public let generationID: UUID
    let storageRevision: String

}

/// Opaque compare-and-delete token for an unreadable draft artifact.
public nonisolated struct CaptureDraftDiscardToken: Hashable, Sendable {
    let storageObservation: String

}

/// A complete, recoverable capture draft.
public struct CaptureDraft {
    public let image: UIImage?
    public let content: String
    public let date: Date
    public let category: String?
    public let token: CaptureDraftToken

    public init(
        image: UIImage?,
        content: String,
        date: Date,
        category: String?,
        token: CaptureDraftToken
    ) {
        self.image = image
        self.content = content
        self.date = date
        self.category = category
        self.token = token
    }
}

public nonisolated enum CaptureDraftFailureReason: Equatable, Sendable {
    case unsupportedVersion
    case malformedEnvelope
    case integrityCheckFailed
    case emptyDraft
    case imageDecodeFailed
    case storageUnavailable
}

/// A persisted artifact exists, but it cannot safely be restored as a draft.
public nonisolated struct CaptureDraftFailure: Equatable, Sendable {
    public let reason: CaptureDraftFailureReason
    public let discardToken: CaptureDraftDiscardToken?

}

/// Distinguishes a clean absence from recoverable and fail-closed corrupt states.
public enum CaptureDraftReadState {
    case none
    case recoverable(CaptureDraft)
    case unrecoverable(CaptureDraftFailure)
}

public nonisolated enum CaptureDraftError: Error, Equatable, Sendable {
    case draftAlreadyExists
    case draftChanged
    case draftMissing
    case settlementInProgress
    case emptyDraft
    case imageEncodingFailed
    case envelopeTooLarge
    case storageFailure
}

/// Manages the single Profile-free capture draft under `AS/Drafts`.
public protocol CaptureDraftServiceProtocol: AnyObject {
    /// Reads the current state without collapsing corrupt or unreadable storage into `none`.
    func loadDraftState() async -> CaptureDraftReadState

    /// Publishes one complete old-or-new draft generation.
    ///
    /// `expectedToken == nil` creates only when no artifact exists. Updates must return the latest
    /// token, preventing late OCR or `onDisappear` work from overwriting a newer generation.
    func saveDraft(
        image: UIImage?,
        content: String,
        category: String?,
        expectedToken: CaptureDraftToken?
    ) async throws -> CaptureDraftToken

    /// Publishes the final draft generation and atomically closes write admission.
    func saveDraftAndBeginSettlement(
        image: UIImage?,
        content: String,
        category: String?,
        expectedToken: CaptureDraftToken?
    ) async throws -> CaptureDraftToken

    /// Explicitly discards the exact recoverable generation the user saw.
    func discardDraft(expectedToken: CaptureDraftToken) async throws

    /// Explicitly discards an unreadable artifact only if its observed node is unchanged.
    func discardUnrecoverableDraft(expectedToken: CaptureDraftDiscardToken) async throws

    /// Closes draft-write admission for a generation that is already durable.
    func beginSettlement(expectedToken: CaptureDraftToken) async throws

    /// Retires the exact settled generation after the formal item transaction commits.
    ///
    /// The formal item ID must equal `expectedToken.captureID`. If the process exits after the
    /// database commit but before this call completes, launch-time reconciliation must detect that
    /// committed ID and explicitly discard the matching draft generation.
    func completeSettlement(expectedToken: CaptureDraftToken) async throws

    /// Reopens draft-write admission after the formal item transaction fails.
    func abortSettlement(expectedToken: CaptureDraftToken) async
}
