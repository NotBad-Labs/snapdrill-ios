//
//  CaptureDraftServiceMock.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import UIKit

/// In-memory implementation for tests and SwiftUI previews.
public final class CaptureDraftServiceMock: CaptureDraftServiceProtocol {
    public struct SaveCall {
        public let image: UIImage?
        public let content: String
        public let category: String?
        public let expectedToken: CaptureDraftToken?
    }

    public private(set) var state: CaptureDraftReadState
    public private(set) var saveCalls: [SaveCall] = []
    public private(set) var discardCallCount = 0
    public private(set) var settlementPrepareCallCount = 0
    public private(set) var settlementCompleteCallCount = 0
    public private(set) var settlementAbortCallCount = 0
    public private(set) var settlementIsActive = false
    public var saveError: CaptureDraftError?
    public var saveErrorOnCallNumber: Int?
    public var discardError: CaptureDraftError?
    public var settlementPrepareError: CaptureDraftError?
    public var settlementCompleteError: CaptureDraftError?

    public init(initialState: CaptureDraftReadState = .none) {
        state = initialState
    }

    public convenience init(initialDraft: CaptureDraft?) {
        self.init(initialState: initialDraft.map(CaptureDraftReadState.recoverable) ?? .none)
    }

    public func loadDraftState() async -> CaptureDraftReadState {
        state
    }

    public func saveDraft(
        image: UIImage?,
        content: String,
        category: String?,
        expectedToken: CaptureDraftToken?
    ) async throws -> CaptureDraftToken {
        if let saveError,
           saveErrorOnCallNumber == nil || saveErrorOnCallNumber == saveCalls.count + 1 {
            throw saveError
        }
        guard image != nil
                || !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CaptureDraftError.emptyDraft
        }
        guard !settlementIsActive else {
            throw CaptureDraftError.settlementInProgress
        }
        let existing = recoverableDraft
        if let expectedToken {
            guard existing?.token == expectedToken else {
                throw CaptureDraftError.draftChanged
            }
        } else if !isNone {
            throw CaptureDraftError.draftAlreadyExists
        }

        saveCalls.append(
            SaveCall(
                image: image,
                content: content,
                category: category,
                expectedToken: expectedToken
            )
        )
        let token = CaptureDraftToken(
            captureID: expectedToken?.captureID ?? UUID(),
            generationID: UUID(),
            storageRevision: UUID().uuidString
        )
        state = .recoverable(
            CaptureDraft(
                image: image,
                content: content,
                date: Date(),
                category: category,
                token: token
            )
        )
        return token
    }

    public func saveDraftAndBeginSettlement(
        image: UIImage?,
        content: String,
        category: String?,
        expectedToken: CaptureDraftToken?
    ) async throws -> CaptureDraftToken {
        if let settlementPrepareError { throw settlementPrepareError }
        let token = try await saveDraft(
            image: image,
            content: content,
            category: category,
            expectedToken: expectedToken
        )
        settlementPrepareCallCount += 1
        settlementIsActive = true
        return token
    }

    public func discardDraft(expectedToken: CaptureDraftToken) async throws {
        if let discardError { throw discardError }
        guard !settlementIsActive else {
            throw CaptureDraftError.settlementInProgress
        }
        guard recoverableDraft?.token == expectedToken else {
            throw CaptureDraftError.draftChanged
        }
        discardCallCount += 1
        state = .none
    }

    public func discardUnrecoverableDraft(
        expectedToken: CaptureDraftDiscardToken
    ) async throws {
        if let discardError { throw discardError }
        guard !settlementIsActive else {
            throw CaptureDraftError.settlementInProgress
        }
        guard case .unrecoverable(let failure) = state,
              failure.discardToken == expectedToken else {
            throw CaptureDraftError.draftChanged
        }
        discardCallCount += 1
        state = .none
    }

    public func beginSettlement(expectedToken: CaptureDraftToken) async throws {
        if let settlementPrepareError { throw settlementPrepareError }
        guard !settlementIsActive else {
            throw CaptureDraftError.settlementInProgress
        }
        guard recoverableDraft?.token == expectedToken else {
            throw CaptureDraftError.draftChanged
        }
        settlementPrepareCallCount += 1
        settlementIsActive = true
    }

    public func completeSettlement(expectedToken: CaptureDraftToken) async throws {
        if let settlementCompleteError { throw settlementCompleteError }
        guard settlementIsActive, recoverableDraft?.token == expectedToken else {
            throw CaptureDraftError.draftChanged
        }
        settlementCompleteCallCount += 1
        settlementIsActive = false
        discardCallCount += 1
        state = .none
    }

    public func abortSettlement(expectedToken: CaptureDraftToken) async {
        guard recoverableDraft?.token == expectedToken else { return }
        settlementAbortCallCount += 1
        settlementIsActive = false
    }

    public func setState(_ state: CaptureDraftReadState) {
        self.state = state
        settlementIsActive = false
    }

    public func seedDraft(
        image: UIImage? = nil,
        content: String,
        category: String? = nil,
        date: Date = Date()
    ) {
        let token = CaptureDraftToken(
            captureID: UUID(),
            generationID: UUID(),
            storageRevision: UUID().uuidString
        )
        state = .recoverable(
            CaptureDraft(
                image: image,
                content: content,
                date: date,
                category: category,
                token: token
            )
        )
        settlementIsActive = false
    }

    private var recoverableDraft: CaptureDraft? {
        guard case .recoverable(let draft) = state else { return nil }
        return draft
    }

    private var isNone: Bool {
        if case .none = state { return true }
        return false
    }
}
