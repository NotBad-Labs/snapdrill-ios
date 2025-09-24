//
//  ProfileNavigationUITests.swift
//  NotBadUITests
//
//  Created by Copilot on 2025/09/23.
//

import XCTest

final class ProfileNavigationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testProfileSettingsAndAboutNavigation() {
        let profileTab = app.tabBars.buttons["我的"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5))
        profileTab.tap()
    XCTAssertTrue(app.otherElements["screen_profile"].waitForExistence(timeout: 3))

        // 打开“关于我们”
    let aboutCell = app.otherElements["profile_menu_about"].firstMatch
    XCTAssertTrue(aboutCell.waitForExistence(timeout: 3))
    aboutCell.tap()
    XCTAssertTrue(app.otherElements["screen_profile_about"].waitForExistence(timeout: 3))

        // 返回并打开“应用设置”
        app.navigationBars.buttons.element(boundBy: 0).tap()
    XCTAssertTrue(app.otherElements["screen_profile"].waitForExistence(timeout: 3))

    let settingsCell = app.otherElements["profile_menu_settings"].firstMatch
    XCTAssertTrue(settingsCell.waitForExistence(timeout: 3))
    settingsCell.tap()
    XCTAssertTrue(app.otherElements["screen_profile_settings"].waitForExistence(timeout: 3))
    }
}
