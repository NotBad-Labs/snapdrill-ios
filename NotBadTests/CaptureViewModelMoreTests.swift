//
//  CaptureViewModelMoreTests.swift
//  NotBadTests
//
//  Created by GitHub Copilot on 9/23/25.
//

import XCTest
import UIKit
import Combine
@testable import NotBad

@MainActor
final class CaptureViewModelMoreTests: XCTestCase {
    // MARK: - Mocks
    struct ThrowingOcr: OcrProcessing {
        enum MockError: Error { case failed }
        func process(_ image: UIImage) async throws -> OCRResult {
            throw MockError.failed
        }
    }

    // Helper: small 1x1 image
    private func makeDummyImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        return renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }

    func testProcessImage_errorPath_resetsState_andCallsErrorHandler() async {
        // Arrange
        let coordinator = CaptureCoordinator()
        let services = ServiceContainer.shared
        let errorHandler = AppErrorHandler()
        let vm = CaptureViewModel(
            captureUseCase: services.captureReviewItemUseCase,
            coordinator: coordinator,
            ocrProcessor: ThrowingOcr()
        )
        vm.configure(errorHandler: errorHandler)

        let exp = expectation(description: "error handled")
        var bag = Set<AnyCancellable>()
        // Observe published error; use Combine and fulfill when non-nil appears
        errorHandler.$currentError
            .dropFirst()
            .sink { err in
                if err != nil { exp.fulfill() }
            }
            .store(in: &bag)

        // Act
        vm.handleCapturedImage(makeDummyImage())

        // Assert
        await fulfillment(of: [exp], timeout: 3.0)
        XCTAssertFalse(vm.isProcessingOCR)
        XCTAssertEqual(vm.ocrProgress, 0.0, accuracy: 0.0001)
        XCTAssertNil(vm.ocrResult)
    }
}
