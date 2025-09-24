//
//  LibraryViewUITests.swift
//  NotBadUITests
//
//  Created by Copilot on 2025/09/23.
//

import XCTest

final class LibraryViewUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testLibraryEmptyState() {
        let libraryTab = app.tabBars.buttons["题库"]
        XCTAssertTrue(libraryTab.waitForExistence(timeout: 5))
        libraryTab.tap()
    // 使用屏幕级标识符，提升定位稳定性
    XCTAssertTrue(app.otherElements["screen_library"].waitForExistence(timeout: 3))

        // 空态文案
    XCTAssertTrue(app.staticTexts["暂无题目"].waitForExistence(timeout: 3))
    // 或者使用空态标识符（两者至少其一存在）
    XCTAssertTrue(app.staticTexts["暂无题目"].exists || app.otherElements["library_empty_state"].exists)

        // 统计标题存在（不依赖具体数值）
    XCTAssertTrue(app.otherElements["library_stat_total"].exists)
    XCTAssertTrue(app.otherElements["library_stat_reviewed"].exists)
    XCTAssertTrue(app.otherElements["library_stat_pending"].exists)
    }
}
