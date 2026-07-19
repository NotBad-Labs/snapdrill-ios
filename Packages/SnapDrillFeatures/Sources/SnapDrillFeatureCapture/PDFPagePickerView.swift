//
//  PDFPagePickerView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
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
/// 缩略图通过 ``PDFThumbnailCache`` 异步生成并缓存，LazyVGrid 滚动不掉帧。
struct PDFPagePickerView: View {

    // MARK: - Properties

    @Bindable var router: CaptureRouter
    @Environment(\.repositories) private var repositories
    @Environment(\.analyticsService) private var analyticsService

    @State private var cropperItem: CropperItem?
    @State private var isRendering = false
    @State private var isProcessingOCR = false
    @State private var renderTask: Task<Void, Never>?
    @State private var ocrTask: Task<Void, Never>?
    @State private var thumbnailCache: PDFThumbnailCache?
    @State private var ocrNotice = OCRNotice()
    @State private var draftSession = CapturePageDraftSession()

    var ocrService: OCRServiceProtocol = OCRService()
    var draftService: CaptureDraftServiceProtocol

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
                    Text(L10n.Capture.pdfPageHint(pageCount))
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
                            .accessibleButton(label: L10n.Accessibility.pdfPageButton(page: index + 1))
                            .accessibilityIdentifier("capture.pdfPage.\(index + 1)")
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
                            Text(isRendering ? L10n.Capture.loadingPage : L10n.Capture.recognizingPage)
                                .foregroundStyle(.white)
                                .font(.headline)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .accessible(label: L10n.Accessibility.processingOverlay)
                        .accessibilityIdentifier("capture.pdfPagePicker.processing")
                    }
            }
        }
        .accessibilityIdentifier("capture.pdfPagePicker.root")
        .navigationTitle(L10n.Capture.selectPage)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $cropperItem) { item in
            ImageCropperView(
                originalImage: item.image,
                onCrop: { croppedImage in
                    cropperItem = nil
                    processOCRAndNavigate(croppedImage)
                },
                onCancel: {
                    cropperItem = nil
                }
            )
        }
        .onAppear {
            // 初始化缩略图缓存（仅在首次出现时创建）
            if thumbnailCache == nil, let doc = document {
                thumbnailCache = PDFThumbnailCache(document: doc, thumbnailSize: thumbnailSize)
            }
            draftSession.synchronize(with: draftService.state())
        }
        .onDisappear {
            renderTask?.cancel()
            renderTask = nil
            ocrTask?.cancel()
            ocrTask = nil
            thumbnailCache?.cancelAll()
        }
        .alert(ocrNotice.title, isPresented: $ocrNotice.isPresented) {
            if ocrNotice.draftToken != nil {
                Button(L10n.Capture.ocrContinueEdit) {
                    if let image = ocrNotice.image {
                        router.push(
                            .scannerResult(
                                content: "",
                                image: image,
                                draftToken: ocrNotice.draftToken
                            )
                        )
                    }
                    ocrNotice.clear()
                }
            }
            Button(L10n.Common.cancel, role: .cancel) {
                ocrNotice.clear()
            }
        } message: {
            Text(ocrNotice.message)
        }
    }

    // MARK: - Private Helpers

    /// 异步缩略图卡片，使用缓存避免重复计算
    @ViewBuilder
    private func pageCard(pageIndex: Int) -> some View {
        VStack(spacing: 8) {
            PDFThumbnailView(cache: thumbnailCache, pageIndex: pageIndex)
                .frame(maxHeight: 240)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

            Text(L10n.Capture.pageNumber(pageIndex + 1))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }

    /// 仅对选中的单页异步渲染全尺寸图（长边 ≤ 2048px），然后打开裁剪器
    private func renderFullSizeAndCrop(pageIndex: Int) {
        guard let page = document?.page(at: pageIndex) else { return }
        renderTask?.cancel()
        isRendering = true
        // PDFPage（NSObject）读操作线程安全，但类型未遵循 Sendable。
        // nonisolated(unsafe) 显式声明此跨隔离域传递是安全的。
        nonisolated(unsafe) let sendablePage = page
        renderTask = Task {
            // 嵌套 detached task 脱离 MainActor，避免 2048px 渲染阻塞 UI
            let image = await Task.detached {
                Self.renderPDFPage(sendablePage)
            }.value
            guard !Task.isCancelled else { return }
            isRendering = false
            cropperItem = CropperItem(image: image)
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

    @discardableResult
    func processOCRAndNavigate(_ image: UIImage) -> Task<Void, Never> {
        isProcessingOCR = true
        let task = Task {
            let checkpoint: CaptureDraftToken
            do {
                checkpoint = try await makeCheckpoint(for: image)
            } catch {
                await presentOCRNotice(
                    title: L10n.Capture.saveFailed,
                    message: L10n.Errors.tryAgainLater,
                    image: image,
                    draftToken: nil
                )
                return
            }

            guard let ocrText = await recognizeText(in: image, checkpoint: checkpoint) else {
                return
            }

            guard !Task.isCancelled else { return }
            isProcessingOCR = false
            guard !ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                ocrNotice.present(
                    title: L10n.Capture.ocrEmptyTitle,
                    message: L10n.Capture.ocrEmptyHint,
                    image: image,
                    draftToken: checkpoint
                )
                return
            }
            await enrichAndNavigate(
                image: image,
                text: ocrText,
                checkpoint: checkpoint
            )
        }
        ocrTask = task
        return task
    }

    private func makeCheckpoint(for image: UIImage) async throws -> CaptureDraftToken {
        try await draftSession.saveCheckpoint(
            image: image,
            using: draftService
        )
    }

    private func recognizeText(
        in image: UIImage,
        checkpoint: CaptureDraftToken
    ) async -> String? {
        guard let cgImage = image.cgImage else {
            await presentOCRNotice(
                title: L10n.Capture.ocrFailedTitle,
                message: L10n.Capture.ocrFailedHint,
                image: image,
                draftToken: checkpoint
            )
            return nil
        }
        do {
            return try await ocrService.recognizeDocument(from: cgImage).transcript
        } catch {
            SnapDrillLogger.capture.error("PDF 页面 OCR 失败: \(error.localizedDescription)")
            await presentOCRNotice(
                title: L10n.Capture.ocrFailedTitle,
                message: L10n.Capture.ocrFailedHint,
                image: image,
                draftToken: checkpoint
            )
            return nil
        }
    }

    private func enrichAndNavigate(
        image: UIImage,
        text: String,
        checkpoint: CaptureDraftToken
    ) async {
        do {
            let enriched = try await draftService.saveDraft(
                image: image,
                content: text,
                category: nil,
                captureID: checkpoint.captureID,
                expected: checkpoint
            )
            draftSession.token = enriched
            router.push(
                .scannerResult(
                    content: text,
                    image: image,
                    draftToken: enriched
                )
            )
        } catch {
            ocrNotice.present(
                title: L10n.Capture.saveFailed,
                message: L10n.Errors.tryAgainLater,
                image: image,
                draftToken: checkpoint
            )
        }
    }

    private func presentOCRNotice(
        title: String,
        message: String,
        image: UIImage,
        draftToken: CaptureDraftToken?
    ) async {
        guard !Task.isCancelled else { return }
        isProcessingOCR = false
        ocrNotice.present(
            title: title,
            message: message,
            image: image,
            draftToken: draftToken
        )
    }
}

private struct CropperItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct OCRNotice {
    var isPresented = false
    var title = ""
    var message = ""
    var image: UIImage?
    var draftToken: CaptureDraftToken?

    mutating func present(
        title: String,
        message: String,
        image: UIImage,
        draftToken: CaptureDraftToken?
    ) {
        self.title = title
        self.message = message
        self.image = image
        self.draftToken = draftToken
        self.isPresented = true
    }

    mutating func clear() {
        isPresented = false
        image = nil
        draftToken = nil
    }
}

// MARK: - PDFThumbnailCache

/// PDF 缩略图异步缓存
///
/// 在后台线程生成缩略图并缓存到内存字典中，避免 LazyVGrid 滚动时重复调用
/// `PDFPage.thumbnail(of:for:)` 导致掉帧。每页缩略图仅生成一次。
@Observable
final class PDFThumbnailCache {

    // MARK: - Properties

    /// 已缓存的缩略图（pageIndex → UIImage）
    private(set) var thumbnails: [Int: UIImage] = [:]

    /// 正在生成中的页面索引集合（防止重复提交）
    private var pendingPages: Set<Int> = []

    private let document: PDFDocument
    private let thumbnailSize: CGSize

    /// PDF 文档的 Data 快照，供 Task.detached 内重建文档使用（避免非 Sendable 的 PDFPage 跨隔离域）
    private let documentData: Data?

    @ObservationIgnored
    private var generationTasks: [Int: Task<Void, Never>] = [:]

    // MARK: - Initialization

    /// 创建缩略图缓存
    /// - Parameters:
    ///   - document: PDF 文档
    ///   - thumbnailSize: 缩略图尺寸（点）
    init(document: PDFDocument, thumbnailSize: CGSize) {
        self.document = document
        self.thumbnailSize = thumbnailSize
        self.documentData = document.dataRepresentation()
    }

    // MARK: - Public API

    /// 请求指定页面的缩略图，若未缓存则异步生成
    /// - Parameter pageIndex: 页面索引
    func requestThumbnail(for pageIndex: Int) {
        // 已缓存或正在生成中，跳过
        guard thumbnails[pageIndex] == nil, !pendingPages.contains(pageIndex) else { return }
        guard document.page(at: pageIndex) != nil else { return }

        pendingPages.insert(pageIndex)
        let size = thumbnailSize
        let docData = documentData
        generationTasks[pageIndex] = Task {
            let image: UIImage? = await Task.detached {
                guard let data = docData,
                      let doc = PDFDocument(data: data),
                      let page = doc.page(at: pageIndex) else { return nil }
                return page.thumbnail(of: size, for: .mediaBox)
            }.value

            guard !Task.isCancelled, let image else { return }
            thumbnails[pageIndex] = image
            pendingPages.remove(pageIndex)
            generationTasks.removeValue(forKey: pageIndex)
        }
    }

    /// 取消所有进行中的缩略图生成任务
    func cancelAll() {
        for task in generationTasks.values {
            task.cancel()
        }
        generationTasks.removeAll()
        pendingPages.removeAll()
    }
}

// MARK: - PDFThumbnailView

/// 异步缩略图视图
///
/// 出现时向 ``PDFThumbnailCache`` 请求缩略图，缓存命中后立即展示。
/// 加载中显示占位 ProgressView，确保流畅滚动体验。
private struct PDFThumbnailView: View {

    let cache: PDFThumbnailCache?
    let pageIndex: Int

    var body: some View {
        Group {
            if let thumbnail = cache?.thumbnails[pageIndex] {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity)
            } else {
                // 占位：与缩略图同比例的灰色区域 + 加载指示器
                Rectangle()
                    .fill(Color(.systemGray5))
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
                    .overlay {
                        ProgressView()
                    }
                    .accessible(label: L10n.Accessibility.pdfLoadingThumbnail)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: cache?.thumbnails[pageIndex] != nil)
        .onAppear {
            cache?.requestThumbnail(for: pageIndex)
        }
        .task(id: cache == nil) {
            cache?.requestThumbnail(for: pageIndex)
        }
    }
}
