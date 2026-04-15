//
//  ScanPagePickerView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/04/15.
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

    @State private var isShowingCropper = false
    @State private var selectedImage: UIImage?
    @State private var isProcessingOCR = false
    @State private var ocrTask: Task<Void, Never>?

    var ocrService: OCRServiceProtocol = OCRService()

    private var pages: [UIImage] { router.scannedPages ?? [] }

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.Capture.selectPage)
                    .font(.headline)
                    .padding(.horizontal)

                Text(L10n.Capture.pdfPageHint(pages.count))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, image in
                        Button {
                            selectedImage = image
                            isShowingCropper = true
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
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(L10n.Capture.selectPage)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isShowingCropper) {
            if let image = selectedImage {
                ImageCropperView(
                    originalImage: image,
                    onCrop: { croppedImage in
                        isShowingCropper = false
                        processImage(croppedImage)
                    },
                    onCancel: {
                        isShowingCropper = false
                        selectedImage = nil
                    }
                )
                .ignoresSafeArea()
            }
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
                    }
            }
        }
        .onDisappear {
            ocrTask?.cancel()
            ocrTask = nil
        }
    }

    // MARK: - Private

    private func processImage(_ image: UIImage) {
        isProcessingOCR = true
        ocrTask = Task {
            do {
                guard let cgImage = image.cgImage else {
                    isProcessingOCR = false
                    return
                }
                let text = try await ocrService.recognizeText(from: cgImage)
                guard !Task.isCancelled else { return }
                isProcessingOCR = false
                router.push(.scannerResult(content: text, image: image))
            } catch is CancellationError {
                SnapDrillLogger.capture.info("扫描页 OCR 任务已取消。")
            } catch {
                isProcessingOCR = false
                SnapDrillLogger.capture.error("扫描页 OCR 失败: \(error.localizedDescription)")
                // OCR 失败仍推入编辑页，让用户手动输入
                router.push(.scannerResult(content: "", image: image))
            }
        }
    }
}
