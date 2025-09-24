//
//  CaptureViewUITests.swift
//  NotBadUITests
//
//  Created by Copilot on 2025/09/23.
//

import XCTest

final class CaptureViewUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testCaptureTabShowsKeyControls() {
        let captureTab = app.tabBars.buttons["拍照"]
        XCTAssertTrue(captureTab.waitForExistence(timeout: 5))
        captureTab.tap()
    XCTAssertTrue(app.otherElements["screen_capture"].waitForExistence(timeout: 3))

        // 页面标题与主要按钮文案
    XCTAssertTrue(app.staticTexts["拍照识别"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.buttons["capture_main_button"].exists)
    XCTAssertTrue(app.otherElements["capture_option_scan"].exists)
    XCTAssertTrue(app.otherElements["capture_option_library"].exists)

        // 可选：不触发实际相机系统弹窗，仅验证按钮存在
        // app.buttons["拍摄题目"].tap() // 如未来改为 Button，可考虑触发流程
    }
}
