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
        auditManualCaptureEditor()
        auditLibraryDetailAndExportPreview()
        auditSmartPaperConfig()
        auditStoreRecovery()
        auditSymbolPicker()

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
            PrimaryTab(index: 3, screen: "Review Tab", root: "review.root"),
            PrimaryTab(index: 4, screen: "Settings Tab", root: "settings.root")
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

    private func auditManualCaptureEditor() {
        let app = launchApp()
        guard openPrimaryTab(index: 2, root: "capture.root", in: app) else {
            recordBlocked(screen: "Manual Capture Editor", reason: "capture.root did not appear.", app: app)
            app.terminate()
            return
        }

        let manualButton = app.buttons["capture.manual"]
        guard manualButton.waitForExistence(timeout: 5) else {
            recordBlocked(screen: "Manual Capture Editor", reason: "capture.manual did not appear.", app: app)
            app.terminate()
            return
        }
        manualButton.tap()

        if waitForElement("capture.result.root", in: app),
           waitForElement("capture.contentEditor", in: app) {
            recordAudit(screen: "Manual Capture Editor", rootIdentifier: "capture.result.root", app: app)
        } else {
            recordBlocked(
                screen: "Manual Capture Editor",
                reason: "Manual capture result editor did not appear.",
                app: app
            )
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

    private func auditSmartPaperConfig() {
        let app = launchApp()
        guard openPrimaryTab(index: 1, root: "library.root", in: app) else {
            recordBlocked(screen: "SmartPaper Config", reason: "library.root did not appear.", app: app)
            app.terminate()
            return
        }

        let smartPaperButton = app.buttons["library.smartPaperButton"]
        guard smartPaperButton.waitForExistence(timeout: 5) else {
            recordBlocked(screen: "SmartPaper Config", reason: "library.smartPaperButton did not appear.", app: app)
            app.terminate()
            return
        }
        smartPaperButton.tap()

        if waitForElement("smartPaper.root", in: app) {
            recordAudit(screen: "SmartPaper Config", rootIdentifier: "smartPaper.root", app: app)
        } else {
            recordBlocked(screen: "SmartPaper Config", reason: "smartPaper.root did not appear.", app: app)
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

    private func auditSymbolPicker() {
        let app = launchApp()
        guard openPrimaryTab(index: 4, root: "settings.root", in: app) else {
            recordBlocked(screen: "Symbol Picker", reason: "settings.root did not appear.", app: app)
            app.terminate()
            return
        }

        if let failureReason = openSymbolPicker(in: app) {
            recordBlocked(screen: "Symbol Picker", reason: failureReason, app: app)
            app.terminate()
            return
        }

        recordAudit(screen: "Symbol Picker", rootIdentifier: "symbolPicker.category.common", app: app)
        app.terminate()
    }
}
