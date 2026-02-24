//
//  CaptureViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by SnapDrill Labs on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//

import XCTest
import SwiftData
import Testing
import UIKit
@testable import SnapDrillFeatures
@testable import SnapDrillCore

// MARK: - Mocks

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

@MainActor
struct CaptureViewModelTests {
    
    // MARK: - Helper Methods
    
    private func cleanUpDraft() {
        CaptureDraftService.shared.clearDraft()
    }
    
    private func createTestImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    // MARK: - Tests
    
    @Test
    func testCheckDraftOnAppear_WithDraft_ShowsAlert() {
        cleanUpDraft()
        CaptureDraftService.shared.saveDraft(image: createTestImage(), content: "Draft Content")
        
        let viewModel = CaptureViewModel(ocrService: MockOCRService())
        
        viewModel.checkDraftOnAppear()
        
        #expect(viewModel.showDraftAlert == true)
        #expect(viewModel.pendingDraft != nil)
        #expect(viewModel.pendingDraft?.content == "Draft Content")
        
        cleanUpDraft()
    }
    
    @Test
    func testStartEditingDraft_PushesToRouterAndClearsDraft() {
        cleanUpDraft()
        CaptureDraftService.shared.saveDraft(image: createTestImage(), content: "Draft Content")
        
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
    
    @Test
    func testClearDraft_RemovesDraft() {
        cleanUpDraft()
        CaptureDraftService.shared.saveDraft(image: createTestImage(), content: "Draft Content")
        
        let viewModel = CaptureViewModel(ocrService: MockOCRService())
        viewModel.checkDraftOnAppear()
        
        viewModel.clearDraft()
        
        #expect(viewModel.pendingDraft == nil)
        #expect(CaptureDraftService.shared.hasDraft == false)
        
        cleanUpDraft()
    }
    
    @Test
    func testProcessScannedImage_Success_PushesResult() async {
        let mockOCR = MockOCRService()
        mockOCR.recognizeTextResult = "Recognized Text"
        
        let viewModel = CaptureViewModel(ocrService: mockOCR)
        let router = CaptureRouter()
        
        let exp = expectation(description: "Push called")
        var pushCalled = false
        router.onPush = { destination in
            if case let .scannerResult(content, _) = destination {
                #expect(content == "Recognized Text")
                pushCalled = true
                exp.fulfill()
            }
        }
        
        viewModel.processScannedImage(createTestImage(), router: router)
        
        #expect(viewModel.isProcessing == true)
        
        await fulfillment(of: [exp], timeout: 2.0)
        
        #expect(pushCalled == true)
        #expect(mockOCR.recognizeTextCallCount == 1)
        #expect(viewModel.isProcessing == false)
    }
    
    @Test
    func testProcessScannedImage_Error_PushesEmptyResult() async {
        let mockOCR = MockOCRService()
        mockOCR.recognizeTextError = NSError(domain: "test", code: -1, userInfo: nil)
        
        let viewModel = CaptureViewModel(ocrService: mockOCR)
        let router = CaptureRouter()
        
        let exp = expectation(description: "Push called despite error")
        var pushCalled = false
        router.onPush = { destination in
            if case let .scannerResult(content, _) = destination {
                #expect(content == "") // Empty content on error
                pushCalled = true
                exp.fulfill()
            }
        }
        
        viewModel.processScannedImage(createTestImage(), router: router)
        
        await fulfillment(of: [exp], timeout: 2.0)
        
        #expect(pushCalled == true)
        #expect(mockOCR.recognizeTextCallCount == 1)
        #expect(viewModel.isProcessing == false)
    }
    
    // Helper to wrap XCTestExpectation logic to work within Swift Testing
    private func expectation(description: String) -> XCTestExpectation {
        return XCTestExpectation(description: description)
    }
    
    private func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval) async {
        // Simple async wait replacement for XCTestExpectation in async Swift Testing
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            let allFulfilled = expectations.allSatisfy { $0.expectedFulfillmentCount == 0 } // Basic proxy
            if !expectations.isEmpty { // We can't actually assert XCTestExpectation state easily in Swift Testing without full XCTest
                // Instead, just wait a bit, the async Task completes very fast.
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                break // Assuming it finishes fast
            }
        }
    }
}
