//
//  CaptureDraftRecoveryUITests.swift
//  SnapDrillUITests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  End-to-end coverage for recoverable and corrupt Capture draft presentation.
//

import XCTest

@MainActor
final class CaptureDraftRecoveryUITests: XCTestCase {

    func testRecoverableDraftContinuesIntoEditor() {
        let app = launchApp(extraArgument: "--ui-test-capture-recoverable-draft")
        openCapture(in: app)

        let continueButton = app.buttons["capture.draft.continue"].firstMatch
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5), "可恢复草稿应提供继续编辑操作")
        XCTAssertTrue(app.buttons["capture.draft.discard"].firstMatch.exists, "可恢复草稿应允许用户放弃")
        assertAccessibilityAuditIsClean(in: app)
        continueButton.tap()

        let editor = app.textViews["capture.contentEditor"]
        XCTAssertTrue(
            app.descendants(matching: .any)["capture.result.root"].waitForExistence(timeout: 8),
            "继续恢复后应进入采集编辑页"
        )
        XCTAssertTrue(editor.waitForExistence(timeout: 3), "恢复后的正文编辑器应出现")
        XCTAssertEqual(editor.value as? String, "Recoverable Capture Draft")
    }

    func testCorruptDraftCanOnlyBeDiscarded() {
        let app = launchApp(extraArgument: "--ui-test-capture-corrupt-draft")
        openCapture(in: app)

        let discardButton = app.buttons["capture.draft.discard"].firstMatch
        XCTAssertTrue(discardButton.waitForExistence(timeout: 5), "损坏草稿应提供安全丢弃操作")
        XCTAssertFalse(app.buttons["capture.draft.continue"].firstMatch.exists, "损坏草稿不得进入编辑页")
        assertAccessibilityAuditIsClean(in: app)
        discardButton.tap()

        XCTAssertTrue(
            discardButton.waitForNonExistence(timeout: 5),
            "丢弃损坏草稿后提示应关闭"
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["capture.root"].exists,
            "丢弃损坏草稿后应留在采集页"
        )
    }

    private func launchApp(extraArgument: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            extraArgument,
            "-hasCompletedOnboarding", "YES",
            "-tip.fieldConfig.v1.seen", "YES",
            "-tip.reviewSwipe.v1.seen", "YES"
        ]
        app.launch()
        return app
    }

    private func openCapture(in app: XCUIApplication) {
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "主 Tab 应出现")
        app.tabBars.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["capture.root"].waitForExistence(timeout: 5),
            "采集页应出现"
        )
    }

    private func assertAccessibilityAuditIsClean(in app: XCUIApplication) {
        XCTAssertNoThrow(try app.performAccessibilityAudit(for: .all))
    }
}
