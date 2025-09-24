//
//  CameraViewRenderTests.swift
//  NotBadTests
//
//  Created by GitHub Copilot on 2025/09/23.
//

import XCTest
import SwiftUI
import UIKit
@testable import NotBad

@MainActor
final class CameraViewRenderTests: XCTestCase {

    // 渲染 CameraView 并触发 onAppear 路径（权限回调可能为拒绝，但不应导致崩溃）
    func testCameraView_Renders_NoCrash_onAppear() {
        // Given
        let coordinator = CaptureCoordinator()
        let vm = CaptureViewModel(
            captureUseCase: ServiceContainer.shared.captureReviewItemUseCase,
            coordinator: coordinator
        )
        // 配置错误处理器，避免可选依赖为空
        vm.configure(errorHandler: AppEnvironment.createTestEnvironment().errorHandler)

        let view = CameraView(viewModel: vm)
        let hosting = UIHostingController(rootView: view)

        // When: 触发视图加载与 onAppear
        hosting.loadViewIfNeeded()

        // Then: 布局并简单等待片刻让 onAppear 的异步路径有机会执行
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }
}
