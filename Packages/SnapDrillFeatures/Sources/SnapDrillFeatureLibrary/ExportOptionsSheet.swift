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
import ZIPFoundation
import SnapDrillCore
import SnapDrillData
import SnapDrillUI

/// 导出选项面板
///
/// 提供多种导出格式选择，作为导出流程的起点。
struct ExportOptionsSheet: View {
    
    // MARK: - Properties
    
    let items: [ReviewExportSnapshot]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.profileManager) private var profileManager
    private var imageStorage: ImageStorage { profileManager.activeImageStorage }

    @State private var showingPDFPreview = false
    @State private var hideAnswers = true
    @State private var showBlankAnswerArea = true
    @State private var showHeader = true
    @State private var itemsPerPage = 2
    @State private var isExportingZIP = false
    @State private var zipURL: URL?
    @State private var isShowingZIPShare = false
    @State private var showNoImagesAlert = false
    @State private var showExportError = false

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
                    .accessibleButton(label: L10n.Library.exportPDF, hint: L10n.Accessibility.exportPDFHint)
                    
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
                    .accessibleButton(label: L10n.Library.exportCSV, hint: L10n.Accessibility.exportCSVHint)

                    // 3. 原图 ZIP
                    Button {
                        exportImagesZIP()
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text(L10n.Library.exportImages)
                                    .font(.headline)
                                Text(L10n.Library.exportImagesHint)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            if isExportingZIP {
                                ProgressView()
                            } else {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .foregroundStyle(.purple)
                                    .font(.title2)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .disabled(isExportingZIP)
                }
                
                Section(L10n.Export.pdfOptions) {
                    Toggle(L10n.Export.hideAnswers, isOn: $hideAnswers)
                    if hideAnswers {
                        Toggle(L10n.Export.showBlankArea, isOn: $showBlankAnswerArea)
                    }
                    Toggle(L10n.Export.showHeader, isOn: $showHeader)
                    Picker(L10n.Export.itemsPerPage, selection: $itemsPerPage) {
                        Text("1").tag(1)
                        Text("2").tag(2)
                        Text("4").tag(4)
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
            .sheet(isPresented: $isShowingZIPShare) {
                if let url = zipURL {
                    ZIPShareSheet(activityItems: [url])
                }
            }
            .alert(L10n.Library.noImages, isPresented: $showNoImagesAlert) {
                Button(L10n.Common.close, role: .cancel) { }
            }
            .alert(L10n.Errors.exportFailed, isPresented: $showExportError) {
                Button(L10n.Common.close, role: .cancel) { }
            }
            .navigationDestination(isPresented: $showingPDFPreview) {
                ExportPreviewView(
                    items: items,
                    options: PDFExportOptions(
                        hideAnswers: hideAnswers,
                        showBlankAnswerArea: showBlankAnswerArea,
                        showHeader: showHeader,
                        itemsPerPage: itemsPerPage
                    )
                )
            }
        }
    }

    // MARK: - ZIP 导出

    private func exportImagesZIP() {
        let imagePaths = items.compactMap(\.imagePath)
        guard !imagePaths.isEmpty else {
            showNoImagesAlert = true
            return
        }

        isExportingZIP = true
        let storage = imageStorage

        Task.detached {
            do {
                let tempDir = FileManager.default.temporaryDirectory
                let zipName = "SnapDrill_Images_\(Date().filenameDateString).zip"
                let zipURL = tempDir.appendingPathComponent(zipName)

                // 如果已有同名文件则先清理
                try? FileManager.default.removeItem(at: zipURL)

                let archive = try Archive(url: zipURL, accessMode: .create)

                for (index, path) in imagePaths.enumerated() {
                    try autoreleasepool {
                        guard let image = storage.loadImage(path: path),
                              let data = image.jpegData(compressionQuality: 0.9) else {
                            return
                        }
                        let fileName = "\(index + 1)_\(URL(fileURLWithPath: path).lastPathComponent)"
                        try archive.addEntry(
                            with: fileName,
                            type: .file,
                            uncompressedSize: Int64(data.count),
                            compressionMethod: .deflate,
                            provider: { position, size in
                                data[Int(position) ..< Int(position) + size]
                            }
                        )
                    }
                }

                await MainActor.run {
                    self.zipURL = zipURL
                    self.isExportingZIP = false
                    self.isShowingZIPShare = true
                }
            } catch {
                SnapDrillLogger.generic.error("ZIP 导出失败: \(error.localizedDescription)")
                await MainActor.run {
                    self.isExportingZIP = false
                    self.showExportError = true
                }
            }
        }
    }
}

/// ZIP 分享的 UIKit 桥接
private struct ZIPShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
        var csv = "ID,Content,Subject,Source,Difficulty,Answer,CreatedAt,LastReviewed,NextReview,Tags\n"

        for item in items {
            let row = [
                item.id.uuidString,
                escapeCSVField(item.content ?? ""),
                escapeCSVField(item.subject),
                escapeCSVField(item.source),
                "\(item.difficulty)",
                escapeCSVField(item.answerText ?? ""),
                item.createdAt.ISO8601Format(),
                item.lastReviewedAt?.ISO8601Format() ?? "",
                item.nextReviewAt?.ISO8601Format() ?? "",
                escapeCSVField(item.tags.joined(separator: "; "))
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
