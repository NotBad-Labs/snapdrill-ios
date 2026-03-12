//
//  ExportPreviewView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  PDF 导出预览页，使用 PDFKit 渲染导出结果并提供分享/打印入口。
//

import SwiftUI
import PDFKit
import SnapDrillCore
import SnapDrillData

struct ExportPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    let items: [ReviewExportSnapshot]
    
    @State private var pdfData: Data?
    @State private var isLoading = true
    @State private var tempPDFURL: URL?
    @State private var showSaveError = false

    private let imageStorage = ImageStorage()
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView(L10n.Library.generating)
                } else if let pdfData = pdfData, let document = PDFDocument(data: pdfData) {
                    PDFKitRepresentedView(document: document)
                } else {
                    ContentUnavailableView(L10n.Library.generateFailed, systemImage: "exclamationmark.triangle")
                }
            }
            .navigationTitle(L10n.Library.exportPreview)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.close) { dismiss() }
                }
                
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
            .task {
                generatePDF()
            }
        }
    }
    
    private func generatePDF() {
        // Run in background
        Task {
            do {
                let data = try await PDFExportService.shared.createPDF(from: items) { path in
                    return imageStorage.loadImage(path: path)
                }
                
                await MainActor.run {
                    self.pdfData = data
                    self.isLoading = false
                    self.saveToTemp(pdfData: data)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func saveToTemp(pdfData: Data) {
        let fileName = "SnapDrill_Mistakes_\(Date().formatted(date: .numeric, time: .omitted)).pdf"
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
