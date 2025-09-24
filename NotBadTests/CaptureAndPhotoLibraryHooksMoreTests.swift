//
//  CaptureAndPhotoLibraryHooksMoreTests.swift
//  NotBadTests
//
//  Created by GitHub Copilot on 2025/09/24.
//

import XCTest
import SwiftUI
import UIKit
@testable import NotBad

@MainActor
final class CaptureAndPhotoLibraryHooksMoreTests: XCTestCase {

    // 覆盖 CameraView 保存到相册的分支（权限通常未授权 -> 早退），确保路径可执行
    func testCameraView_saveToPhotoLibrary_hook_runsGuardPath() {
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

        // 制作一些任意数据（不要求是有效图片）
        let data = Data([0x00, 0x01, 0x02])

        // When & Then: 通过测试钩子调用，不崩溃即可
        view._test_saveImageToPhotoLibrary(data)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }

    // 使用无效图片数据走到 handleCapturedImage 的早退路径（UIImage(data:) 为 nil）
    func testCameraView_handleCapturedImage_withInvalidData_doesNotSetImage() {
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

        // 无效数据
        let invalidData = Data([0x00])

        // When
        view._test_handleCapturedImage(invalidData)

        // Then
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        XCTAssertNil(vm.capturedImage)
    }

    // 覆盖 PhotoLibraryView 的 handleSelectedImage 无效数据路径
    func testPhotoLibraryView_handleSelectedImage_withInvalidData_doesNotSetImage() {
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

        let invalidData = Data([0xFF])

        // When
        sut._test_handleSelectedImage(invalidData)

        // Then
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        XCTAssertNil(vm.capturedImage)
    }

    // 通过 Hook 先设置预览数据，再清空，覆盖预览/清空分支（无法直接读取私有状态，主要关注执行路径）
    func testPhotoLibraryView_setAndClearPreview_viaHook() {
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

        // 制作一张小图片数据作为预览
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        let uiImage = renderer.image { ctx in
            UIColor.green.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        let data = uiImage.pngData()

        // When: 先设置预览，再清空
        sut._test_setSelectedImageData(data)
        sut._test_setSelectedImageData(nil)

        // Then: 等待 UI 事件循环推进，不崩溃即可
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }
}
