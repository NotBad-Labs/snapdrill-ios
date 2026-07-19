//
//  LibraryEditMetadataReadinessUITests.swift
//  SnapDrillUITests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import XCTest

@MainActor
final class LibraryEditMetadataReadinessUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMetadataLoadingDisablesSaveAndKeepsCancelAvailable() {
        let app = launchApp(behavior: "--ui-test-library-edit-metadata-loading")
        openSeededLibraryEdit(in: app)

        XCTAssertTrue(element("library.edit.metadataLoading", in: app).waitForExistence(timeout: 5))
        let save = app.buttons["library.edit.save"]
        XCTAssertTrue(save.exists)
        XCTAssertFalse(save.isEnabled)
        XCTAssertTrue(app.buttons["library.edit.cancel"].isHittable)
        XCTAssertFalse(element("library.edit.root", in: app).exists)
    }

    func testMetadataFailureRetriesToReady() {
        let app = launchApp(behavior: "--ui-test-library-edit-metadata-failure")
        openSeededLibraryEdit(in: app)

        XCTAssertTrue(element("library.edit.metadataError", in: app).waitForExistence(timeout: 5))
        let save = app.buttons["library.edit.save"]
        XCTAssertTrue(save.exists)
        XCTAssertFalse(save.isEnabled)
        XCTAssertTrue(app.buttons["library.edit.cancel"].isHittable)

        let retry = app.buttons["library.edit.metadataRetry"]
        XCTAssertTrue(retry.waitForExistence(timeout: 5))
        retry.tap()

        XCTAssertTrue(element("library.edit.root", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(save.isEnabled)
        XCTAssertFalse(retry.exists)
    }

    func testSlowInitialImageDoesNotHideReadyMetadata() {
        let app = launchApp(behavior: "--ui-test-library-edit-slow-image")
        openSeededLibraryEdit(in: app)

        XCTAssertTrue(element("library.edit.root", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(element("library.edit.questionImageLoading", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["library.edit.save"].isEnabled)
        XCTAssertFalse(element("library.edit.questionImage", in: app).exists)
        XCTAssertTrue(scrollToElement("capture.dimRow.分类", in: app))
    }

    func testMissingAnswerImageShowsRecoveryActions() {
        let app = launchApp(behavior: "--ui-test-library-edit-missing-answer")
        openSeededLibraryEdit(in: app)

        XCTAssertTrue(element("library.edit.root", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(scrollToElement("library.edit.answerImageError", in: app))
        XCTAssertTrue(app.buttons["library.edit.addAnswerImage"].exists)
        XCTAssertTrue(app.buttons["library.edit.removeAnswerImage"].exists)
        XCTAssertFalse(element("library.edit.answerImageLoading", in: app).exists)
    }

    private func launchApp(behavior: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "-hasCompletedOnboarding", "YES",
            "-tip.fieldConfig.v1.seen", "YES",
            "-tip.reviewSwipe.v1.seen", "YES",
            "-AppleLanguages", "(zh-Hans)",
            "-AppleLocale", "zh_CN",
            "--ui-test-seed-image-library",
            behavior
        ]
        app.launch()
        return app
    }

    private func openSeededLibraryEdit(in app: XCUIApplication) {
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        app.tabBars.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(element("library.root", in: app).waitForExistence(timeout: 8))

        let imageCell = app.cells.containing(.staticText, identifier: "Library Image Fixture").firstMatch
        XCTAssertTrue(imageCell.waitForExistence(timeout: 10))
        imageCell.tap()
        XCTAssertTrue(element("library.detail.root", in: app).waitForExistence(timeout: 8))
        app.buttons["library.detail.editButton"].tap()
    }

    private func scrollToElement(_ identifier: String, in app: XCUIApplication) -> Bool {
        let target = element(identifier, in: app)
        for _ in 0..<6 where !target.exists {
            app.swipeUp()
        }
        return target.waitForExistence(timeout: 5)
    }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
