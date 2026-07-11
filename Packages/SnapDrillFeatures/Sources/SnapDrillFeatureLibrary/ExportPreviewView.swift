//
//  ExportPreviewView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  PDF 导出预览页，使用 PDFKit 渲染导出结果并提供分享/打印入口。
//

import SwiftUI
import PDFKit
import UIKit
import SnapDrillCore
import SnapDrillData
import SnapDrillUI

struct ExportPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    let items: [ArchiveExportSnapshot]
    var options: PDFExportOptions = .default
    var onExport: (() -> Void)?
    @Environment(\.analyticsService) private var analyticsService

    @State private var pdfData: Data?
    @State private var isLoading = true
    @State private var tempPDFURL: URL?
    @State private var showingShareSheet = false
    @State private var showGenerateError = false
    @State private var showPrintError = false
    @State private var isPrinting = false
    @State private var printAnchorView: UIView?

    @Environment(\.repositories) private var repositories
    @Environment(\.services) private var services
    @Environment(\.printPresenter) private var printPresenter
    private var imageStorage: ImageStorage { repositories.imageStorage }
    
    var body: some View {
        VStack {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text(L10n.Library.generating)
                        .font(.headline)
                    Text(L10n.Library.generatingHint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .accessible(label: L10n.Accessibility.generatingPDF)
            } else if let pdfData = pdfData, let document = PDFDocument(data: pdfData) {
                PDFKitRepresentedView(document: document)
                    .accessible(label: L10n.Accessibility.pdfPreviewLabel)
            } else {
                ContentUnavailableView {
                    Label(L10n.Library.generateFailed, systemImage: "exclamationmark.triangle")
                } description: {
                    Text(L10n.Errors.pdfGenerateFailed)
                } actions: {
                    Button(L10n.Common.retry) {
                        generatePDF()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .accessibilityIdentifier("library.exportPreview.root")
        .overlay {
            if isPrinting {
                VStack(spacing: 10) {
                    ProgressView()
                    Text(L10n.Library.preparingPrint)
                        .font(.subheadline.weight(.semibold))
                }
                .padding(16)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .navigationTitle(L10n.Library.exportPreview)
        .navigationBarTitleDisplayMode(.inline)
        .background {
            ExportPrintAnchorView { view in
                if printAnchorView !== view {
                    printAnchorView = view
                }
            }
            .frame(width: 0, height: 0)
        }
        .toolbar {
            ToolbarItemGroup(placement: .confirmationAction) {
                if let tempPDFURL {
                    if onExport == nil {
                        ShareLink(item: tempPDFURL) {
                            Label(L10n.Library.share, systemImage: "square.and.arrow.up")
                        }
                        .accessibilityIdentifier("library.exportPreview.share")
                    } else {
                        Button {
                            showingShareSheet = true
                        } label: {
                            Label(L10n.Library.share, systemImage: "square.and.arrow.up")
                        }
                        .accessibilityIdentifier("library.exportPreview.share")
                    }
                }

                if pdfData != nil {
                    Button {
                        printPDF()
                    } label: {
                        if isPrinting {
                            Label(L10n.Library.preparingPrint, systemImage: "printer")
                        } else {
                            Label(L10n.Library.printSingle, systemImage: "printer")
                        }
                    }
                    .disabled(isPrinting)
                }
            }
        }
        .alert(L10n.Errors.pdfGenerateFailed, isPresented: $showGenerateError) {
            Button(L10n.Common.retry) { generatePDF() }
            Button(L10n.Common.cancel, role: .cancel) { dismiss() }
        }
        .alert(L10n.Library.printFailed, isPresented: $showPrintError) {
            Button(L10n.Common.ok, role: .cancel) {}
        }
        .sheet(
            isPresented: $showingShareSheet,
            onDismiss: {
                showingShareSheet = false
            },
            content: {
                if let tempPDFURL, let onExport {
                    PDFActivityView(activityItems: [tempPDFURL]) { completed in
                        showingShareSheet = false
                        if completed {
                            onExport()
                        }
                    }
                }
            }
        )
        .task {
            generatePDF()
        }
    }
    
    private func generatePDF() {
        isLoading = true
        showGenerateError = false
        pdfData = nil
        tempPDFURL = nil

        // 在 MainActor 上下文中捕获，避免 Task 闭包中跨 actor 访问
        let storage = imageStorage
        // 经 ServiceContainer 注入，而非直调 PDFExportService.shared（DI 铁律）
        let pdfExport = services.pdfExport
        // 导出期间标记 .exporting，供应用级活动状态统一追踪
        let activityTracker = services.activityTracker
        // Run in background
        Task {
            activityTracker.begin(.exporting)
            defer { activityTracker.end(.exporting) }
            do {
                let data = try await pdfExport.createPDF(from: items, options: options) { path in
                    // autoreleasepool 确保每张图片渲染后立即释放，避免 50+ 题时 OOM
                    // 降采样到 1200px（A4 150dpi 足够），避免 12MB/张全分辨率位图堆积
                    return autoreleasepool {
                        storage.loadDownsampledImage(path: path, maxLongSide: 1200)
                    }
                }

                await MainActor.run {
                    // 临时文件没存好就不进预览——避免「看得到预览却被告知导出失败」的不连贯；
                    // 失败统一走与生成失败一致的错误路径（含重试）。
                    guard let tempURL = saveToTemp(pdfData: data) else {
                        self.isLoading = false
                        self.showGenerateError = true
                        return
                    }
                    self.tempPDFURL = tempURL
                    self.pdfData = data
                    self.isLoading = false
                    analyticsService.track(.pdfExported, parameters: [
                        "item_count": "\(items.count)"
                    ])
                }
            } catch {
                SnapDrillLogger.generic.error("PDF 生成失败: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                    self.showGenerateError = true
                }
            }
        }
    }
    
    /// 写入临时文件供分享/打印用；成功返回 URL，失败返回 nil（作为「不进预览」的判据）。
    private func saveToTemp(pdfData: Data) -> URL? {
        let fileName = "SnapDrill_Reference_Set_\(Date().filenameDateString).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try pdfData.write(to: tempURL)
            return tempURL
        } catch {
            SnapDrillLogger.generic.error("PDF 写入临时文件失败: \(error.localizedDescription)")
            return nil
        }
    }

    private func printPDF() {
        guard !isPrinting, let pdfData else { return }
        let activityTracker = services.activityTracker
        let presenter = printPresenter
        Task {
            isPrinting = true
            activityTracker.begin(.printing)
            defer {
                activityTracker.end(.printing)
                isPrinting = false
            }
            do {
                guard let printAnchorView else {
                    throw PrintError.presentationFailed
                }
                let outcome = try await presenter.present(
                    pdfData: pdfData,
                    jobName: L10n.Library.exportPreview,
                    anchor: .view(printAnchorView)
                )
                Self.notifyExportIfPrintCompleted(outcome, onExport: onExport)
            } catch {
                SnapDrillLogger.generic.error("PDF 打印失败: \(error.localizedDescription)")
                showPrintError = true
            }
        }
    }

    /// Maps the system print outcome to the export-consumption callback.
    ///
    /// This is intentionally tiny: SmartPaper free quota consumption is owned by
    /// `SmartPaperViewModel`; `ExportPreviewView` only reports a completed export.
    static func notifyExportIfPrintCompleted(_ outcome: PrintOutcome, onExport: (() -> Void)?) {
        guard outcome == .completed else { return }
        onExport?()
    }
}

private struct PDFActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let onComplete: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            DispatchQueue.main.async {
                onComplete(completed)
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct ExportPrintAnchorView: UIViewRepresentable {
    let onResolve: (UIView) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        resolve(view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        resolve(uiView)
    }

    private func resolve(_ view: UIView) {
        DispatchQueue.main.async {
            onResolve(view)
        }
    }
}

struct PDFKitRepresentedView: UIViewRepresentable {
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}

#Preview {
    ExportPreviewView(items: [])
}
