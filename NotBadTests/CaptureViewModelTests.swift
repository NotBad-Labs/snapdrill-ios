//
//  CaptureViewModelTests.swift
//  NotBadTests
//
//  Created by Copilot on 9/22/25.
//

import XCTest
import Combine
import UIKit
@testable import NotBad

@MainActor
final class CaptureViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Helpers
    private func make1x1Image() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        return renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }

    private func makeSUT() -> (CaptureViewModel, MockCaptureCoordinator, AppErrorHandler) {
        let reviewItemService = ReviewItemService(repository: InMemoryReviewItemRepository())
        let useCase = CaptureReviewItemUseCase(reviewItemService: reviewItemService)
        let coordinator = MockCaptureCoordinator()
        let sut = CaptureViewModel(captureUseCase: useCase, coordinator: coordinator)
        let errorHandler = AppErrorHandler()
        sut.configure(errorHandler: errorHandler)
        return (sut, coordinator, errorHandler)
    }

    // MARK: - Tests
    func testShowCameraAndPhotoLibraryToggles() async {
        let (vm, _, _) = makeSUT()

        vm.showCameraView()
        XCTAssertTrue(vm.showCamera)

        vm.showPhotoLibraryView()
        XCTAssertTrue(vm.showPhotoLibrary)
    }

    func testHandleCapturedImage_runsOCR_setsResult_andNavigatesToSave() async {
        let (vm, coordinator, _) = makeSUT()
        let image = make1x1Image()

        let resultExpectation = expectation(description: "OCR result set and navigation triggered")

        // Observe ocrResult to know when processing finished
        vm.$ocrResult
            .dropFirst()
            .sink { result in
                if result != nil {
                    resultExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        vm.showCameraView()
        vm.handleCapturedImage(image)

        // Then (wait OCR)
        await fulfillment(of: [resultExpectation], timeout: 5.0)

        XCTAssertFalse(vm.isProcessingOCR)
        XCTAssertEqual(vm.ocrProgress, 0.0, accuracy: 0.0001)
        XCTAssertNotNil(vm.ocrResult)
        XCTAssertEqual(vm.capturedImage?.size, image.size)
        XCTAssertFalse(vm.showCamera) // hidden after capture

        // Verify navigation to save with expected content
        guard case let .saveReviewItem(content: content)? = coordinator.lastDelegatedRoute else {
            return XCTFail("Expected navigation to saveReviewItem")
        }
        XCTAssertTrue(content.contains("题目："))
        XCTAssertTrue(content.contains("答案："))
    }

    func testSaveAsReviewItem_withoutResult_presentsError() async {
        let (vm, _, errorHandler) = makeSUT()

        // Ensure no OCR result yet
        vm.ocrResult = nil
        vm.saveAsReviewItem()

        // Error presentation happens synchronously for warning
        XCTAssertNotNil(errorHandler.currentError)
        XCTAssertEqual(errorHandler.currentError?.message, "没有OCR结果可保存")
    }

    func testRetakePhoto_resetsState_andShowsCamera() async {
        let (vm, _, _) = makeSUT()
        vm.capturedImage = make1x1Image()
        vm.ocrResult = OCRResult(question: "Q", answer: "A", notes: nil, confidence: 1.0)

        vm.retakePhoto()

        XCTAssertNil(vm.capturedImage)
        XCTAssertNil(vm.ocrResult)
        XCTAssertTrue(vm.showCamera)
    }

    func testNavigateToManualInput_routesToSaveWithEmptyContent() async {
        let (vm, coordinator, _) = makeSUT()

        vm.navigateToManualInput()

        guard case let .saveReviewItem(content: content)? = coordinator.lastDelegatedRoute else {
            return XCTFail("Expected navigation to saveReviewItem")
        }
        XCTAssertEqual(content, "")
    }

    func testSaveAsReviewItem_includesNotesWhenPresent() async {
        let (vm, coordinator, _) = makeSUT()
        vm.ocrResult = OCRResult(question: "Q", answer: "A", notes: "N", confidence: 0.9)

        vm.saveAsReviewItem()

        guard case let .saveReviewItem(content: content)? = coordinator.lastDelegatedRoute else {
            return XCTFail("Expected navigation to saveReviewItem")
        }
        XCTAssertTrue(content.contains("备注：N"))
    }

    func testHandleSelectedImage_runsOCR_hidesPhotoLibrary_andNavigatesToSave() async {
        let (vm, coordinator, _) = makeSUT()
        let image = make1x1Image()

        let resultExpectation = expectation(description: "OCR result set and navigation triggered (selected image)")

        vm.$ocrResult
            .dropFirst()
            .sink { result in
                if result != nil {
                    resultExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When: present photo library then select an image
        vm.showPhotoLibraryView()
        XCTAssertTrue(vm.showPhotoLibrary)
        vm.handleSelectedImage(image)

        // Then
        await fulfillment(of: [resultExpectation], timeout: 5.0)
        XCTAssertFalse(vm.showPhotoLibrary)
        XCTAssertNotNil(vm.ocrResult)

        guard case let .saveReviewItem(content: content)? = coordinator.lastDelegatedRoute else {
            return XCTFail("Expected navigation to saveReviewItem after selecting image")
        }
        XCTAssertTrue(content.contains("题目："))
        XCTAssertTrue(content.contains("答案："))
    }

    func testSaveAsReviewItem_withEmptyNotes_doesNotIncludeNotesLine() async {
        let (vm, coordinator, _) = makeSUT()

        // Case 1: notes = nil
        vm.ocrResult = OCRResult(question: "Q1", answer: "A1", notes: nil, confidence: 0.9)
        vm.saveAsReviewItem()
        guard case let .saveReviewItem(content: content1)? = coordinator.lastDelegatedRoute else {
            return XCTFail("Expected navigation to saveReviewItem for notes=nil")
        }
        XCTAssertFalse(content1.contains("备注："))

        // Case 2: notes = "" (empty string)
        vm.ocrResult = OCRResult(question: "Q2", answer: "A2", notes: "", confidence: 0.9)
        vm.saveAsReviewItem()
        guard case let .saveReviewItem(content: content2)? = coordinator.lastDelegatedRoute else {
            return XCTFail("Expected navigation to saveReviewItem for notes=empty")
        }
        XCTAssertFalse(content2.contains("备注："))
    }
}

// MARK: - Mocks
@MainActor
private final class MockCaptureCoordinator: CaptureCoordinator {
    var lastDelegatedRoute: Route?

    override init() {
        super.init()
    }

    override func coordinate(to route: Route) {
        // Record the route and do not call super to avoid modifying navigationPath unnecessarily
        lastDelegatedRoute = route
        // If desired, we could emulate parts of real behavior, but not required for assertions here.
    }
}
