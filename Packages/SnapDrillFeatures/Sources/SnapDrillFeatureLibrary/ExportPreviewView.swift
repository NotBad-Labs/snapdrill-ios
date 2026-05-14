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
import SnapDrillCore
import SnapDrillData
import SnapDrillUI

struct ExportPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    let items: [ReviewExportSnapshot]
    var options: PDFExportOptions = .default
    @Environment(\.analyticsService) private var analyticsService

    @State private var pdfData: Data?
    @State private var isLoading = true
    @State private var tempPDFURL: URL?
    @State private var showSaveError = false
    @State private var showGenerateError = false

    @Environment(\.profileManager) private var profileManager
    private var imageStorage: ImageStorage { profileManager.activeImageStorage }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView(L10n.Library.generating)
                    .accessible(label: L10n.Accessibility.generatingPDF)
            } else if let pdfData = pdfData, let document = PDFDocument(data: pdfData) {
                PDFKitRepresentedView(document: document)
                    .accessible(label: L10n.Accessibility.pdfPreviewLabel)
            } else {
                ContentUnavailableView(L10n.Library.generateFailed, systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle(L10n.Library.exportPreview)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let tempPDFURL {
                ToolbarItem(placement: .confirmationAction) {
                    ShareLink(item: tempPDFURL) {
                        Label(L10n.Library.shareOrPrint, systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .alert(L10n.Errors.exportFailed, isPresented: $showSaveError) {
            Button(L10n.Common.ok, role: .cancel) {}
        }
        .alert(L10n.Errors.pdfGenerateFailed, isPresented: $showGenerateError) {
            Button(L10n.Common.retry) { generatePDF() }
            Button(L10n.Common.cancel, role: .cancel) { dismiss() }
        }
        .task {
            generatePDF()
        }
    }
    
    private func generatePDF() {
        // 在 MainActor 上下文中捕获，避免 Task 闭包中跨 actor 访问
        let storage = imageStorage
        // Run in background
        Task {
            do {
                let data = try await PDFExportService.shared.createPDF(from: items, options: options) { path in
                    // autoreleasepool 确保每张图片渲染后立即释放，避免 50+ 题时 OOM
                    // 降采样到 1200px（A4 150dpi 足够），避免 12MB/张全分辨率位图堆积
                    return autoreleasepool {
                        storage.loadDownsampledImage(path: path, maxLongSide: 1200)
                    }
                }
                
                await MainActor.run {
                    self.pdfData = data
                    self.isLoading = false
                    self.saveToTemp(pdfData: data)
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
    
    private func saveToTemp(pdfData: Data) {
        let fileName = "SnapDrill_Mistakes_\(Date().filenameDateString).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try pdfData.write(to: tempURL)
            self.tempPDFURL = tempURL
        } catch {
            SnapDrillLogger.generic.error("PDF 写入临时文件失败: \(error.localizedDescription)")
            self.showSaveError = true
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
