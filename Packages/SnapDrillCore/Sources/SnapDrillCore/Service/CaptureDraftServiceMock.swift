//
//  CaptureDraftServiceMock.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import UIKit

/// In-memory generation-safe Capture draft service for tests and previews.
public final class CaptureDraftServiceMock: CaptureDraftServiceProtocol {
    public private(set) var storedDraft: CaptureDraft?
    public private(set) var unrecoverableDraft: CaptureDraftUnrecoverable?
    public private(set) var committedPendingRetirementToken: CaptureDraftToken?
    public private(set) var settlementEvidenceToken: CaptureDraftToken?
    public private(set) var saveCalls: [SaveCall] = []
    public private(set) var clearCallCount = 0
    public var saveError: CaptureDraftServiceError?
    public var beginSettlementError: CaptureDraftServiceError?
    public var discardError: CaptureDraftServiceError?

    private var activeSettlements: [UUID: UUID] = [:]
    private var closedCaptureIDs: Set<UUID> = []

    public struct SaveCall {
        public let image: UIImage?
        public let content: String
        public let category: String?
        public let captureID: UUID?
        public let expected: CaptureDraftToken?
    }

    public init(
        initialDraft: CaptureDraft? = nil,
        pendingSettlementToken: CaptureDraftToken? = nil
    ) {
        storedDraft = initialDraft
        settlementEvidenceToken = pendingSettlementToken
    }

    public var hasDraft: Bool {
        if case .none = state() {
            return false
        }
        return true
    }

    public func state() -> CaptureDraftState {
        if let unrecoverableDraft {
            return .unrecoverable(unrecoverableDraft)
        }
        if let storedDraft {
            if committedPendingRetirementToken == storedDraft.token {
                return .committedPendingRetirement(storedDraft.token)
            }
            if settlementEvidenceToken == storedDraft.token {
                return .settlementPending(storedDraft.token)
            }
            return .recoverable(storedDraft)
        }
        return .none
    }

    public func pendingSettlementToken() -> CaptureDraftToken? {
        if let committedPendingRetirementToken {
            return committedPendingRetirementToken
        }
        guard settlementEvidenceToken == storedDraft?.token else {
            return nil
        }
        return settlementEvidenceToken
    }

    @discardableResult
    public func saveDraft(
        image: UIImage?,
        content: String,
        category: String?,
        captureID: UUID?,
        expected: CaptureDraftToken?
    ) async throws -> CaptureDraftToken {
        saveCalls.append(
            SaveCall(
                image: image,
                content: content,
                category: category,
                captureID: captureID,
                expected: expected
            )
        )
        if let saveError {
            throw saveError
        }

        let resolvedCaptureID = expected?.captureID ?? captureID ?? UUID()
        guard !closedCaptureIDs.contains(resolvedCaptureID) else {
            throw CaptureDraftServiceError.admissionClosed
        }
        if let expected, storedDraft?.token != expected {
            throw CaptureDraftServiceError.staleGeneration
        }
        if expected == nil {
            switch state() {
            case .none, .committedPendingRetirement:
                break
            case .durabilityPending, .settlementPending:
                throw CaptureDraftServiceError.admissionClosed
            case .recoverable, .unrecoverable:
                throw CaptureDraftServiceError.draftAlreadyExists
            }
        }
        guard image != nil || !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CaptureDraftServiceError.emptyDraft
        }

        let token = CaptureDraftToken(
            captureID: resolvedCaptureID,
            generationID: UUID()
        )
        storedDraft = CaptureDraft(
            image: image,
            content: content,
            date: Date(),
            category: category,
            token: token
        )
        unrecoverableDraft = nil
        committedPendingRetirementToken = nil
        if settlementEvidenceToken == expected {
            settlementEvidenceToken = nil
        }
        return token
    }

    public func discard(_ revision: CaptureDraftRevision) throws {
        if let discardError {
            throw discardError
        }
        guard state().revision == revision else {
            throw CaptureDraftServiceError.staleGeneration
        }
        clearCallCount += 1
        storedDraft = nil
        unrecoverableDraft = nil
        if case .generation(let token) = revision {
            if committedPendingRetirementToken == token {
                committedPendingRetirementToken = nil
            }
            if settlementEvidenceToken == token {
                settlementEvidenceToken = nil
            }
        }
    }

    public func beginSettlement(
        captureID: UUID,
        expected: CaptureDraftToken?
    ) async throws -> CaptureDraftSettlement {
        guard !closedCaptureIDs.contains(captureID) else {
            throw CaptureDraftServiceError.admissionClosed
        }
        if let beginSettlementError {
            if beginSettlementError == .publicationOutcomeUncertain {
                settlementEvidenceToken = expected
            }
            throw beginSettlementError
        }
        if let expected {
            guard expected.captureID == captureID,
                  storedDraft?.token == expected else {
                throw CaptureDraftServiceError.staleGeneration
            }
        } else {
            switch state() {
            case .none, .committedPendingRetirement:
                break
            case .durabilityPending, .settlementPending:
                throw CaptureDraftServiceError.admissionClosed
            case .recoverable, .unrecoverable:
                throw CaptureDraftServiceError.draftAlreadyExists
            }
        }
        settlementEvidenceToken = expected
        let settlementID = UUID()
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
        if let discardError {
            throw discardError
        }
        if settlementEvidenceToken == settlement.token {
            settlementEvidenceToken = nil
        }
        activeSettlements[settlement.captureID] = nil
        closedCaptureIDs.remove(settlement.captureID)
    }

    public func retireCommittedDraft(_ settlement: CaptureDraftSettlement) throws {
        guard activeSettlements[settlement.captureID] == settlement.id else {
            throw CaptureDraftServiceError.settlementMismatch
        }
        activeSettlements[settlement.captureID] = nil
        if let token = settlement.token {
            committedPendingRetirementToken = token
            try discard(.generation(token))
        }
    }

    public func reconcileCommittedDraft(_ token: CaptureDraftToken) throws {
        guard pendingSettlementToken() == token else {
            throw CaptureDraftServiceError.staleGeneration
        }
        closedCaptureIDs.insert(token.captureID)
        committedPendingRetirementToken = token
        try discard(.generation(token))
    }

    public func reconcileUncommittedDraft(_ token: CaptureDraftToken) throws {
        guard pendingSettlementToken() == token else {
            throw CaptureDraftServiceError.staleGeneration
        }
        if let discardError {
            throw discardError
        }
        settlementEvidenceToken = nil
        committedPendingRetirementToken = nil
        activeSettlements[token.captureID] = nil
        closedCaptureIDs.remove(token.captureID)
    }

    // MARK: - Compatibility helpers for focused pre-contract tests

    public func loadDraft() -> CaptureDraft? {
        storedDraft
    }

    public func clearDraft() {
        clearCallCount += 1
        storedDraft = nil
        unrecoverableDraft = nil
        committedPendingRetirementToken = nil
        settlementEvidenceToken = nil
    }

    public func saveDraft(
        image: UIImage?,
        content: String,
        category: String?
    ) async {
        do {
            _ = try await saveDraft(
                image: image,
                content: content,
                category: category,
                captureID: storedDraft?.token.captureID,
                expected: storedDraft?.token
            )
        } catch {
            // Compatibility calls intentionally expose state through `saveError`.
        }
    }

    public func setDraftToLoad(_ draft: CaptureDraft?) {
        storedDraft = draft
        unrecoverableDraft = nil
        committedPendingRetirementToken = nil
        settlementEvidenceToken = nil
    }

    public func setUnrecoverable(_ failure: CaptureDraftUnrecoverable?) {
        unrecoverableDraft = failure
        if failure != nil {
            storedDraft = nil
            committedPendingRetirementToken = nil
            settlementEvidenceToken = nil
        }
    }
}
