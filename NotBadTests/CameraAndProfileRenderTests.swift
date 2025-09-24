// NotBadTests/CameraAndProfileRenderTests.swift
// Focus: Cover CameraPreviewView and CameraManager lightweight paths

import XCTest
import SwiftUI
import UIKit
import AVFoundation
@testable import NotBad

@MainActor
final class CameraAndProfileRenderTests: XCTestCase {

    func testCameraPreviewView_Renders() {
        let session = AVCaptureSession()
        let view = CameraPreviewView(session: session)
        let hosting = UIHostingController(rootView: AnyView(
            VStack { view }.frame(width: 200, height: 200)
        ))
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    func testCameraManager_InitAndToggleFlashlight_NoCrash() {
        // Constructing manager should not crash on simulator (no camera available)
        let manager = CameraManager()
        // Toggling flashlight on simulator should be a no-op and not crash
        manager.toggleFlashlight()
        // Basic sanity: session exists and is not running by default
        XCTAssertFalse(manager.isSessionRunning)
    }
}
