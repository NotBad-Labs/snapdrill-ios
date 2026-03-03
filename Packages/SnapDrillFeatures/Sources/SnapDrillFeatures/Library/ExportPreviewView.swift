//
//  ExportPreviewView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  该文件已废弃，其功能已被 ResolvedExportSheet 替代。
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
    
    private let imageStorage = ImageStorage()
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("正在生成 PDF...")
                } else if let pdfData = pdfData, let document = PDFDocument(data: pdfData) {
                    PDFKitRepresentedView(document: document)
                } else {
                    ContentUnavailableView("生成失败", systemImage: "exclamationmark.triangle")
                }
            }
            .navigationTitle("导出预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                
                if let pdfData = pdfData {
                    ToolbarItem(placement: .confirmationAction) {
                        ShareLink(item: URL(fileURLWithPath: saveToTemp(pdfData: pdfData))) {
                            Label("分享/打印", systemImage: "square.and.arrow.up")
                        }
                    }
                }
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
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func saveToTemp(pdfData: Data) -> String {
        let fileName = "SnapDrill_Mistakes_\(Date().formatted(date: .numeric, time: .omitted)).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? pdfData.write(to: tempURL)
        return tempURL.path
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
