//
//  CameraCoverageSmokeTests.swift
//  NotBadTests
//
//  Created by Copilot on 2025/09/23.
//

import XCTest
import SwiftUI
import UIKit
import AVFoundation
@testable import NotBad

@MainActor
final class CameraCoverageSmokeTests: XCTestCase {

    // 仅构建 CameraPreviewView 并触发布局，以覆盖 UIViewRepresentable 的 make/update 路径。
    func testCameraPreviewView_RendersWithEmptySession() {
        let session = AVCaptureSession()
        let view = CameraPreviewView(session: session)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    // 轻触 CameraManager 的初始化与权限拒绝分支（不实际启动会话）。
    func testCameraManager_InitAndToggleFlash_NoDeviceSafe() {
        let manager = CameraManager()

        // 不启动会话，直接调用切换手电（在无设备/无权限时，函数应安全返回）。
        manager.toggleFlashlight()

        // 断言对象已创建并且默认状态合理
        XCTAssertFalse(manager.isSessionRunning)
    }
}
