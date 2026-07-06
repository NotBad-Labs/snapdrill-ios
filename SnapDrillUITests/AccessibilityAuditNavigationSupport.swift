//
//  AccessibilityAuditNavigationSupport.swift
//  SnapDrillUITests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import XCTest

@MainActor
extension AccessibilityAuditUITests {

    func launchApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "-hasCompletedOnboarding", "YES",
            "-tip.fieldConfig.v1.seen", "YES",
            "-tip.reviewSwipe.v1.seen", "YES",
            "-AppleLanguages", "(zh-Hans)",
            "-AppleLocale", "zh_CN"
        ] + extraArguments
        app.launch()
        return app
    }

    func openPrimaryTab(index: Int, root: String, in app: XCUIApplication) -> Bool {
        guard app.tabBars.firstMatch.waitForExistence(timeout: 10) else {
            return false
        }
        app.tabBars.buttons.element(boundBy: index).tap()
        return waitForElement(root, in: app)
    }

    func openSeededLibraryList(in app: XCUIApplication) -> Bool {
        guard openPrimaryTab(index: 1, root: "library.root", in: app) else {
            return false
        }
        return app.staticTexts["Library Image Fixture"].waitForExistence(timeout: 10)
    }

    func openSeededLibraryDetail(in app: XCUIApplication) -> Bool {
        let imageCell = seededImageCell(in: app)
        guard imageCell.waitForExistence(timeout: 5) else {
            return false
        }
        imageCell.tap()
        return waitForElement("library.detail.root", in: app)
    }

    func openSeededExportPreview(in app: XCUIApplication) -> Bool {
        guard waitForElement("library.root", in: app) else {
            return false
        }

        let listCell = seededImageCell(in: app)
        guard listCell.waitForExistence(timeout: 5) else {
            return false
        }
        listCell.press(forDuration: 0.6)

        let exportButton = app.buttons["library.selection.export"]
        guard exportButton.waitForExistence(timeout: 5) else {
            return false
        }
        if !exportButton.isEnabled {
            listCell.tap()
        }
        guard exportButton.isEnabled else {
            return false
        }
        exportButton.tap()

        guard waitForElement("library.export.root", in: app) else {
            return false
        }
        app.buttons["library.export.pdf"].tap()
        guard waitForElement("library.exportPreview.root", in: app, timeout: 12) else {
            return false
        }
        _ = app.staticTexts["正在生成..."].waitForNonExistence(timeout: 12)
        return true
    }

    func openSymbolPicker(in app: XCUIApplication) -> Bool {
        let manageCategories = app.buttons["settings.manageCategories"]
        scrollUntilHittable(manageCategories, in: app, maxSwipes: 10)
        guard manageCategories.waitForExistence(timeout: 5) else {
            return false
        }
        manageCategories.tap()

        guard waitForElement("settings.categoryManager.root", in: app) else {
            return false
        }
        app.buttons["dim.row.category"].tap()
        guard waitForElement("dimValueList.root.category", in: app) else {
            return false
        }
        app.buttons["dimValue.资料"].tap()
        guard waitForElement("dimValueEdit.root", in: app) else {
            return false
        }
        app.buttons["dimValueEdit.iconPicker"].tap()
        return waitForElement("symbolPicker.category.common", in: app)
    }

    func waitForElement(
        _ identifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 8
    ) -> Bool {
        app.descendants(matching: .any)[identifier].waitForExistence(timeout: timeout)
    }

    func waitForUIAnimation(seconds: TimeInterval = 0.8) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        var swipes = 0
        while !element.isHittable && swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
    }

    private func seededImageCell(in app: XCUIApplication) -> XCUIElement {
        app.cells.containing(.staticText, identifier: "Library Image Fixture").firstMatch
    }
}
