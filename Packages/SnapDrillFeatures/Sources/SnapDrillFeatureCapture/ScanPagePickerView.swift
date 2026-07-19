//
//  ScanPagePickerView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  文档扫描多页选择器：展示全部扫描页面的缩略图，点击后进入裁剪/OCR 流程。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI

/// 文档扫描多页选择器
///
/// 与 ``PDFPagePickerView`` 交互模式一致：缩略图网格 → 点击选页 → 裁剪 → OCR → 编辑保存。
struct ScanPagePickerView: View {

    @Bindable var router: CaptureRouter
    @Environment(\.repositories) private var repositories
    @Environment(\.analyticsService) private var analyticsService

    @State private var cropperItem: CropperItem?
    @State private var isProcessingOCR = false
    @State private var ocrTask: Task<Void, Never>?
    @State private var ocrNotice = OCRNotice()
    @State private var draftSession = CapturePageDraftSession()

    var ocrService: OCRServiceProtocol = OCRService()
    var draftService: CaptureDraftServiceProtocol

    private var pages: [UIImage] { router.scannedPages ?? [] }

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.Capture.pdfPageHint(pages.count))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, image in
                        Button {
                            cropperItem = CropperItem(image: image)
                        } label: {
                            VStack(spacing: 8) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .shadow(radius: 2)

                                Text(L10n.Capture.pageNumber(index + 1))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibleButton(label: L10n.Accessibility.pdfPageButton(page: index + 1))
                        .accessibilityIdentifier("capture.scanPage.\(index + 1)")
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .accessibilityIdentifier("capture.scanPagePicker.root")
        .navigationTitle(L10n.Capture.selectPage)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $cropperItem) { item in
            ImageCropperView(
                originalImage: item.image,
                onCrop: { croppedImage in
                    cropperItem = nil
                    processImage(croppedImage)
                },
                onCancel: {
                    cropperItem = nil
                }
            )
            .ignoresSafeArea()
        }
        .overlay {
            if isProcessingOCR {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 16) {
                            ProgressView()
                                .controlSize(.large)
                                .tint(.white)
                            Text(L10n.Capture.recognizingPage)
                                .foregroundStyle(.white)
                                .font(.headline)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .accessibilityIdentifier("capture.scanPagePicker.processing")
                    }
            }
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
        .onDisappear {
            ocrTask?.cancel()
            ocrTask = nil
        }
        .onAppear {
            draftSession.synchronize(with: draftService.state())
        }
    }

    // MARK: - Private

    @discardableResult
    func processImage(_ image: UIImage) -> Task<Void, Never> {
        ocrTask?.cancel()
        isProcessingOCR = true
        let task = Task {
            defer { isProcessingOCR = false }
            let checkpoint: CaptureDraftToken
            do {
                checkpoint = try await makeCheckpoint(for: image)
            } catch {
                presentSaveFailure(for: image, draftToken: nil)
                return
            }

            do {
                guard let cgImage = image.cgImage else {
                    presentOCRFailure(for: image, draftToken: checkpoint)
                    return
                }
                let result = try await ocrService.recognizeDocument(from: cgImage)
                let text = result.transcript
                try Task.checkCancellation()
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    ocrNotice.present(
                        title: L10n.Capture.ocrEmptyTitle,
                        message: L10n.Capture.ocrEmptyHint,
                        image: image,
                        draftToken: checkpoint
                    )
                    return
                }
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
            } catch is CancellationError {
                SnapDrillLogger.capture.info("扫描页 OCR 任务已取消。")
            } catch {
                SnapDrillLogger.capture.error("扫描页 OCR 失败: \(error.localizedDescription)")
                presentOCRFailure(for: image, draftToken: checkpoint)
            }
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

    private func presentSaveFailure(
        for image: UIImage,
        draftToken: CaptureDraftToken?
    ) {
        ocrNotice.present(
            title: L10n.Capture.saveFailed,
            message: L10n.Errors.tryAgainLater,
            image: image,
            draftToken: draftToken
        )
    }

    private func presentOCRFailure(
        for image: UIImage,
        draftToken: CaptureDraftToken
    ) {
        ocrNotice.present(
            title: L10n.Capture.ocrFailedTitle,
            message: L10n.Capture.ocrFailedHint,
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
