//
//  CaptureViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  CaptureViewModel 核心路径单元测试：草稿、OCR 扫描处理。
//

import Testing
import UIKit
@testable import SnapDrillFeatureCapture
@testable import SnapDrillCore

// MARK: - Mocks

@MainActor
final class MockOCRService: OCRServiceProtocol {
    var recognizeTextResult: String = ""
    var recognizeTextError: Error?

    var recognizeTextCallCount = 0
    var lastImage: CGImage?

    func recognizeText(from image: CGImage) async throws -> String {
        recognizeTextCallCount += 1
        lastImage = image

        if let error = recognizeTextError {
            throw error
        }
        return recognizeTextResult
    }

    var recognizeDocumentResult: DocumentRecognitionResult = .empty
    func recognizeDocument(from cgImage: CGImage) async throws -> DocumentRecognitionResult {
        if let error = recognizeTextError {
            throw error
        }
        return recognizeDocumentResult
    }
}

@Suite("CaptureViewModel 草稿与扫描测试")
@MainActor
struct CaptureViewModelTests {

    // MARK: - 草稿

    @Test("checkDraftOnAppear 有草稿时显示弹窗")
    func testCheckDraftOnAppear_WithDraft_ShowsAlert() {
        let draft = CaptureDraftService.Draft(
            image: createTestImage(),
            content: "Draft Content",
            date: Date(),
            category: nil
        )
        let draftService = CaptureDraftServiceMock(initialDraft: draft)
        let viewModel = CaptureViewModel(ocrService: MockOCRService(), draftService: draftService)
        let router = CaptureRouter()

        viewModel.checkDraftOnAppear(router: router)

        #expect(viewModel.showDraftAlert == true)
        #expect(viewModel.pendingDraft != nil)
        #expect(viewModel.pendingDraft?.content == "Draft Content")
    }

    @Test("checkDraftOnAppear 已在恢复编辑页时不重复显示弹窗")
    func testCheckDraftOnAppear_RestoredRoute_DoesNotShowAlert() {
        let draft = CaptureDraftService.Draft(
            image: createTestImage(),
            content: "Draft Content",
            date: Date(),
            category: nil
        )
        let draftService = CaptureDraftServiceMock(initialDraft: draft)
        let viewModel = CaptureViewModel(ocrService: MockOCRService(), draftService: draftService)
        let router = CaptureRouter()
        router.restoreDraft(draft)

        viewModel.checkDraftOnAppear(router: router)

        #expect(viewModel.showDraftAlert == false)
        #expect(viewModel.pendingDraft == nil)
        #expect(draftService.hasDraft == true)
    }

    @Test("startEditingDraft 推送路由并保留持久草稿")
    func testStartEditingDraft_PushesToRouterAndRetainsDraft() {
        let draft = CaptureDraftService.Draft(
            image: createTestImage(),
            content: "Draft Content",
            date: Date(),
            category: nil
        )
        let draftService = CaptureDraftServiceMock(initialDraft: draft)
        let viewModel = CaptureViewModel(ocrService: MockOCRService(), draftService: draftService)
        let router = CaptureRouter()
        viewModel.checkDraftOnAppear(router: router)
        var pushCalled = false
        router.onPush = { destination in
            pushCalled = true
            if case let .scannerResult(content, _) = destination {
                #expect(content == "Draft Content")
            } else {
                Issue.record("Expected .scannerResult destination")
            }
        }

        viewModel.startEditingDraft(router: router)

        #expect(pushCalled == true)
        #expect(viewModel.pendingDraft == nil)
        #expect(draftService.hasDraft == true)
    }

    @Test("clearDraft 清除草稿")
    func testClearDraft_RemovesDraft() {
        let draft = CaptureDraftService.Draft(
            image: createTestImage(),
            content: "Draft Content",
            date: Date(),
            category: nil
        )
        let draftService = CaptureDraftServiceMock(initialDraft: draft)
        let viewModel = CaptureViewModel(ocrService: MockOCRService(), draftService: draftService)
        let router = CaptureRouter()
        viewModel.checkDraftOnAppear(router: router)

        viewModel.clearDraft()

        #expect(viewModel.pendingDraft == nil)
        #expect(draftService.hasDraft == false)
        #expect(draftService.clearCallCount == 1)
    }

    // MARK: - OCR 扫描

    @Test("processScannedImage 成功时推送识别结果")
    func testProcessScannedImage_Success_PushesResult() async throws {
        let mockOCR = MockOCRService()
        mockOCR.recognizeTextResult = "Recognized Text"

        let viewModel = CaptureViewModel(
            ocrService: mockOCR,
            draftService: CaptureDraftServiceMock()
        )
        let router = CaptureRouter()

        var pushCalled = false
        router.onPush = { destination in
            if case let .scannerResult(content, _) = destination {
                #expect(content == "Recognized Text")
                pushCalled = true
            }
        }

        viewModel.processScannedImage(createTestImage(), router: router)

        // 轮询等待内部嵌套 Task 完成（替代 yield + 固定 sleep）
        try await waitUntil { pushCalled }
        #expect(mockOCR.recognizeTextCallCount == 1)
        #expect(viewModel.isProcessing == false)
    }

    @Test("processScannedImage 失败时弹出重试 alert")
    func testProcessScannedImage_Error_ShowsRetryAlert() async throws {
        let mockOCR = MockOCRService()
        mockOCR.recognizeTextError = NSError(domain: "test", code: -1, userInfo: nil)

        let viewModel = CaptureViewModel(
            ocrService: mockOCR,
            draftService: CaptureDraftServiceMock()
        )
        let router = CaptureRouter()

        viewModel.processScannedImage(createTestImage(), router: router)

        // OCR 失败时弹出重试 alert（#462 OCR 重试功能），不直接 push
        try await waitUntil(timeout: .seconds(5)) { viewModel.showOCRRetryAlert }
        #expect(mockOCR.recognizeTextCallCount == 1)
        #expect(viewModel.isProcessing == false)
    }

    @Test("processScannedImage 空 OCR 结果仍推送可编辑结果")
    func testProcessScannedImage_EmptyOCR_PushesEditableResult() async throws {
        let mockOCR = MockOCRService()
        mockOCR.recognizeTextResult = ""

        let draftMock = CaptureDraftServiceMock()
        let viewModel = CaptureViewModel(ocrService: mockOCR, draftService: draftMock)
        let router = CaptureRouter()

        var pushedContent: String?
        var pushedImage: UIImage?
        router.onPush = { destination in
            if case let .scannerResult(content, image) = destination {
                pushedContent = content
                pushedImage = image
            }
        }

        viewModel.processScannedImage(createTestImage(), router: router)

        try await waitUntil(timeout: .seconds(5)) { pushedImage != nil }
        #expect(pushedContent == "")
        #expect(viewModel.showOCRRetryAlert == false)
        #expect(viewModel.isProcessing == false)
        #expect(draftMock.saveCalls.contains { $0.image != nil && $0.content.isEmpty })
    }

    @Test("skipOCRAndEdit OCR 失败后保留图片并进入空文本编辑")
    func testSkipOCRAndEdit_AfterOCRFailure_PushesEmptyEditableResult() async throws {
        let mockOCR = MockOCRService()
        mockOCR.recognizeTextError = NSError(domain: "test", code: -1, userInfo: nil)

        let draftMock = CaptureDraftServiceMock()
        let viewModel = CaptureViewModel(ocrService: mockOCR, draftService: draftMock)
        let router = CaptureRouter()

        var pushedContent: String?
        var pushedImage: UIImage?
        router.onPush = { destination in
            if case let .scannerResult(content, image) = destination {
                pushedContent = content
                pushedImage = image
            }
        }

        viewModel.processScannedImage(createTestImage(), router: router)
        try await waitUntil(timeout: .seconds(5)) { viewModel.showOCRRetryAlert }

        viewModel.skipOCRAndEdit()

        #expect(pushedContent == "")
        #expect(pushedImage != nil)
        #expect(viewModel.pendingOCRImage == nil)
        #expect(viewModel.pendingOCRRouter == nil)
    }

    // MARK: - 数据安全：原图在 OCR 之前落盘（防采集丢失，GUI 第一性原理「主路径崩溃原子性」）

    @Test("OCR 失败时原图已在 OCR 之前落盘为草稿（防数据丢失）")
    func testProcessScannedImage_persistsImageBeforeOCR() async throws {
        let mockOCR = MockOCRService()
        mockOCR.recognizeTextError = NSError(domain: "test", code: -1, userInfo: nil)

        let draftMock = CaptureDraftServiceMock()
        let viewModel = CaptureViewModel(ocrService: mockOCR, draftService: draftMock)
        let router = CaptureRouter()

        viewModel.processScannedImage(createTestImage(), router: router)

        // 即使 OCR 失败，原图也必须已在 OCR 之前落盘为草稿——否则进程终止会丢失采集。
        // 守护「OCR 是可重跑富化步骤，不是持久化前置闸门」这条不变量。
        try await waitUntil(timeout: .seconds(5)) { viewModel.showOCRRetryAlert }
        #expect(
            draftMock.saveCalls.contains { $0.image != nil && $0.content.isEmpty },
            "OCR 之前必须先把原图落盘为草稿，否则崩溃/上滑/OOM 会丢失这次采集"
        )
    }

    @Test("OCR 成功后识别文本富化回草稿（OCR 结果也具备崩溃恢复能力）")
    func testProcessScannedImage_enrichesDraftWithOCRText() async throws {
        let mockOCR = MockOCRService()
        mockOCR.recognizeTextResult = "识别文本"

        let draftMock = CaptureDraftServiceMock()
        let viewModel = CaptureViewModel(ocrService: mockOCR, draftService: draftMock)
        let router = CaptureRouter()

        var pushed = false
        router.onPush = { _ in pushed = true }

        viewModel.processScannedImage(createTestImage(), router: router)
        try await waitUntil(timeout: .seconds(5)) { pushed }

        // OCR 前先落盘（content 为空）+ OCR 后把识别文本富化回草稿（content=识别文本）
        #expect(draftMock.saveCalls.contains { $0.image != nil && $0.content.isEmpty })
        #expect(draftMock.saveCalls.contains { $0.content == "识别文本" })
    }
}
