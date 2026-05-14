//
//  DataExporter.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  数据导出器：JSON / CSV 格式导出。
//

import Foundation
import SnapDrillCore

/// 数据导出器
actor DataExporter {
    func export(items: [ExportableItem], format: PrivacyDataExportFormat) throws -> URL {
        let data: Data

        switch format {
        case .json:
            data = try exportJSON(items: items)
        case .csv:
            data = try exportCSV(items: items)
        }

        let fileName = "SnapDrill_Export_\(Date().filenameDateString).\(format.fileExtension)"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        try data.write(to: fileURL)
        return fileURL
    }

    private func exportJSON(items: [ExportableItem]) throws -> Data {
        let exportItems = items.map { item in
            [
                "id": item.id.uuidString,
                "content": item.content ?? "",
                "subject": item.subject,
                "source": item.source,
                "difficulty": item.difficulty,
                "answerText": item.answerText ?? "",
                "createdAt": item.createdAt.ISO8601Format(),
                "lastReviewedAt": item.lastReviewedAt?.ISO8601Format() ?? "",
                "nextReviewAt": item.nextReviewAt?.ISO8601Format() ?? "",
                "tags": item.tags.joined(separator: ", ")
            ] as [String: Any]
        }

        return try JSONSerialization.data(withJSONObject: exportItems, options: .prettyPrinted)
    }

    private func exportCSV(items: [ExportableItem]) throws -> Data {
        var csv = "ID,Content,Subject,Source,Difficulty,Answer,CreatedAt,LastReviewed,NextReview,Tags\n"

        for item in items {
            let row = [
                item.id.uuidString,
                escapeCSV(item.content ?? ""),
                escapeCSV(item.subject),
                escapeCSV(item.source),
                "\(item.difficulty)",
                escapeCSV(item.answerText ?? ""),
                item.createdAt.ISO8601Format(),
                item.lastReviewedAt?.ISO8601Format() ?? "",
                item.nextReviewAt?.ISO8601Format() ?? "",
                escapeCSV(item.tags.joined(separator: "; "))
            ].joined(separator: ",")

            csv += row + "\n"
        }

        guard let data = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }

        return data
    }

    /// CSV 转义 + Excel 公式注入防护
    private func escapeCSV(_ string: String) -> String {
        var value = string
        if let first = value.first, "=+\\-@".contains(first) {
            value = "\t" + value
        }
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}

enum ExportError: LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return L10n.Errors.encodingFailed
        }
    }
}
