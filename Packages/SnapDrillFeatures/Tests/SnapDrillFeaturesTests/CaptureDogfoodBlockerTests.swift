//
//  CaptureDogfoodBlockerTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Dogfood blocker regressions: continuous crop presentation and camera shutter guards.
//

import Testing
import UIKit
@testable import SnapDrillFeatureCapture

@Suite("Capture dogfood blocker regressions")
@MainActor
struct CaptureDogfoodBlockerTests {

    @Test("连续裁剪缺少相册原图时不呈现裁剪器")
    func continuousCropperRequiresOriginalAlbumImage() {
        #expect(ContinuousCropperPresentationPolicy.shouldPresent(originalAlbumImage: UIImage?.none) == false)
        #expect(ContinuousCropperPresentationPolicy.shouldPresent(originalAlbumImage: createTestImage()) == true)
    }

    @Test("相机会话未运行时 manager 快门早退不崩")
    func cameraSessionManagerSkipsCaptureWhenSessionIsNotRunning() {
        let manager = CameraSessionManager()

        #expect(manager.canCapturePhoto == false)
        manager.capturePhoto()
    }

    @Test("相机会话未运行时 UIKit 控制器快门早退不崩")
    func smartCameraViewControllerSkipsCaptureWhenSessionIsNotRunning() {
        let controller = SmartCameraViewController()
        controller.loadViewIfNeeded()

        controller.capturePhoto()
    }
}
