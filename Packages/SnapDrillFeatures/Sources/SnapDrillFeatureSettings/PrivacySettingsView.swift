//
//  PrivacySettingsView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/01/02.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  隐私设置页面，管理数据收集与隐私选项。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData
import UniformTypeIdentifiers

/// 隐私设置页面
struct PrivacySettingsView: View {
    
    // MARK: - Properties
    
    @Environment(\.repositories) private var repositories
    @Environment(\.analyticsService) private var analyticsService
    @AppStorage(UDKey.analyticsEnabled) private var analyticsEnabled = false
    @AppStorage(UDKey.crashReportingEnabled) private var crashReportingEnabled = true
    
    @State private var showingExportOptions = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var exportTask: Task<Void, Never>?
    
    var body: some View {
        List {
            Section {
                Toggle(L10n.Settings.useAnalytics, isOn: $analyticsEnabled)
                Toggle(L10n.Settings.crashReporting, isOn: $crashReportingEnabled)
            } header: {
                Text(L10n.Settings.dataCollection)
            } footer: {
                Text(L10n.Settings.dataCollectionFooter)
            }
            
            Section {
                Button {
                    showingExportOptions = true
                } label: {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .controlSize(.small)
                            Text(L10n.Settings.exporting)
                                .foregroundStyle(.secondary)
                        } else {
                            // 省略 foregroundStyle 让系统 tint 色（蓝色）表达可点击语义
                            Text(L10n.Settings.exportMyData)
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .disabled(isExporting)
                // confirmationDialog 挂在 Button 上，确保锚点在触发元素附近
                .confirmationDialog(L10n.Settings.chooseExportFormat, isPresented: $showingExportOptions, titleVisibility: .visible) {
                    Button(L10n.Settings.jsonFormat) {
                        exportTask?.cancel()
                        exportTask = Task { await exportData(format: .json) }
                    }
                    Button(L10n.Settings.csvFormat) {
                        exportTask?.cancel()
                        exportTask = Task { await exportData(format: .csv) }
                    }
                    Button(L10n.Common.cancel, role: .cancel) {}
                }
            } header: {
                Text(L10n.Settings.dataManagement)
            } footer: {
                Text(L10n.Settings.exportDataFooter)
            }
            
            if let error = exportError {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.Settings.privacyAndSecurity)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
        }
        .onDisappear {
            exportTask?.cancel()
        }
    }
    
    // MARK: - Private Helpers
    
    private func exportData(format: PrivacyDataExportFormat) async {
        isExporting = true
        exportError = nil
        
        do {
            let items = try repositories.review.fetchAllModels()

            // Convert to Sendable value types before crossing actor boundary
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
            
            await MainActor.run {
                exportedFileURL = fileURL
                showingShareSheet = true
                isExporting = false
                analyticsService.track(.dataExported, parameters: [
                    "format": format.fileExtension,
                    "item_count": "\(exportableItems.count)"
                ])
            }
        } catch {
            await MainActor.run {
                exportError = L10n.Errors.exportFailed
                isExporting = false
            }
        }
    }
}

/// Sendable value type for export
struct ExportableItem: Sendable {
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
enum PrivacyDataExportFormat {
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
        
        // 保存到临时目录
        let fileName = "SnapDrill_Export_\(Date().formatted(date: .numeric, time: .omitted)).\(format.fileExtension)"
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
        var csv = "ID,内容,学科,来源,难度,答案,创建时间,上次复习,下次复习,标签\n"
        
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
    ///
    /// 对 `=`, `+`, `-`, `@` 开头的值添加 tab 前缀，阻止 Excel 解析为公式。
    /// 参考：OWASP CSV Injection Prevention Cheat Sheet
    private func escapeCSV(_ string: String) -> String {
        var value = string
        // Excel 公式注入防护：危险前缀加 tab 前缀使其成为纯文本
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

/// ShareSheet for UIKit integration
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}
