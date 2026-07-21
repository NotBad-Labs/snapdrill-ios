//
//  CapturePageImportProcessorTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import Testing
@testable import SnapDrillCore
@testable import SnapDrillFeatureCapture

@Suite("Capture page import durable-before-OCR flow")
@MainActor
struct CapturePageImportProcessorTests {
    @Test("successful page import checkpoints before OCR and enriches by CAS")
    func successCheckpointsThenEnriches() async {
        let ocr = MockOCRService()
        ocr.recognizeDocumentResult = DocumentRecognitionResult(
            transcript: "Recognized page",
            paragraphs: ["Recognized page"],
            tables: []
        )
        let draftService = CaptureDraftServiceMock()
        let tracker = AppActivityTracker()
        let outcome = await makeProcessor(
            ocr: ocr,
            draftService: draftService,
            tracker: tracker
        ).process(createTestImage())

        guard case .ready(let content, let token) = outcome else {
            Issue.record("Expected ready outcome")
            return
        }
        #expect(content == "Recognized page")
        #expect(ocr.recognizeDocumentCallCount == 1)
        #expect(draftService.saveCalls.count == 2)
        #expect(draftService.saveCalls[0].content.isEmpty)
        #expect(draftService.saveCalls[0].expectedToken == nil)
        #expect(draftService.saveCalls[1].content == content)
        #expect(draftService.saveCalls[1].expectedToken != nil)
        #expect(recoverablePageDraft(in: draftService)?.token == token)
        #expect(tracker.canSwitchProfile)
    }

    @Test("checkpoint failure stops before OCR")
    func checkpointFailureStopsBeforeOCR() async {
        let ocr = MockOCRService()
        let draftService = CaptureDraftServiceMock()
        draftService.saveError = .storageFailure
        let tracker = AppActivityTracker()
        let outcome = await makeProcessor(
            ocr: ocr,
            draftService: draftService,
            tracker: tracker
        ).process(createTestImage())

        guard case .checkpointFailed = outcome else {
            Issue.record("Expected checkpoint failure")
            return
        }
        #expect(ocr.recognizeDocumentCallCount == 0)
        #expect(draftService.saveCalls.isEmpty)
        #expect(tracker.canSwitchProfile)
    }

    @Test("OCR failure retains the image checkpoint")
    func ocrFailureRetainsCheckpoint() async {
        let ocr = MockOCRService()
        ocr.recognizeTextError = NSError(domain: "test", code: -1)
        let draftService = CaptureDraftServiceMock()
        let tracker = AppActivityTracker()
        let outcome = await makeProcessor(
            ocr: ocr,
            draftService: draftService,
            tracker: tracker
        ).process(createTestImage())

        guard case .ocrUnavailable(let token) = outcome else {
            Issue.record("Expected OCR unavailable outcome")
            return
        }
        #expect(draftService.saveCalls.count == 1)
        #expect(recoverablePageDraft(in: draftService)?.token == token)
        #expect(tracker.canSwitchProfile)
    }

    @Test("empty OCR remains a recoverable image-only checkpoint")
    func emptyOCRRetainsCheckpoint() async {
        let ocr = MockOCRService()
        let draftService = CaptureDraftServiceMock()
        let tracker = AppActivityTracker()
        let outcome = await makeProcessor(
            ocr: ocr,
            draftService: draftService,
            tracker: tracker
        ).process(createTestImage())

        guard case .ocrEmpty(let token) = outcome else {
            Issue.record("Expected empty OCR outcome")
            return
        }
        #expect(draftService.saveCalls.count == 1)
        #expect(recoverablePageDraft(in: draftService)?.token == token)
        #expect(tracker.canSwitchProfile)
    }

    @Test("enrichment failure preserves OCR text and the checkpoint token")
    func enrichmentFailurePreservesCheckpoint() async {
        let ocr = MockOCRService()
        ocr.recognizeDocumentResult = DocumentRecognitionResult(
            transcript: "Useful OCR",
            paragraphs: [],
            tables: []
        )
        let draftService = CaptureDraftServiceMock()
        draftService.saveError = .storageFailure
        draftService.saveErrorOnCallNumber = 2
        let tracker = AppActivityTracker()
        let outcome = await makeProcessor(
            ocr: ocr,
            draftService: draftService,
            tracker: tracker
        ).process(createTestImage())

        guard case .enrichmentFailed(let content, let token) = outcome else {
            Issue.record("Expected enrichment failure")
            return
        }
        #expect(content == "Useful OCR")
        #expect(draftService.saveCalls.count == 1)
        #expect(recoverablePageDraft(in: draftService)?.content.isEmpty == true)
        #expect(recoverablePageDraft(in: draftService)?.token == token)
        #expect(tracker.canSwitchProfile)
    }

    private func makeProcessor(
        ocr: MockOCRService,
        draftService: CaptureDraftServiceMock,
        tracker: AppActivityTracker
    ) -> CapturePageImportProcessor {
        CapturePageImportProcessor(
            ocrService: ocr,
            draftService: draftService,
            activityTracker: tracker
        )
    }
}

@MainActor
private func recoverablePageDraft(in service: CaptureDraftServiceMock) -> CaptureDraft? {
    guard case .recoverable(let draft) = service.state else { return nil }
    return draft
}
