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
    @State private var tempFileURL: URL?
    @State private var showWriteError = false

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
                
                if let url = tempFileURL {
                    ToolbarItem(placement: .confirmationAction) {
                        ShareLink(item: url) {
                            Label(L10n.Library.shareOrPrint, systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .task {
                generatePDF()
            }
            .alert(L10n.Errors.exportFailed, isPresented: $showWriteError) {
                Button(L10n.Common.ok, role: .cancel) {}
            } message: {
                Text(L10n.Errors.exportWriteDetail)
            }
        }
    }
    
    private func generatePDF() {
        Task {
            do {
                let data = try await PDFExportService.shared.createPDF(from: items) { path in
                    return imageStorage.loadImage(path: path)
                }

                await MainActor.run {
                    self.pdfData = data
                    self.isLoading = false
                    saveToTemp(pdfData: data)
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
            self.tempFileURL = tempURL
        } catch {
            SnapDrillLogger.generic.error("PDF 临时文件写入失败: \(error.localizedDescription)")
            showWriteError = true
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
