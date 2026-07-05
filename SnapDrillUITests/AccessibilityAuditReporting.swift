//
//  AccessibilityAuditReporting.swift
//  SnapDrillUITests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import XCTest

@MainActor
extension AccessibilityAuditUITests {

    func recordAudit(screen: String, rootIdentifier: String, app: XCUIApplication) {
        waitForUIAnimation()
        let screenshotPath = saveScreenshot(screen: screen)
        var issues: [AuditIssueRecord] = []

        do {
            try app.performAccessibilityAudit(for: .all) { issue in
                issues.append(
                    AuditIssueRecord(
                        type: Self.auditTypeName(issue.auditType),
                        element: Self.describeElement(issue.element),
                        compactDescription: issue.compactDescription,
                        detailedDescription: issue.detailedDescription
                    )
                )
                // Report mode: collect the issue but do not fail this baseline test.
                return true
            }
            results.append(.audited(screen: screen, rootIdentifier: rootIdentifier, issues: issues, screenshotPath))
        } catch {
            results.append(
                .blocked(
                    screen: screen,
                    rootIdentifier: rootIdentifier,
                    reason: "performAccessibilityAudit threw: \(error.localizedDescription)",
                    screenshotPath
                )
            )
        }
    }

    func recordBlocked(screen: String, reason: String, app: XCUIApplication) {
        waitForUIAnimation(seconds: 0.3)
        let screenshotPath = app.exists ? saveScreenshot(screen: screen) : nil
        results.append(.blocked(screen: screen, reason: reason, screenshotPath))
    }

    func writeReport() {
        let reportURL = reportDirectory().appendingPathComponent(Self.reportFileName)
        let report = makeReport()
        do {
            try FileManager.default.createDirectory(at: reportDirectory(), withIntermediateDirectories: true)
            try report.write(to: reportURL, atomically: true, encoding: .utf8)
            attachReport(report, name: Self.reportFileName)
        } catch {
            attachReport("Failed to write AX audit report: \(error)\n\n\(report)", name: "ax-audit-report-write-failed")
        }
    }

    func prepareReportOutput() {
        let fileManager = FileManager.default
        let reportDirectory = reportDirectory()
        let assetDirectory = assetDirectory()
        try? fileManager.createDirectory(at: reportDirectory, withIntermediateDirectories: true)
        try? fileManager.removeItem(at: reportDirectory.appendingPathComponent(Self.reportFileName))
        try? fileManager.removeItem(at: assetDirectory)
        try? fileManager.createDirectory(at: assetDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Report Sections

    private func makeReport() -> String {
        var lines = reportHeader()
        appendScreenSummary(to: &lines)
        appendIssueDistribution(to: &lines)
        appendScreenDetails(to: &lines)
        appendGateGuidance(to: &lines)
        return lines.joined(separator: "\n") + "\n"
    }

    private func reportHeader() -> [String] {
        let passedScreens = results.filter { $0.status == "PASS" }.count
        let blockedScreens = results.filter { $0.status == "BLOCKED" }.count
        let totalIssues = results.reduce(0) { $0 + $1.issues.count }

        return [
            "# SnapDrill Accessibility Audit Baseline",
            "",
            "- Date: 2026-07-05",
            "- Mode: report-only; audit issues are collected, not treated as test failures.",
            "- Scope: iOS Simulator UI audit for primary tabs and critical deep screens.",
            "- Coverage: \(results.count) screens (\(passedScreens) audited, \(blockedScreens) blocked), \(totalIssues) issues recorded.",
            "- Out of scope: system share/file panels, real-device camera/OCR/printing, manual HIG judgement."
        ]
    }

    private func appendScreenSummary(to lines: inout [String]) {
        lines.append(contentsOf: [
            "",
            "## Screen Summary",
            "",
            "| Screen | Status | Issues | Screenshot | PO 分级 |",
            "|---|---:|---:|---|---|"
        ])

        for result in results {
            lines.append(
                "| \(Self.escape(result.screen)) | \(result.status) | \(result.issues.count) | \(Self.screenshotLink(result.screenshotPath)) |  |"
            )
        }
    }

    private func appendIssueDistribution(to lines: inout [String]) {
        let issueCounts = Dictionary(grouping: results.flatMap(\.issues), by: \.type)
            .mapValues(\.count)
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key < rhs.key }
                return lhs.value > rhs.value
            }

        lines.append(contentsOf: [
            "",
            "## Issue Distribution",
            "",
            "| Type | Count |",
            "|---|---:|"
        ])
        if issueCounts.isEmpty {
            lines.append("| None | 0 |")
        } else {
            for (type, count) in issueCounts {
                lines.append("| \(Self.escape(type)) | \(count) |")
            }
        }
    }

    private func appendScreenDetails(to lines: inout [String]) {
        lines.append(contentsOf: ["", "## Screen Details"])
        for result in results {
            appendDetailHeader(for: result, to: &lines)
            appendIssueRows(for: result, to: &lines)
        }
    }

    private func appendDetailHeader(for result: ScreenAuditResult, to lines: inout [String]) {
        lines.append(contentsOf: [
            "",
            "### \(result.screen)",
            "",
            "- Status: \(result.status)",
            "- Root identifier: \(result.rootIdentifier ?? "-")",
            "- Screenshot: \(Self.screenshotLink(result.screenshotPath))"
        ])
        if let reason = result.blockedReason {
            lines.append("- Blocked reason: \(Self.escape(reason))")
        }
    }

    private func appendIssueRows(for result: ScreenAuditResult, to lines: inout [String]) {
        lines.append(contentsOf: [
            "",
            "| Type | Element | Compact description | Detail | PO 分级 |",
            "|---|---|---|---|---|"
        ])
        if result.issues.isEmpty {
            lines.append("| None | - | - | - |  |")
        } else {
            for issue in result.issues {
                lines.append(issue.markdownRow)
            }
        }
    }

    private func appendGateGuidance(to lines: inout [String]) {
        lines.append(contentsOf: [
            "",
            "## Gate Guidance",
            "",
            "- Screens with zero issues can be considered candidates for future enforced audit gates after PO review.",
            "- Screens with issues remain report-only until Q2/Q3 triage assigns severity and fixes.",
            "- BLOCKED screens require navigation/API investigation before they can become gates."
        ])
    }

    // MARK: - Files and Attachments

    private func saveScreenshot(screen: String) -> String? {
        let screenshot = XCUIScreen.main.screenshot()
        let sanitized = Self.slug(screen)
        let fileURL = assetDirectory().appendingPathComponent("\(sanitized).png")
        do {
            try screenshot.pngRepresentation.write(to: fileURL)
            attachScreenshot(screenshot, name: "ax-audit-\(sanitized)")
            return fileURL.path
        } catch {
            attachScreenshot(screenshot, name: "ax-audit-\(sanitized)-write-failed")
            return nil
        }
    }

    private func reportDirectory() -> URL {
        if let override = ProcessInfo.processInfo.environment["SNAPDRILL_AX_AUDIT_REPORT_DIR"],
           !override.isEmpty {
            return URL(fileURLWithPath: override)
        }

        let localDeveloperDirectory = "/Users/yiming/Developer"
        if FileManager.default.fileExists(atPath: localDeveloperDirectory) {
            return URL(fileURLWithPath: localDeveloperDirectory)
                .appendingPathComponent("snapdrill-agent-reports")
        }

        return URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("snapdrill-agent-reports")
    }

    private func assetDirectory() -> URL {
        reportDirectory()
            .appendingPathComponent("assets")
            .appendingPathComponent(Self.assetDirectoryName)
    }

    private func attachScreenshot(_ screenshot: XCUIScreenshot, name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func attachReport(_ report: String, name: String) {
        let attachment = XCTAttachment(string: report)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
