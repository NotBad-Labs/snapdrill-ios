//
//  PrivacySettingsViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/04/02.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  隐私设置 ViewModel，管理数据导出逻辑。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData
import UniformTypeIdentifiers

/// 隐私设置 ViewModel
///
/// 将数据导出逻辑从 View 层移出，遵循 architecture 铁律：
/// View 不直接访问 Repository，必须通过 ViewModel。
@Observable
final class PrivacySettingsViewModel {

    // MARK: - Published State

    var isExporting = false
    var exportError: String?
    var exportedFileURL: URL?
    var showingShareSheet = false

    // MARK: - Dependencies

    private let repositories: RepositoryContainer
    private let analyticsService: AnalyticsServiceProtocol

    // MARK: - Task Management

    @ObservationIgnored
    private var exportTask: Task<Void, Never>?

    // MARK: - Init

    /// - Parameters:
    ///   - repositories: 数据仓库容器
    ///   - analyticsService: 埋点服务
    init(
        repositories: RepositoryContainer,
        analyticsService: AnalyticsServiceProtocol
    ) {
        self.repositories = repositories
        self.analyticsService = analyticsService
    }

    // MARK: - Actions

    /// 触发数据导出
    func startExport(format: PrivacyDataExportFormat) {
        exportTask?.cancel()
        exportTask = Task { await exportData(format: format) }
    }

    /// 取消进行中的导出
    func cancelExport() {
        exportTask?.cancel()
    }

    // MARK: - Private

    private func exportData(format: PrivacyDataExportFormat) async {
        AppActivityTracker.shared.begin(.exporting)
        defer { AppActivityTracker.shared.end(.exporting) }
        isExporting = true
        exportError = nil

        do {
            let items = try repositories.review.fetchAllModels()
            guard !Task.isCancelled else {
                isExporting = false
                return
            }

            // 跨 actor 边界前转换为 Sendable 值类型
            let exportableItems = items.map { item in
                ExportableItem(
                    id: item.id,
                    content: item.content,
                    subject: item.subject,
                    source: item.source,
                    difficulty: item.difficulty,
                    answerText: item.answerText,
                    createdAt: item.createdAt,
                    lastReviewedAt: item.lastReviewedAt,
                    nextReviewAt: item.nextReviewAt,
                    tags: (item.tags ?? []).map { $0.name }
                )
            }

            let exporter = DataExporter()
            let fileURL = try await exporter.export(items: exportableItems, format: format)
            guard !Task.isCancelled else {
                try? FileManager.default.removeItem(at: fileURL) // best-effort: 清理已生成但不需要的文件
                isExporting = false
                return
            }

            exportedFileURL = fileURL
            showingShareSheet = true
            isExporting = false
            analyticsService.track(.dataExported, parameters: [
                "format": format.fileExtension,
                "item_count": "\(exportableItems.count)"
            ])
        } catch {
            if !Task.isCancelled {
                exportError = L10n.Errors.exportFailed
            }
            isExporting = false
        }
    }
}

// MARK: - Supporting Types

/// 导出专用的 Sendable 值类型
nonisolated struct ExportableItem: Sendable {
    let id: UUID
    let content: String?
    let subject: String
    let source: String
    let difficulty: Int
    let answerText: String?
    let createdAt: Date
    let lastReviewedAt: Date?
    let nextReviewAt: Date?
    let tags: [String]
}

/// 隐私数据导出格式（区别于题库导出的 ReviewExport.ExportFormat）
nonisolated enum PrivacyDataExportFormat {
    case json
    case csv

    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        }
    }

    var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        }
    }
}

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

/// UIKit 分享面板桥接
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
