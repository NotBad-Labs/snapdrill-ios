//
//  CaptureAndPhotoLibraryCoverageTests.swift
//  NotBadTests
//
//  Created by GitHub Copilot on 2025/09/23.
//

import XCTest
import SwiftUI
import UIKit
@testable import NotBad

@MainActor
final class CaptureAndPhotoLibraryCoverageTests: XCTestCase {

    // 通过 DEBUG 测试钩子直接覆盖 CameraView 内部处理路径
    func testCameraView_testHook_handleCapturedImage_processesImage() {
        // Given
        let coordinator = CaptureCoordinator()
        let vm = CaptureViewModel(
            captureUseCase: ServiceContainer.shared.captureReviewItemUseCase,
            coordinator: coordinator
        )
        vm.configure(errorHandler: AppEnvironment.createTestEnvironment().errorHandler)

        let view = CameraView(viewModel: vm)
        let hosting = UIHostingController(rootView: view)
        hosting.loadViewIfNeeded()

        // 制作一张小图片数据
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let uiImage = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
        guard let data = uiImage.pngData() else {
            XCTFail("Failed to create image data")
            return
        }

        // When: 通过测试钩子触发内部处理
        view._test_handleCapturedImage(data)

        // Then: 等待短暂时间以便异步 OCR 流程推进
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        XCTAssertNotNil(vm.capturedImage)
    }

    // 覆盖 PhotoLibraryView 的选择-处理路径与预览分支
    func testPhotoLibraryView_setsPreview_thenHandleSelectedImage_viaHooks() {
        // Given
        let coordinator = CaptureCoordinator()
        let vm = CaptureViewModel(
            captureUseCase: ServiceContainer.shared.captureReviewItemUseCase,
            coordinator: coordinator
        )
        vm.configure(errorHandler: AppEnvironment.createTestEnvironment().errorHandler)

        var sut = PhotoLibraryView(viewModel: vm)
        let hosting = UIHostingController(rootView: sut)
        hosting.loadViewIfNeeded()

        // 制作一张小图片数据
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 6, height: 6))
        let uiImage = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 6, height: 6))
        }
        guard let data = uiImage.pngData() else {
            XCTFail("Failed to create image data")
            return
        }

        // When: 先设置预览数据以覆盖 UI 分支，再触发处理
        sut._test_setSelectedImageData(data)
        sut._test_handleSelectedImage(data)

        // Then
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        XCTAssertNotNil(vm.capturedImage)
    }
}
