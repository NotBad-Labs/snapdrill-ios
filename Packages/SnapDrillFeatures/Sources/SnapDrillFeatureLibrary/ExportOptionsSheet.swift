//
//  ExportOptionsSheet.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  导出选项配置页，允许用户选择要包含在 PDF 中的内容。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData

/// 导出选项面板
///
/// 提供多种导出格式选择，作为导出流程的起点。
struct ExportOptionsSheet: View {
    
    // MARK: - Properties
    
    let items: [ReviewExportSnapshot]
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingPDFPreview = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                Section(L10n.Library.exportTitle) {
                    // 1. PDF / Print
                    Button {
                        showingPDFPreview = true
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text(L10n.Library.exportPDF)
                                    .font(.headline)
                                Text(L10n.Library.exportPDFHint)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "printer.fill")
                                .foregroundStyle(.blue)
                                .font(.title2)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // 2. CSV (.csv)
                    ShareLink(
                        item: ReviewExport(items: items, format: .csv),
                        preview: SharePreview(L10n.Library.exportCSV, image: Image(systemName: "tablecells"))
                    ) {
                        Label {
                            VStack(alignment: .leading) {
                                Text(L10n.Library.exportCSV)
                                    .font(.headline)
                                Text(L10n.Library.exportCSVHint)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "tablecells")
                                .foregroundStyle(.green)
                                .font(.title2)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        Text(L10n.Common.itemCount(items.count))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle(L10n.Library.export)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.close) { dismiss() }
                }
            }
            .navigationDestination(isPresented: $showingPDFPreview) {
                ExportPreviewView(items: items)
            }
        }
    }
}

// MARK: - Transferable Export Model
import UniformTypeIdentifiers

struct ReviewExport: Transferable {
    let items: [ReviewExportSnapshot]
    let format: ExportFormat
    
    enum ExportFormat {
        case csv

        var contentType: UTType {
            switch self {
            case .csv: return .commaSeparatedText
            }
        }

        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            }
        }
    }
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .plainText) { export in
            let content = export.generateContent()
            return content.data(using: .utf8) ?? Data()
        }
        .suggestedFileName { export in
            "SnapDrill_Export_\(Date().filenameDateString).\(export.format.fileExtension)"
        }

        // Also support file URL export for apps that prefer files
        FileRepresentation(exportedContentType: .plainText) { export in
            let content = export.generateContent()
            let tempParams = try? FileManager.default.url(
                for: .itemReplacementDirectory,
                in: .userDomainMask,
                appropriateFor: URL(fileURLWithPath: ""),
                create: true
            )
            let tempDir = tempParams ?? FileManager.default.temporaryDirectory
            let fileName = "SnapDrill_Export_\(Date().filenameDateString).\(export.format.fileExtension)"
            let fileURL = tempDir.appendingPathComponent(fileName)
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return SentTransferredFile(fileURL)
        }
    }
    
    private func generateContent() -> String {
        switch format {
        case .csv:
            return generateCSV()
        }
    }

    private func generateCSV() -> String {
        var csv = "ID,Subject,Content,CreatedAt,Source\n"

        for item in items {
            let row = [
                item.id.uuidString,
                escapeCSVField(item.subject),
                escapeCSVField(item.content ?? ""),
                item.createdAt.description,
                escapeCSVField(item.source)
            ].joined(separator: ",")
            csv += row + "\n"
        }
        return csv
    }

    /// CSV 转义 + Excel 公式注入防护
    private func escapeCSVField(_ string: String) -> String {
        var value = string
        if let first = value.first, "=+\\-@".contains(first) {
            value = "\t" + value
        }
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}

#Preview {
    ExportOptionsSheet(items: [])
}
