//
//  CaptureDraftChannelSafetyTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import Testing
import UIKit
@testable import SnapDrillCore
@testable import SnapDrillFeatureCapture

@Suite("Capture page-picker draft safety")
@MainActor
struct CaptureDraftChannelSafetyTests {

    @Test("PDF checkpoint failure blocks OCR and editor navigation")
    func pdfCheckpointFailureBlocksOCRAndNavigation() async {
        let draftService = CaptureDraftServiceMock()
        draftService.saveError = .persistenceFailed
        let ocrService = MockOCRService()
        let router = CaptureRouter()
        var pushed = false
        router.onPush = { _ in pushed = true }
        let view = PDFPagePickerView(
            router: router,
            ocrService: ocrService,
            draftService: draftService
        )

        await view.processOCRAndNavigate(createTestImage()).value

        #expect(ocrService.recognizeDocumentCallCount == 0)
        #expect(pushed == false)
    }

    @Test("PDF retries replace the picker-owned generation with CAS")
    func pdfRetryAfterEmptyOCRUsesCAS() async {
        let draftService = CaptureDraftServiceMock()
        let ocrService = emptyDocumentOCR()
        let view = PDFPagePickerView(
            router: CaptureRouter(),
            ocrService: ocrService,
            draftService: draftService
        )

        await view.processOCRAndNavigate(createTestImage()).value
        let first = draftService.storedDraft?.token
        await view.processOCRAndNavigate(createTestImage()).value

        #expect(ocrService.recognizeDocumentCallCount == 2)
        #expect(draftService.saveCalls.count == 2)
        #expect(draftService.saveCalls.last?.expected == first)
    }

    @Test("multi-page scan checkpoint failure blocks OCR and editor navigation")
    func scanCheckpointFailureBlocksOCRAndNavigation() async {
        let draftService = CaptureDraftServiceMock()
        draftService.saveError = .persistenceFailed
        let ocrService = MockOCRService()
        let router = CaptureRouter()
        var pushed = false
        router.onPush = { _ in pushed = true }
        let view = ScanPagePickerView(
            router: router,
            ocrService: ocrService,
            draftService: draftService
        )

        await view.processImage(createTestImage()).value

        #expect(ocrService.recognizeDocumentCallCount == 0)
        #expect(pushed == false)
    }

    @Test("multi-page scan retries replace the picker-owned generation with CAS")
    func scanRetryAfterEmptyOCRUsesCAS() async {
        let draftService = CaptureDraftServiceMock()
        let ocrService = emptyDocumentOCR()
        let view = ScanPagePickerView(
            router: CaptureRouter(),
            ocrService: ocrService,
            draftService: draftService
        )

        await view.processImage(createTestImage()).value
        let first = draftService.storedDraft?.token
        await view.processImage(createTestImage()).value

        #expect(ocrService.recognizeDocumentCallCount == 2)
        #expect(draftService.saveCalls.count == 2)
        #expect(draftService.saveCalls.last?.expected == first)
    }

    @Test(
        "page picker starts a new capture after its prior generation commits",
        arguments: PagePickerChannel.allCases
    )
    func pickerStartsNewCaptureAfterCommittedResidue(channel: PagePickerChannel) async throws {
        let draftService = CaptureDraftServiceMock()
        let ocrService = emptyDocumentOCR()
        let image = createTestImage()

        let process: () -> Task<Void, Never>
        switch channel {
        case .pdf:
            let view = PDFPagePickerView(
                router: CaptureRouter(),
                ocrService: ocrService,
                draftService: draftService
            )
            process = { view.processOCRAndNavigate(image) }
        case .scan:
            let view = ScanPagePickerView(
                router: CaptureRouter(),
                ocrService: ocrService,
                draftService: draftService
            )
            process = { view.processImage(image) }
        }

        await process().value
        guard let first = draftService.storedDraft?.token else {
            Issue.record("首个页面必须建立 picker-owned generation")
            return
        }
        let settlement = try await draftService.beginSettlement(
            captureID: first.captureID,
            expected: first
        )
        draftService.discardError = .discardFailed
        #expect(throws: CaptureDraftServiceError.discardFailed) {
            try draftService.retireCommittedDraft(settlement)
        }
        draftService.discardError = nil

        await process().value

        #expect(draftService.saveCalls.last?.expected == nil)
        #expect(draftService.saveCalls.last?.captureID == nil)
        #expect(draftService.storedDraft?.token.captureID != first.captureID)
    }

    @Test(
        "page picker clears an older generation after the same capture commits",
        arguments: PagePickerChannel.allCases
    )
    func pickerClearsOlderGenerationAfterEditorCommit(channel: PagePickerChannel) async throws {
        let draftService = CaptureDraftServiceMock()
        let ocrService = emptyDocumentOCR()
        let image = createTestImage()
        let process: () -> Task<Void, Never>
        switch channel {
        case .pdf:
            let view = PDFPagePickerView(
                router: CaptureRouter(),
                ocrService: ocrService,
                draftService: draftService
            )
            process = { view.processOCRAndNavigate(image) }
        case .scan:
            let view = ScanPagePickerView(
                router: CaptureRouter(),
                ocrService: ocrService,
                draftService: draftService
            )
            process = { view.processImage(image) }
        }

        await process().value
        guard let pickerToken = draftService.storedDraft?.token else {
            Issue.record("Picker must own the first generation")
            return
        }
        let editorToken = CaptureDraftToken(
            captureID: pickerToken.captureID,
            generationID: UUID()
        )
        draftService.setDraftToLoad(
            CaptureDraft(
                image: image,
                content: "editor checkpoint",
                date: Date(),
                category: nil,
                token: editorToken
            )
        )
        let settlement = try await draftService.beginSettlement(
            captureID: editorToken.captureID,
            expected: editorToken
        )
        draftService.discardError = .discardFailed
        #expect(throws: CaptureDraftServiceError.discardFailed) {
            try draftService.retireCommittedDraft(settlement)
        }
        draftService.discardError = nil

        await process().value

        #expect(draftService.saveCalls.last?.expected == nil)
        #expect(draftService.saveCalls.last?.captureID == nil)
        #expect(draftService.storedDraft?.token.captureID != pickerToken.captureID)
    }

    @Test(
        "page picker reconciles an editor checkpoint that commits after picker appearance",
        arguments: PagePickerChannel.allCases
    )
    func pickerReconcilesLateEditorCheckpoint(channel: PagePickerChannel) async {
        let base = CaptureDraftServiceMock()
        let draftService = SuspendingCaptureDraftService(base: base)
        let ocrService = emptyDocumentOCR()
        let image = createTestImage()

        let process: () -> Task<Void, Never>
        switch channel {
        case .pdf:
            let view = PDFPagePickerView(
                router: CaptureRouter(),
                ocrService: ocrService,
                draftService: draftService
            )
            process = { view.processOCRAndNavigate(image) }
        case .scan:
            let view = ScanPagePickerView(
                router: CaptureRouter(),
                ocrService: ocrService,
                draftService: draftService
            )
            process = { view.processImage(image) }
        }

        await process().value
        guard let first = base.storedDraft?.token else {
            Issue.record("首个页面必须先建立 picker-owned generation")
            return
        }

        draftService.suspendNextSave()
        let nextPage = process()
        await draftService.waitForSuspendedSave()

        let editorCheckpoint = CaptureDraft(
            image: image,
            content: "editor checkpoint",
            date: Date(),
            category: nil,
            token: CaptureDraftToken(
                captureID: first.captureID,
                generationID: UUID()
            )
        )
        base.setDraftToLoad(editorCheckpoint)
        draftService.resumeSuspendedSave()
        await nextPage.value

        let attempts = Array(base.saveCalls.suffix(2))
        #expect(attempts.count == 2)
        #expect(attempts.first?.expected == first)
        #expect(attempts.last?.expected == editorCheckpoint.token)
        #expect(base.storedDraft?.token.captureID == first.captureID)
        #expect(base.storedDraft?.token != editorCheckpoint.token)
    }

    private func emptyDocumentOCR() -> MockOCRService {
        let service = MockOCRService()
        service.recognizeDocumentResult = DocumentRecognitionResult(
            transcript: "",
            paragraphs: [],
            tables: []
        )
        return service
    }
}

enum PagePickerChannel: String, CaseIterable, CustomTestStringConvertible {
    case pdf
    case scan

    var testDescription: String { rawValue }
}

@MainActor
private final class SuspendingCaptureDraftService: CaptureDraftServiceProtocol {
    private let base: CaptureDraftServiceMock
    private var shouldSuspendNextSave = false
    private var isSaveSuspended = false
    private var releaseRequested = false
    private var saveStartedContinuation: CheckedContinuation<Void, Never>?
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    init(base: CaptureDraftServiceMock) {
        self.base = base
    }

    func suspendNextSave() {
        shouldSuspendNextSave = true
    }

    func waitForSuspendedSave() async {
        guard !isSaveSuspended else {
            return
        }
        await withCheckedContinuation {
            saveStartedContinuation = $0
        }
    }

    func resumeSuspendedSave() {
        if let releaseContinuation {
            self.releaseContinuation = nil
            releaseContinuation.resume()
        } else {
            releaseRequested = true
        }
    }

    func state() -> CaptureDraftState {
        base.state()
    }

    func pendingSettlementToken() -> CaptureDraftToken? {
        base.pendingSettlementToken()
    }

    func saveDraft(
        image: UIImage?,
        content: String,
        category: String?,
        captureID: UUID?,
        expected: CaptureDraftToken?
    ) async throws -> CaptureDraftToken {
        if shouldSuspendNextSave {
            shouldSuspendNextSave = false
            isSaveSuspended = true
            saveStartedContinuation?.resume()
            saveStartedContinuation = nil
            await withCheckedContinuation { continuation in
                if releaseRequested {
                    releaseRequested = false
                    continuation.resume()
                } else {
                    releaseContinuation = continuation
                }
            }
            isSaveSuspended = false
        }
        return try await base.saveDraft(
            image: image,
            content: content,
            category: category,
            captureID: captureID,
            expected: expected
        )
    }

    func discard(_ revision: CaptureDraftRevision) throws {
        try base.discard(revision)
    }

    func beginSettlement(
        captureID: UUID,
        expected: CaptureDraftToken?
    ) async throws -> CaptureDraftSettlement {
        try await base.beginSettlement(captureID: captureID, expected: expected)
    }

    func abortSettlement(_ settlement: CaptureDraftSettlement) throws {
        try base.abortSettlement(settlement)
    }

    func retireCommittedDraft(_ settlement: CaptureDraftSettlement) throws {
        try base.retireCommittedDraft(settlement)
    }

    func reconcileCommittedDraft(_ token: CaptureDraftToken) throws {
        try base.reconcileCommittedDraft(token)
    }

    func reconcileUncommittedDraft(_ token: CaptureDraftToken) throws {
        try base.reconcileUncommittedDraft(token)
    }
}
