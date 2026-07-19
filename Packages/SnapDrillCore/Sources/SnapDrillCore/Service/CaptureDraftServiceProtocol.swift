//
//  CaptureDraftServiceProtocol.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Typed, generation-safe contract for the single recoverable Capture draft.
//

import Foundation
import UIKit

/// Identifies one immutable committed generation of a logical Capture.
public nonisolated struct CaptureDraftToken: Hashable, Sendable {
    public let captureID: UUID
    public let generationID: UUID

    public init(captureID: UUID, generationID: UUID) {
        self.captureID = captureID
        self.generationID = generationID
    }
}

/// Conditional mutation token for either a valid generation or corrupt bytes.
public nonisolated enum CaptureDraftRevision: Hashable, Sendable {
    case generation(CaptureDraftToken)
    case corruptFingerprint(String)
}

/// Validation failure that prevents draft recovery.
public nonisolated enum CaptureDraftCorruptionReason: Equatable, Sendable {
    case unreadable
    case malformedEnvelope
    case unsupportedSchema
    case lengthMismatch
    case digestMismatch
    case invalidImage
    case emptyPayload
}

/// A committed draft file exists, but cannot safely enter the editor.
public nonisolated struct CaptureDraftUnrecoverable: Equatable, Sendable {
    public let reason: CaptureDraftCorruptionReason
    public let revision: CaptureDraftRevision

    public init(
        reason: CaptureDraftCorruptionReason,
        revision: CaptureDraftRevision
    ) {
        self.reason = reason
        self.revision = revision
    }
}

/// One validated, recoverable Capture generation.
public struct CaptureDraft {
    public let token: CaptureDraftToken
    public let image: UIImage?
    public let content: String
    public let date: Date
    public let category: String?

    public init(
        image: UIImage?,
        content: String,
        date: Date,
        category: String?,
        token: CaptureDraftToken = CaptureDraftToken(
            captureID: UUID(),
            generationID: UUID()
        )
    ) {
        self.token = token
        self.image = image
        self.content = content
        self.date = date
        self.category = category
    }
}

/// The only authority for whether Capture recovery is available.
public enum CaptureDraftState {
    case none
    case recoverable(CaptureDraft)
    /// Valid draft bytes exist, but durable publication or settlement control
    /// evidence is unresolved. Recovery stays hidden until it can be proven.
    case durabilityPending(CaptureDraftRevision)
    /// Durable settlement evidence exists, but archive commit outcome has not
    /// yet been reconciled. Recovery and new writes remain closed.
    case settlementPending(CaptureDraftToken)
    /// The archive committed, so this generation is safety state only and must
    /// never be offered as editable recovery while physical deletion retries.
    case committedPendingRetirement(CaptureDraftToken)
    case unrecoverable(CaptureDraftUnrecoverable)

    public var revision: CaptureDraftRevision? {
        switch self {
        case .none:
            nil
        case .recoverable(let draft):
            .generation(draft.token)
        case .durabilityPending(let revision):
            revision
        case .settlementPending(let token):
            .generation(token)
        case .committedPendingRetirement(let token):
            .generation(token)
        case .unrecoverable(let failure):
            failure.revision
        }
    }
}

/// Capability returned after draft writes for a capture have been fenced.
public nonisolated struct CaptureDraftSettlement: Sendable {
    public let captureID: UUID
    public let token: CaptureDraftToken?
    let id: UUID
}

public nonisolated enum CaptureDraftServiceError: Error, Equatable, Sendable {
    case storageUnavailable
    case emptyDraft
    case imageEncodingFailed
    case draftAlreadyExists
    case staleGeneration
    case admissionClosed
    case settlementMismatch
    case persistenceFailed
    case publicationOutcomeUncertain
    case discardFailed
}

/// Generation-safe draft persistence shared by Capture, Dashboard and Settings.
public protocol CaptureDraftServiceProtocol {
    /// Reads and validates the single committed generation.
    func state() -> CaptureDraftState

    /// Returns the exact generation that must be reconciled before recovery.
    ///
    /// A readable marker supplies the token directly. If marker bytes are
    /// unreadable, the current generation is returned only while those control
    /// bytes remain present, so archive lookup can safely choose retire or reopen.
    /// Capture identity without settlement control evidence is never sufficient.
    func pendingSettlementToken() -> CaptureDraftToken?

    /// Publishes one complete replacement generation.
    ///
    /// `expected` performs compare-and-swap enrichment. A nil expectation starts
    /// a new logical capture and therefore cannot replace an unrelated draft.
    @discardableResult
    func saveDraft(
        image: UIImage?,
        content: String,
        category: String?,
        captureID: UUID?,
        expected: CaptureDraftToken?
    ) async throws -> CaptureDraftToken

    /// Removes only the exact generation or corrupt byte fingerprint supplied.
    func discard(_ revision: CaptureDraftRevision) throws

    /// Closes write admission for `captureID` before formal archive persistence.
    func beginSettlement(
        captureID: UUID,
        expected: CaptureDraftToken?
    ) async throws -> CaptureDraftSettlement

    /// Durably removes settlement evidence, then reopens write admission.
    func abortSettlement(_ settlement: CaptureDraftSettlement) throws

    /// Retires the exact settled generation after the archive commit succeeds.
    func retireCommittedDraft(_ settlement: CaptureDraftSettlement) throws

    /// Boot-time commit/retire reconciliation for a known archived capture.
    func reconcileCommittedDraft(_ token: CaptureDraftToken) throws

    /// Boot-time reconciliation when the archive did not commit.
    ///
    /// Settlement evidence must be retired durably before recovery reopens.
    func reconcileUncommittedDraft(_ token: CaptureDraftToken) throws
}
