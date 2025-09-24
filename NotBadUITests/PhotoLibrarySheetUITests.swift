//
//  PhotoLibrarySheetUITests.swift
//  NotBadUITests
//
//  Created by GitHub Copilot on 2025/09/23.
//

import XCTest

final class PhotoLibrarySheetUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testOpenPhotoLibrarySheet() {
        // 切到拍照 Tab
        let captureTab = app.tabBars.buttons["拍照"]
        XCTAssertTrue(captureTab.waitForExistence(timeout: 5))
        captureTab.tap()

        // 点击相册入口
        let libraryOption = app.otherElements["capture_option_library"]
        XCTAssertTrue(libraryOption.waitForExistence(timeout: 3))
        libraryOption.tap()

        // 期望出现照片库界面的一些元素（标题或按钮文案）
        // 注意：系统 PhotosPicker 可能限制可见元素；我们兜底用导航标题/按钮的文案
        let title = app.navigationBars.staticTexts["选择照片"]
        let chooseButton = app.buttons["选择照片"]
        let cancelButton = app.buttons["取消"]
        XCTAssertTrue(title.waitForExistence(timeout: 3) || chooseButton.waitForExistence(timeout: 3) || cancelButton.waitForExistence(timeout: 3))
    }
}
