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
                "answerText": item.answerText ?? "",
                "createdAt": item.createdAt.ISO8601Format(),
                // A2 动态维度：维度名 → 值名数组
                "dimensions": item.dimensionValues
            ] as [String: Any]
        }

        return try JSONSerialization.data(withJSONObject: exportItems, options: .prettyPrinted)
    }

    private func exportCSV(items: [ExportableItem]) throws -> Data {
        // CSV 列 schema / 转义 / 公式注入防护统一由 ArchiveCSVCodec 提供（单一契约源）。
        guard let data = ArchiveCSVCodec.makeCSV(items).data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        return data
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
