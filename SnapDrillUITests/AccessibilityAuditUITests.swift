//
//  AccessibilityAuditUITests.swift
//  SnapDrillUITests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Enforced accessibility audit baseline.
//

import XCTest

@MainActor
final class AccessibilityAuditUITests: XCTestCase {

    static let reportFileName = "2026-07-05-ax-audit-baseline.md"
    static let assetDirectoryName = "2026-07-05-ax-audit-baseline"

    var results: [ScreenAuditResult] = []

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func testAccessibilityAuditBaselineReport() {
        prepareReportOutput()

        auditPrimaryTabs()
        auditCaptureResultEditor()
        auditLibraryDetailAndExportPreview()
        auditOnboarding()
        auditStoreRecovery()

        writeReport()
        assertAuditGateIsClean()
    }

    // MARK: - Screen Coverage

    private func auditPrimaryTabs() {
        let app = launchApp()
        guard app.tabBars.firstMatch.waitForExistence(timeout: 10) else {
            recordBlocked(
                screen: "Primary Tabs",
                reason: "Tab bar did not appear after launch.",
                app: app
            )
            app.terminate()
            return
        }

        let tabs = [
            PrimaryTab(index: 0, screen: "Dashboard Tab", root: "dashboard.root"),
            PrimaryTab(index: 1, screen: "Library Tab", root: "library.root"),
            PrimaryTab(index: 2, screen: "Capture Tab", root: "capture.root"),
            PrimaryTab(index: 3, screen: "Settings Tab", root: "settings.root")
        ]

        for tab in tabs {
            app.tabBars.buttons.element(boundBy: tab.index).tap()
            if waitForElement(tab.root, in: app) {
                recordAudit(screen: tab.screen, rootIdentifier: tab.root, app: app)
            } else {
                recordBlocked(screen: tab.screen, reason: "\(tab.root) did not appear.", app: app)
            }
        }

        app.terminate()
    }

    private func auditCaptureResultEditor() {
        let app = launchApp(extraArguments: ["--ui-test-capture-image-result"])
        guard app.tabBars.firstMatch.waitForExistence(timeout: 10) else {
            recordBlocked(screen: "Capture Result Editor", reason: "Tab bar did not appear.", app: app)
            app.terminate()
            return
        }
        app.tabBars.buttons.element(boundBy: 2).tap()

        if waitForElement("capture.result.root", in: app),
           waitForElement("capture.result.questionImage", in: app),
           waitForElement("capture.contentEditor", in: app) {
            recordAudit(screen: "Capture Result Editor", rootIdentifier: "capture.result.root", app: app)
        } else {
            recordBlocked(
                screen: "Capture Result Editor",
                reason: "Image-backed capture result editor did not appear.",
                app: app
            )
        }

        app.terminate()
    }

    private func auditOnboarding() {
        let app = launchOnboarding()
        guard waitForElement("onboarding.page.0", in: app, timeout: 10) else {
            recordBlocked(screen: "Onboarding", reason: "onboarding.page.0 did not appear.", app: app)
            app.terminate()
            return
        }

        for pageIndex in 0..<4 {
            let pageIdentifier = "onboarding.page.\(pageIndex)"
            guard waitForElement(pageIdentifier, in: app) else {
                recordBlocked(
                    screen: "Onboarding Page \(pageIndex + 1)",
                    reason: "\(pageIdentifier) did not appear.",
                    app: app
                )
                break
            }
            recordAudit(
                screen: "Onboarding Page \(pageIndex + 1)",
                rootIdentifier: pageIdentifier,
                app: app
            )
            if pageIndex < 3 {
                app.buttons["onboarding.next"].tap()
            }
        }

        app.terminate()
    }

    private func auditLibraryDetailAndExportPreview() {
        let app = launchApp(extraArguments: ["--ui-test-seed-image-library"])
        guard openSeededLibraryList(in: app) else {
            recordBlocked(screen: "Library Detail", reason: "Seeded image fixture did not appear.", app: app)
            recordBlocked(screen: "Export Preview", reason: "Seeded image fixture did not appear.", app: app)
            app.terminate()
            return
        }

        if openSeededLibraryDetail(in: app) {
            recordAudit(screen: "Library Detail", rootIdentifier: "library.detail.root", app: app)
        } else {
            recordBlocked(screen: "Library Detail", reason: "library.detail.root did not appear.", app: app)
            app.terminate()
            return
        }

        app.navigationBars.buttons.element(boundBy: 0).tap()
        if openSeededExportPreview(in: app) {
            recordAudit(screen: "Export Preview", rootIdentifier: "library.exportPreview.root", app: app)
        } else {
            recordBlocked(screen: "Export Preview", reason: "library.exportPreview.root did not appear.", app: app)
        }

        app.terminate()
    }

    private func auditStoreRecovery() {
        let app = launchApp(extraArguments: ["--ui-test-force-store-recovery"])
        if waitForElement("app.storeRecovery.root", in: app, timeout: 10) {
            recordAudit(screen: "Store Recovery", rootIdentifier: "app.storeRecovery.root", app: app)
        } else {
            recordBlocked(screen: "Store Recovery", reason: "app.storeRecovery.root did not appear.", app: app)
        }
        app.terminate()
    }

}
