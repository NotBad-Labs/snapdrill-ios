//
//  CaptureResultView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集结果预览视图。布局拆分为 4 个 Section 子 View（图片/正文/分类/详情）；
//  本文件负责组装、生命周期、toolbar、以及 alert/cover/popover 等 modifier 协调。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI

/// 采集结果预览与编辑视图
public struct CaptureResultView: View {

    // MARK: - Properties

    // @Bindable 用于外部传入的 @Observable 对象，不持有所有权（区别于 @State）
    @Bindable var viewModel: CaptureResultViewModel

    // 固定字段可见性（难度/答案）。L3：学科/来源/年级已并入动态维度，可见性按维度（VM）。
    @AppStorage(UDKey.captureFieldDifficulty) private var showDifficultyField: Bool = false
    @AppStorage(UDKey.captureFieldAnswer) private var showAnswerField: Bool = false

    /// 创建采集结果视图
    /// - Parameter viewModel: 注入的 ViewModel
    public init(viewModel: CaptureResultViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    /// 采集结果预览与编辑的视图层次（组装 4 个 Section + 生命周期/toolbar/弹窗协调）
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                CaptureImageSection(viewModel: viewModel)

                CaptureContentSection(viewModel: viewModel)

                CaptureMetadataSection(viewModel: viewModel)

                CaptureDetailsSection(
                    viewModel: viewModel,
                    showDifficulty: showDifficultyField,
                    showAnswer: showAnswerField
                )

                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .onAppear {
            viewModel.loadFormData()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.save()
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text(L10n.Common.save)
                            .fontWeight(.bold)
                    }
                }
                .disabled(viewModel.isRecognizing || viewModel.isSaving)
                .accessibilityIdentifier("capture.saveButton")
            }
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.isSaving || viewModel.isSaved {
                CaptureSaveStatusBanner(isSaved: viewModel.isSaved)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .navigationTitle(L10n.Capture.previewAndEdit)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $viewModel.isCropping) {
            if let currentImage = viewModel.image {
                ImageCropperView(
                    originalImage: currentImage,
                    onCrop: { croppedImage in
                        viewModel.handleImageCrop(croppedImage)
                    },
                    onCancel: {
                        viewModel.cancelCrop()
                    }
                )
                .ignoresSafeArea()
            }
        }
        .onDisappear {
            viewModel.saveDraftOnDisappear()
            viewModel.cancelTasks()
        }
        .sensoryFeedback(.success, trigger: viewModel.isSaved) { _, newValue in
            newValue
        }
        .popover(isPresented: $viewModel.showFieldConfigTip, arrowEdge: .bottom) {
            TipPopoverContent(
                icon: "slider.horizontal.3",
                title: L10n.Onboarding.fieldConfigTitle,
                message: L10n.Onboarding.fieldConfigDescription
            ) {
                viewModel.dismissFieldConfigTip()
            }
        }
        .alert(L10n.Capture.saveFailed, isPresented: $viewModel.showErrorAlert) {
            Button(L10n.Common.ok, role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

private struct CaptureSaveStatusBanner: View {
    let isSaved: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isSaved ? "checkmark.circle.fill" : "arrow.down.doc")
                .foregroundStyle(isSaved ? .green : .blue)
                .accessibilityHidden(true)

            Text(isSaved ? L10n.Capture.saveSucceeded : L10n.Capture.saving)
                .font(.subheadline.weight(.semibold))

            Spacer(minLength: 0)

            if !isSaved {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
}

// 移除 Preview 以避免繁琐的 Mock 数据注入依赖
