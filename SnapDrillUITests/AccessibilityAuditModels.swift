//
//  AccessibilityAuditModels.swift
//  SnapDrillUITests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import XCTest

struct PrimaryTab {
    let index: Int
    let screen: String
    let root: String
}

struct ScreenAuditResult {
    let screen: String
    let status: String
    let rootIdentifier: String?
    let screenshotPath: String?
    let issues: [AuditIssueRecord]
    let blockedReason: String?

    static func audited(
        screen: String,
        rootIdentifier: String,
        issues: [AuditIssueRecord],
        _ screenshotPath: String?
    ) -> ScreenAuditResult {
        ScreenAuditResult(
            screen: screen,
            status: "PASS",
            rootIdentifier: rootIdentifier,
            screenshotPath: screenshotPath,
            issues: issues,
            blockedReason: nil
        )
    }

    static func blocked(
        screen: String,
        rootIdentifier: String? = nil,
        reason: String,
        _ screenshotPath: String?
    ) -> ScreenAuditResult {
        ScreenAuditResult(
            screen: screen,
            status: "BLOCKED",
            rootIdentifier: rootIdentifier,
            screenshotPath: screenshotPath,
            issues: [],
            blockedReason: reason
        )
    }
}

struct AuditIssueRecord {
    let type: String
    let element: String
    let compactDescription: String
    let detailedDescription: String

    var markdownRow: String {
        "| \(Self.escape(type)) | \(Self.escape(element)) | \(Self.escape(compactDescription)) | \(Self.escape(detailedDescription)) |  |"
    }

    static func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "|", with: "\\|")
    }
}

@MainActor
extension AccessibilityAuditUITests {

    static func auditTypeName(_ type: XCUIAccessibilityAuditType) -> String {
        var names: [String] = []
        if type.contains(.contrast) { names.append("contrast") }
        if type.contains(.elementDetection) { names.append("elementDetection") }
        if type.contains(.hitRegion) { names.append("hitRegion") }
        if type.contains(.sufficientElementDescription) {
            names.append("sufficientElementDescription")
        }
        if type.contains(.dynamicType) { names.append("dynamicType") }
        if type.contains(.textClipped) { names.append("textClipped") }
        if type.contains(.trait) { names.append("trait") }
        return names.isEmpty ? "raw:\(type.rawValue)" : names.joined(separator: "+")
    }

    static func describeElement(_ element: XCUIElement?) -> String {
        guard let element else { return "-" }
        var parts: [String] = [String(describing: element.elementType)]
        if !element.identifier.isEmpty {
            parts.append("id=\(element.identifier)")
        }
        if !element.label.isEmpty {
            parts.append("label=\(element.label)")
        }
        if let value = element.value as? String, !value.isEmpty {
            parts.append("value=\(value)")
        }
        return parts.joined(separator: "; ")
    }

    static func screenshotLink(_ path: String?) -> String {
        guard let path else { return "-" }
        return "[screenshot](\(path))"
    }

    static func escape(_ value: String) -> String {
        AuditIssueRecord.escape(value)
    }

    static func slug(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let scalars = value.lowercased().unicodeScalars.map { scalar -> Character in
            allowed.contains(scalar) ? Character(scalar) : "-"
        }
        return String(scalars).replacingOccurrences(of: "--", with: "-")
    }
}
