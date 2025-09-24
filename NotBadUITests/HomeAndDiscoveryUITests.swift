//
//  HomeAndDiscoveryUITests.swift
//  NotBadUITests
//
//  Created by Copilot on 2025/09/23.
//

import XCTest

final class HomeAndDiscoveryUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testHomeRendersSections() {
        // 默认启动在首页，校验标题与几个关键分区文本
        XCTAssertTrue(app.navigationBars["首页"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["学习统计"].exists)
        XCTAssertTrue(app.staticTexts["最近活动"].exists)
    }

    func testDiscoveryRendersCards() {
        // 切换到“发现”标签，验证卡片标题存在
        let discoveryTab = app.tabBars.buttons["发现"]
        XCTAssertTrue(discoveryTab.waitForExistence(timeout: 5))
        discoveryTab.tap()
        XCTAssertTrue(app.navigationBars["发现"].waitForExistence(timeout: 3))

        // 简单断言若干卡片标题存在
        XCTAssertTrue(app.staticTexts["智能分析"].exists)
        XCTAssertTrue(app.staticTexts["学习统计"].exists)
        XCTAssertTrue(app.staticTexts["定时练习"].exists)
        XCTAssertTrue(app.staticTexts["学习小组"].exists)
    }
}
