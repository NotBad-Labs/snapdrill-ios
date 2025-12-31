//
//  ExportPreviewView.swift
//  NotBadFeatures
//
//  Created by NotBad Architect on 2025/12/31.
//

import SwiftUI
import PDFKit
import NotBadData
import NotBadCore

struct ExportPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    let items: [ReviewItemModel]
    
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
        // Convert Models to Entities (Main Thread)
        let coreItems = items.map { $0.toEntity() }
        
        // Run in background
        DispatchQueue.global(qos: .userInitiated).async {
            let data = PDFExportService.shared.createPDF(from: coreItems) { path in
                // Image Provider closure: runs on thread?
                // ImageStorage loadImage is main-thread safe? it uses UIImage(contentsOfFile), which is thread safe-ish but IO bound.
                // We are in background, so it's fine.
                // Need to construct full path. ImageStorage internal logic is `documentsDirectory.appending(path)`.
                // Accessing ImageStorage from here.
                return imageStorage.loadImage(path: path)
            }
            
            DispatchQueue.main.async {
                self.pdfData = data
                self.isLoading = false
            }
        }
    }
    
    private func saveToTemp(pdfData: Data) -> String {
        let fileName = "NotBad_Mistakes_\(Date().formatted(date: .numeric, time: .omitted)).pdf"
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
