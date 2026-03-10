//
//  CaptureViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/02/25.
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
}

@Suite("CaptureViewModel 草稿与扫描测试")
@MainActor
struct CaptureViewModelTests {

    // MARK: - Helpers

    private func cleanUpDraft() {
        CaptureDraftService.shared.clearDraft()
    }

    // MARK: - 草稿

    @Test("checkDraftOnAppear 有草稿时显示弹窗")
    func testCheckDraftOnAppear_WithDraft_ShowsAlert() async {
        cleanUpDraft()
        await CaptureDraftService.shared.saveDraft(image: createTestImage(), content: "Draft Content")

        let viewModel = CaptureViewModel(ocrService: MockOCRService())

        viewModel.checkDraftOnAppear()

        #expect(viewModel.showDraftAlert == true)
        #expect(viewModel.pendingDraft != nil)
        #expect(viewModel.pendingDraft?.content == "Draft Content")

        cleanUpDraft()
    }

    @Test("startEditingDraft 推送路由并清除草稿")
    func testStartEditingDraft_PushesToRouterAndClearsDraft() async {
        cleanUpDraft()
        await CaptureDraftService.shared.saveDraft(image: createTestImage(), content: "Draft Content")

        let viewModel = CaptureViewModel(ocrService: MockOCRService())
        viewModel.checkDraftOnAppear()

        let router = CaptureRouter()
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
        #expect(CaptureDraftService.shared.hasDraft == false)

        cleanUpDraft()
    }

    @Test("clearDraft 清除草稿")
    func testClearDraft_RemovesDraft() async {
        cleanUpDraft()
        await CaptureDraftService.shared.saveDraft(image: createTestImage(), content: "Draft Content")

        let viewModel = CaptureViewModel(ocrService: MockOCRService())
        viewModel.checkDraftOnAppear()

        viewModel.clearDraft()

        #expect(viewModel.pendingDraft == nil)
        #expect(CaptureDraftService.shared.hasDraft == false)

        cleanUpDraft()
    }

    // MARK: - OCR 扫描

    @Test("processScannedImage 成功时推送识别结果")
    func testProcessScannedImage_Success_PushesResult() async throws {
        let mockOCR = MockOCRService()
        mockOCR.recognizeTextResult = "Recognized Text"

        let viewModel = CaptureViewModel(ocrService: mockOCR)
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

    @Test("processScannedImage 失败时推送空内容")
    func testProcessScannedImage_Error_PushesEmptyResult() async throws {
        let mockOCR = MockOCRService()
        mockOCR.recognizeTextError = NSError(domain: "test", code: -1, userInfo: nil)

        let viewModel = CaptureViewModel(ocrService: mockOCR)
        let router = CaptureRouter()

        var pushCalled = false
        router.onPush = { destination in
            if case let .scannerResult(content, _) = destination {
                #expect(content == "")
                pushCalled = true
            }
        }

        viewModel.processScannedImage(createTestImage(), router: router)

        try await waitUntil { pushCalled }
        #expect(mockOCR.recognizeTextCallCount == 1)
        #expect(viewModel.isProcessing == false)
    }
}
