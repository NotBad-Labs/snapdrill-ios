//
//  MainTabNavigationUITests.swift
//  NotBadUITests
//
//  Created by Copilot on 9/22/25.
//

import XCTest

final class MainTabNavigationUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testSwitchingTabsShowsExpectedTitles() throws {
        // Wait for Home tab to appear (Chinese label "首页")
        let homeTab = app.tabBars.buttons["首页"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5), "Home tab should exist")

        // Validate home title
        XCTAssertTrue(app.navigationBars["首页"].waitForExistence(timeout: 3))

        // Library
        app.tabBars.buttons["题库"].tap()
        XCTAssertTrue(app.navigationBars["题库"].waitForExistence(timeout: 3))

        // Capture
        app.tabBars.buttons["拍照"].tap()
        XCTAssertTrue(app.navigationBars["拍照"].waitForExistence(timeout: 3))

        // Discovery
        app.tabBars.buttons["发现"].tap()
        XCTAssertTrue(app.navigationBars["发现"].waitForExistence(timeout: 3))

        // Profile
        app.tabBars.buttons["我的"].tap()
        XCTAssertTrue(app.navigationBars["我的"].waitForExistence(timeout: 3))
    }
}
