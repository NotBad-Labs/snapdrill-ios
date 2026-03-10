//
//  PDFPagePickerView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/03/10.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  PDF 页面选择器，展示各页缩略图，用户点击后进入裁剪→OCR→保存流程。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI
import SnapDrillData

/// PDF 页面选择器
///
/// 以网格形式展示 PDF 各页的缩略图，用户点击任意页面后进入标准的裁剪→OCR→保存流程。
/// 保存完成后自动返回此页面，方便继续选择下一页（连续录入）。
struct PDFPagePickerView: View {

    // MARK: - Properties

    let pages: [UIImage]
    @Bindable var router: CaptureRouter
    @Environment(\.repositories) private var repositories
    @Environment(\.analyticsService) private var analyticsService

    @State private var selectedPageImage: UIImage?
    @State private var isShowingCropper = false
    @State private var isProcessingOCR = false
    @State private var ocrTask: Task<Void, Never>?

    private let ocrService: OCRServiceProtocol = OCRService()

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("共 \(pages.count) 页，点击选择要录入的页面")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, image in
                            Button {
                                selectedPageImage = image
                                isShowingCropper = true
                            } label: {
                                pageCard(image: image, pageNumber: index + 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }

            // OCR 处理中遮罩
            if isProcessingOCR {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 16) {
                            ProgressView()
                                .controlSize(.large)
                                .tint(.white)
                            Text("正在识别...")
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
            if let image = selectedPageImage {
                ImageCropperView(
                    originalImage: image,
                    onCrop: { croppedImage in
                        isShowingCropper = false
                        processOCRAndNavigate(croppedImage)
                    },
                    onCancel: {
                        isShowingCropper = false
                        selectedPageImage = nil
                    }
                )
            }
        }
        .onDisappear {
            ocrTask?.cancel()
            ocrTask = nil
        }
    }

    // MARK: - Private Helpers

    @ViewBuilder
    private func pageCard(image: UIImage, pageNumber: Int) -> some View {
        VStack(spacing: 8) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 240)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

            Text("第 \(pageNumber) 页")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
            selectedPageImage = nil
            router.push(.scannerResult(content: ocrText, image: image))
        }
    }
}
