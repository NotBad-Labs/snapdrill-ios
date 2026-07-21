//
//  CaptureDraftRecoveryUITests.swift
//  SnapDrillUITests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import XCTest

@MainActor
final class CaptureDraftRecoveryUITests: XCTestCase {
    func testImageDraftSurvivesProcessTerminationAndRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = launchArguments(seedDraft: true)
        app.launch()
        openCaptureTab(in: app)

        let editor = app.textViews["capture.contentEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10), "Seeded draft editor should open")
        XCTAssertTrue(app.buttons["capture.image.crop"].exists, "Seeded draft must retain its image")

        app.terminate()
        app.launchArguments = launchArguments(seedDraft: false)
        app.launch()
        openCaptureTab(in: app)

        let continueButton = app.alerts.buttons["capture.draft.continue"].firstMatch
        XCTAssertTrue(
            continueButton.waitForExistence(timeout: 10),
            "Relaunch must offer the persisted draft"
        )
        continueButton.tap()

        XCTAssertTrue(editor.waitForExistence(timeout: 8), "Recovered editor should reopen")
        XCTAssertEqual(editor.value as? String, "Durable relaunch fixture")
        XCTAssertTrue(app.buttons["capture.image.crop"].exists, "Recovered draft must retain its image")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        let discardButton = app.alerts.buttons["capture.draft.discard"].firstMatch
        XCTAssertTrue(discardButton.waitForExistence(timeout: 8), "Cleanup prompt should reappear")
        discardButton.tap()
    }

    private func launchArguments(seedDraft: Bool) -> [String] {
        var arguments = [
            "--uitesting",
            "--ui-test-durable-capture-draft",
            "-hasCompletedOnboarding", "YES",
            "-tip.fieldConfig.v1.seen", "YES",
            "-tip.reviewSwipe.v1.seen", "YES"
        ]
        if seedDraft {
            arguments.append("--ui-test-seed-durable-capture-draft")
        }
        return arguments
    }

    private func openCaptureTab(in app: XCUIApplication) {
        let captureTab = app.tabBars.buttons.element(boundBy: 2)
        XCTAssertTrue(captureTab.waitForExistence(timeout: 8), "Capture tab should exist")
        captureTab.tap()
    }
}
