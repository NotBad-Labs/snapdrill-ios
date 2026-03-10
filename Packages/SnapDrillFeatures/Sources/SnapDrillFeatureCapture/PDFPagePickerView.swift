//
//  PDFPagePickerView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/03/10.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  PDF 页面选择器，展示各页缩略图，用户点击后渲染全尺寸图进入裁剪→OCR→保存流程。
//

import SwiftUI
import PDFKit
import SnapDrillCore
import SnapDrillUI
import SnapDrillData

/// PDF 页面选择器
///
/// 从 `CaptureRouter.pdfDocument` 读取 PDF 文档，以网格形式展示各页的轻量缩略图。
/// 用户点击页面后，仅对该页渲染全尺寸图（长边 ≤ 2048px），然后进入裁剪→OCR→保存流程。
/// 按需渲染策略避免一次性加载所有页面导致内存溢出。
struct PDFPagePickerView: View {

    // MARK: - Properties

    @Bindable var router: CaptureRouter
    @Environment(\.repositories) private var repositories
    @Environment(\.analyticsService) private var analyticsService

    @State private var isShowingCropper = false
    @State private var fullSizeImage: UIImage?
    @State private var isRendering = false
    @State private var isProcessingOCR = false
    @State private var renderTask: Task<Void, Never>?
    @State private var ocrTask: Task<Void, Never>?

    private let ocrService: OCRServiceProtocol = OCRService()

    /// 缩略图尺寸（点）
    private let thumbnailSize = CGSize(width: 300, height: 400)

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private var document: PDFDocument? { router.pdfDocument }
    private var pageCount: Int { document?.pageCount ?? 0 }

    // MARK: - Body

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("共 \(pageCount) 页，点击选择要录入的页面")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(0 ..< pageCount, id: \.self) { index in
                            Button {
                                renderFullSizeAndCrop(pageIndex: index)
                            } label: {
                                pageCard(pageIndex: index)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }

            // 渲染或 OCR 处理中遮罩
            if isRendering || isProcessingOCR {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 16) {
                            ProgressView()
                                .controlSize(.large)
                                .tint(.white)
                            Text(isRendering ? "正在加载..." : "正在识别...")
                                .foregroundStyle(.white)
                                .font(.headline)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
            }
        }
        .navigationTitle("选择页面")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isShowingCropper) {
            if let image = fullSizeImage {
                ImageCropperView(
                    originalImage: image,
                    onCrop: { croppedImage in
                        isShowingCropper = false
                        fullSizeImage = nil
                        processOCRAndNavigate(croppedImage)
                    },
                    onCancel: {
                        isShowingCropper = false
                        fullSizeImage = nil
                    }
                )
            }
        }
        .onDisappear {
            renderTask?.cancel()
            renderTask = nil
            ocrTask?.cancel()
            ocrTask = nil
        }
    }

    // MARK: - Private Helpers

    /// 使用 PDFPage.thumbnail() 生成轻量缩略图（内存友好）
    @ViewBuilder
    private func pageCard(pageIndex: Int) -> some View {
        VStack(spacing: 8) {
            if let page = document?.page(at: pageIndex) {
                let thumbnail = page.thumbnail(of: thumbnailSize, for: .mediaBox)
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            }

            Text("第 \(pageIndex + 1) 页")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// 仅对选中的单页异步渲染全尺寸图（长边 ≤ 2048px），然后打开裁剪器
    private func renderFullSizeAndCrop(pageIndex: Int) {
        guard let page = document?.page(at: pageIndex) else { return }
        renderTask?.cancel()
        isRendering = true
        renderTask = Task {
            // 嵌套 detached task 脱离 MainActor，避免 2048px 渲染阻塞 UI
            let image = await Task.detached {
                Self.renderPDFPage(page)
            }.value
            guard !Task.isCancelled else { return }
            isRendering = false
            fullSizeImage = image
            isShowingCropper = true
        }
    }

    /// 将 PDF 页面渲染为 UIImage，长边不超过 2048px
    ///
    /// UIGraphicsImageRenderer 自 iOS 10 起线程安全，可在任意线程调用。
    private static nonisolated func renderPDFPage(_ page: PDFPage) -> UIImage {
        let pageRect = page.bounds(for: .mediaBox)
        let maxDimension: CGFloat = 2048
        let scale = min(maxDimension / pageRect.width, maxDimension / pageRect.height, 2.0)
        let renderSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

        let renderer = UIGraphicsImageRenderer(size: renderSize)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: renderSize))
            context.cgContext.translateBy(x: 0, y: renderSize.height)
            context.cgContext.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: context.cgContext)
        }
    }

    private func processOCRAndNavigate(_ image: UIImage) {
        isProcessingOCR = true
        ocrTask = Task {
            var ocrText = ""
            if let cgImage = image.cgImage {
                do {
                    ocrText = try await ocrService.recognizeText(from: cgImage)
                } catch {
                    SnapDrillLogger.capture.error("PDF 页面 OCR 失败: \(error.localizedDescription)")
                }
            }

            guard !Task.isCancelled else { return }
            isProcessingOCR = false
            router.push(.scannerResult(content: ocrText, image: image))
        }
    }
}
