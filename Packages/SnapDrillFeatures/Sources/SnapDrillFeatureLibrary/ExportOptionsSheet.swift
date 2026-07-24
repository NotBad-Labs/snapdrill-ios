//
//  ExportOptionsSheet.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  导出选项配置页，允许用户选择要包含在 PDF 中的内容。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData
import SnapDrillUI

/// 导出选项面板
///
/// 提供多种导出格式选择，作为导出流程的起点。
struct ExportOptionsSheet: View {
    
    // MARK: - Properties
    
    let items: [ArchiveExportSnapshot]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.profileManager) private var profileManager
    @Environment(\.services) private var services
    private var imageStorage: ImageStorage { profileManager.activeImageStorage }

    @State private var showingPDFPreview = false
    @State private var hideAnswers = false
    @State private var showBlankAnswerArea = false
    @State private var showHeader = false
    @State private var itemsPerPage = 2
    @State private var isExportingZIP = false
    @State private var zipURL: URL?
    @State private var isShowingZIPShare = false
    @State private var showNoImagesAlert = false
    @State private var showExportError = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView {
                        Label(L10n.Library.noExportItems, systemImage: "square.and.arrow.up")
                    } description: {
                        Text(L10n.Library.noExportItemsHint)
                    }
                } else {
                    List {
                        Section(L10n.Library.exportTitle) {
                            // 1. PDF / Print
                            Button {
                                showingPDFPreview = true
                            } label: {
                                ExportOptionLabel(
                                    title: L10n.Library.exportPDF,
                                    subtitle: L10n.Library.exportPDFHint,
                                    systemImage: "printer.fill",
                                    tint: .blue
                                )
                            }
                            .accessibleButton(label: L10n.Library.exportPDF, hint: L10n.Accessibility.exportPDFHint)
                            .accessibilityIdentifier("library.export.pdf")

                            if LibraryReleaseSurface.exposesOptionalCapabilities {
                                // 2. CSV (.csv)
                                ShareLink(
                                    item: ReviewExport(items: items, format: .csv),
                                    preview: SharePreview(L10n.Library.exportCSV, image: Image(systemName: "tablecells"))
                                ) {
                                    ExportOptionLabel(
                                        title: L10n.Library.exportCSV,
                                        subtitle: L10n.Library.exportCSVHint,
                                        systemImage: "tablecells",
                                        tint: .green
                                    )
                                }
                                .accessibleButton(label: L10n.Library.exportCSV, hint: L10n.Accessibility.exportCSVHint)
                                .accessibilityIdentifier("library.export.csv")

                                // 3. 原图 ZIP
                                Button {
                                    exportImagesZIP()
                                } label: {
                                    ExportOptionLabel(
                                        title: L10n.Library.exportImages,
                                        subtitle: isExportingZIP ? L10n.Library.exportingImages : L10n.Library.exportImagesHint,
                                        systemImage: "photo.on.rectangle.angled",
                                        tint: .purple,
                                        isLoading: isExportingZIP
                                    )
                                }
                                .accessibilityIdentifier("library.export.zip")
                                .disabled(isExportingZIP)
                            }
                        }

                        Section(L10n.Export.pdfOptions) {
                            if LibraryReleaseSurface.exposesOptionalCapabilities {
                                Toggle(L10n.Export.hideAnswers, isOn: $hideAnswers)
                                    .accessibilityIdentifier("library.export.hideAnswers")
                                if hideAnswers {
                                    Toggle(L10n.Export.showBlankArea, isOn: $showBlankAnswerArea)
                                        .accessibilityIdentifier("library.export.showBlankAnswerArea")
                                }
                                Toggle(L10n.Export.showHeader, isOn: $showHeader)
                                    .accessibilityIdentifier("library.export.showHeader")
                            }
                            Picker(L10n.Export.itemsPerPage, selection: $itemsPerPage) {
                                Text("1").tag(1)
                                Text("2").tag(2)
                                Text("4").tag(4)
                            }
                            .accessibilityIdentifier("library.export.itemsPerPage")
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
                }
            }
            .accessibilityIdentifier("library.export.root")
            .navigationTitle(L10n.Library.export)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.close) { dismiss() }
                        .accessibilityIdentifier("library.export.close")
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
        let activityTracker = services.activityTracker
        let zipName = "SnapDrill_Images_\(Date().filenameDateString).zip"

        Task {
            activityTracker.begin(.exporting)
            defer {
                activityTracker.end(.exporting)
                isExportingZIP = false
            }
            do {
                let zipURL = try await Task.detached(priority: .userInitiated) {
                    let tempDir = FileManager.default.temporaryDirectory
                    let zipURL = tempDir.appendingPathComponent(zipName)

                    var entries: [ZIPFileEntry] = []
                    for (index, path) in imagePaths.enumerated() {
                        guard let fileURL = storage.imageFileURL(path: path) else {
                            continue
                        }
                        let fileName = "\(index + 1)_\(URL(fileURLWithPath: path).lastPathComponent)"
                        entries.append(ZIPFileEntry(path: fileName, fileURL: fileURL))
                    }

                    // 全部图片加载失败 → entries 为空，不打包空 ZIP 假装成功
                    guard !entries.isEmpty else {
                        throw ZIPExportError.noReadableImages
                    }

                    let archiver = ZIPArchiver()
                    try archiver.createArchive(fileEntries: entries, at: zipURL)
                    return zipURL
                }.value

                self.zipURL = zipURL
                self.isShowingZIPShare = true
            } catch {
                SnapDrillLogger.generic.error("ZIP 导出失败: \(error.localizedDescription)")
                self.showExportError = true
            }
        }
    }
}

private enum ZIPExportError: Error {
    case noReadableImages
}

private struct ExportOptionLabel: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    var isLoading = false

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            if isLoading {
                ProgressView()
            } else {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                    .font(.title2)
            }
        }
        .padding(.vertical, 8)
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
    let items: [ArchiveExportSnapshot]
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
            let tempDir: URL
            do {
                tempDir = try FileManager.default.url(
                    for: .itemReplacementDirectory,
                    in: .userDomainMask,
                    appropriateFor: URL(fileURLWithPath: ""),
                    create: true
                )
            } catch {
                SnapDrillLogger.generic.warning("获取 itemReplacementDirectory 失败，回退到 temporaryDirectory: \(error.localizedDescription)")
                tempDir = FileManager.default.temporaryDirectory
            }
            let fileName = "SnapDrill_Export_\(Date().filenameDateString).\(export.format.fileExtension)"
            let fileURL = tempDir.appendingPathComponent(fileName)
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return SentTransferredFile(fileURL)
        }
    }
    
    private func generateContent() -> String {
        switch format {
        case .csv:
            // CSV 列 schema / 转义 / 公式注入防护统一由 ReviewCSVCodec 提供（单一契约源）。
            return ReviewCSVCodec.makeCSV(items)
        }
    }
}

#if DEBUG
#Preview {
    ExportOptionsSheet(items: [])
        .environment(\.services, MockServiceContainer())
}
#endif
