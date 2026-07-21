//
//  CaptureViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Testing
import UIKit
@testable import SnapDrillFeatureCapture
@testable import SnapDrillCore

@MainActor
final class MockOCRService: OCRServiceProtocol {
    var recognizeTextResult = ""
    var recognizeTextError: Error?
    var recognizeTextCallCount = 0
    var lastImage: CGImage?

    func recognizeText(from image: CGImage) async throws -> String {
        recognizeTextCallCount += 1
        lastImage = image
        if let recognizeTextError { throw recognizeTextError }
        return recognizeTextResult
    }

    var recognizeDocumentResult: DocumentRecognitionResult = .empty
    var recognizeDocumentCallCount = 0

    func recognizeDocument(from cgImage: CGImage) async throws -> DocumentRecognitionResult {
        recognizeDocumentCallCount += 1
        if let recognizeTextError { throw recognizeTextError }
        return recognizeDocumentResult
    }
}

@Suite("CaptureViewModel draft checkpoint flow")
@MainActor
struct CaptureViewModelTests {
    @Test("recoverable draft prompts and restore routes its exact token")
    func recoverableDraftPromptsAndRestoresExactToken() async {
        let draftService = CaptureDraftServiceMock()
        draftService.seedDraft(image: createTestImage(), content: "Draft Content")
        let expected = recoverableDraft(in: draftService)?.token
        let viewModel = makeViewModel(draftService: draftService)
        let router = CaptureRouter()
        var routedToken: CaptureDraftToken?
        router.onPush = { destination in
            if case .scannerResult(let content, _, let token) = destination {
                #expect(content == "Draft Content")
                routedToken = token
            }
        }

        await viewModel.checkDraftOnAppear(router: router) { _ in false }
        #expect(viewModel.showDraftAlert)
        viewModel.startEditingDraft(router: router)

        #expect(routedToken == expected)
        #expect(viewModel.pendingDraft == nil)
        #expect(recoverableDraft(in: draftService) != nil)
    }

    @Test("returning from a restored draft immediately reopens the root decision gate")
    func restoredRouteRepromptsOnReturn() async {
        let draftService = CaptureDraftServiceMock()
        draftService.seedDraft(content: "Draft Content")
        guard let draft = recoverableDraft(in: draftService) else {
            Issue.record("Expected seeded draft")
            return
        }
        let viewModel = makeViewModel(draftService: draftService)
        let router = CaptureRouter()
        router.restoreDraft(draft)

        await viewModel.checkDraftOnAppear(router: router) { _ in false }
        #expect(!viewModel.showDraftAlert)
        router.path.removeLast()
        await viewModel.checkDraftOnAppear(router: router) { _ in false }
        #expect(viewModel.showDraftAlert)
        #expect(viewModel.isDraftAdmissionBlocked)
    }

    @Test("draft whose capture ID is already committed is retired without prompting")
    func committedDraftIsReconciled() async {
        let draftService = CaptureDraftServiceMock()
        draftService.seedDraft(content: "already saved")
        let captureID = recoverableDraft(in: draftService)?.token.captureID
        let viewModel = makeViewModel(draftService: draftService)

        await viewModel.checkDraftOnAppear(router: CaptureRouter()) { $0 == captureID }

        #expect(!viewModel.showDraftAlert)
        #expect(draftService.discardCallCount == 1)
        #expect(isNone(draftService.state))
    }

    @Test("committed-item lookup failure keeps recovery and new capture closed")
    func committedLookupFailureFailsClosed() async {
        let draftService = CaptureDraftServiceMock()
        draftService.seedDraft(content: "possibly committed")
        let viewModel = makeViewModel(draftService: draftService)

        await viewModel.checkDraftOnAppear(router: CaptureRouter()) { _ in
            throw TestLookupError.failed
        }

        #expect(!viewModel.showDraftAlert)
        #expect(viewModel.showErrorAlert)
        #expect(viewModel.draftCheckNeedsRetry)
        #expect(viewModel.isDraftAdmissionBlocked)
        #expect(draftService.discardCallCount == 0)
    }

    @Test("an occupied draft returns a multi-page picker to the root decision gate")
    func occupiedDraftClosesPagePicker() async {
        let draftService = CaptureDraftServiceMock()
        draftService.seedDraft(content: "unfinished page")
        let router = CaptureRouter()
        router.push(.pdfPagePicker)

        await CaptureDraftPickerAdmission.returnToRootIfOccupied(
            router: router,
            draftService: draftService
        )

        #expect(router.path.isEmpty)
    }

    @Test("an empty draft slot leaves a multi-page picker open")
    func emptyDraftSlotKeepsPagePickerOpen() async {
        let router = CaptureRouter()
        router.push(.scanPagePicker)

        await CaptureDraftPickerAdmission.returnToRootIfOccupied(
            router: router,
            draftService: CaptureDraftServiceMock()
        )

        #expect(router.path.count == 1)
    }

    @Test("unrecoverable artifact gets a distinct prompt and explicit discard")
    func unrecoverableDraftIsNotCollapsedToNone() async {
        let discardToken = CaptureDraftDiscardToken(storageObservation: "node")
        let failure = CaptureDraftFailure(
            reason: .integrityCheckFailed,
            discardToken: discardToken
        )
        let draftService = CaptureDraftServiceMock(initialState: .unrecoverable(failure))
        let viewModel = makeViewModel(draftService: draftService)

        await viewModel.checkDraftOnAppear(router: CaptureRouter()) { _ in false }
        #expect(viewModel.showUnrecoverableDraftAlert)
        #expect(!viewModel.showDraftAlert)

        await viewModel.clearDraft()
        #expect(isNone(draftService.state))
        #expect(draftService.discardCallCount == 1)
    }

    @Test("camera image is checkpointed before OCR and enriched by CAS")
    func successfulOCRCheckpointsThenEnriches() async throws {
        let ocr = MockOCRService()
        ocr.recognizeTextResult = "Recognized Text"
        let draftService = CaptureDraftServiceMock()
        let viewModel = makeViewModel(ocr: ocr, draftService: draftService)
        let router = CaptureRouter()
        var routedToken: CaptureDraftToken?
        router.onPush = { destination in
            if case .scannerResult(let content, _, let token) = destination {
                #expect(content == "Recognized Text")
                routedToken = token
            }
        }

        viewModel.processScannedImage(createTestImage(), router: router)
        try await waitUntil { routedToken != nil }

        #expect(ocr.recognizeTextCallCount == 1)
        #expect(draftService.saveCalls.count == 2)
        #expect(draftService.saveCalls[0].content.isEmpty)
        #expect(draftService.saveCalls[0].expectedToken == nil)
        #expect(draftService.saveCalls[1].content == "Recognized Text")
        #expect(draftService.saveCalls[1].expectedToken != nil)
        #expect(routedToken == recoverableDraft(in: draftService)?.token)
    }

    @Test("OCR failure retains checkpoint and continue-edit routes its token")
    func failedOCRRetainsCheckpoint() async throws {
        let ocr = MockOCRService()
        ocr.recognizeTextError = NSError(domain: "test", code: -1)
        let draftService = CaptureDraftServiceMock()
        let viewModel = makeViewModel(ocr: ocr, draftService: draftService)
        let router = CaptureRouter()
        var routedToken: CaptureDraftToken?
        router.onPush = { destination in
            if case .scannerResult(_, _, let token) = destination {
                routedToken = token
            }
        }

        viewModel.processScannedImage(createTestImage(), router: router)
        try await waitUntil { viewModel.showOCRRetryAlert }
        let checkpoint = recoverableDraft(in: draftService)?.token
        viewModel.skipOCRAndEdit()

        #expect(draftService.saveCalls.count == 1)
        #expect(routedToken == checkpoint)
        #expect(viewModel.pendingOCRDraftToken == nil)
    }

    @Test("checkpoint failure prevents OCR and navigation")
    func checkpointFailureStopsBeforeOCR() async throws {
        let ocr = MockOCRService()
        let draftService = CaptureDraftServiceMock()
        draftService.saveError = .storageFailure
        let viewModel = makeViewModel(ocr: ocr, draftService: draftService)
        let router = CaptureRouter()
        var didPush = false
        router.onPush = { _ in didPush = true }

        viewModel.processScannedImage(createTestImage(), router: router)
        try await waitUntil { viewModel.showErrorAlert }

        #expect(ocr.recognizeTextCallCount == 0)
        #expect(!didPush)
        #expect(!viewModel.isProcessing)
    }

    @Test("empty OCR result remains editable and durable")
    func emptyOCRResultRoutesEnrichedDraft() async throws {
        let ocr = MockOCRService()
        let draftService = CaptureDraftServiceMock()
        let viewModel = makeViewModel(ocr: ocr, draftService: draftService)
        let router = CaptureRouter()
        var didPush = false
        router.onPush = { destination in
            if case .scannerResult(let content, let image, let token) = destination {
                #expect(content.isEmpty)
                #expect(image != nil)
                #expect(token != nil)
                didPush = true
            }
        }

        viewModel.processScannedImage(createTestImage(), router: router)
        try await waitUntil { didPush }

        #expect(draftService.saveCalls.count == 2)
        #expect(!viewModel.showOCRRetryAlert)
    }

    private func makeViewModel(
        ocr: MockOCRService = MockOCRService(),
        draftService: CaptureDraftServiceMock
    ) -> CaptureViewModel {
        CaptureViewModel(
            ocrService: ocr,
            draftService: draftService,
            activityTracker: AppActivityTracker()
        )
    }
}

private enum TestLookupError: Error {
    case failed
}

private func recoverableDraft(in service: CaptureDraftServiceMock) -> CaptureDraft? {
    guard case .recoverable(let draft) = service.state else { return nil }
    return draft
}

private func isNone(_ state: CaptureDraftReadState) -> Bool {
    if case .none = state { return true }
    return false
}
