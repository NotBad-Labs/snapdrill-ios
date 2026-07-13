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
#if canImport(UIKit)
import UIKit
#endif

/// 采集结果预览与编辑视图
public struct CaptureResultView: View {

    // MARK: - Properties

    // @Bindable 用于外部传入的 @Observable 对象，不持有所有权（区别于 @State）
    @Bindable var viewModel: CaptureResultViewModel

    // 固定字段可见性（答案）。分类/来源/级别/自定义维度可见性按维度（VM）。
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

                if viewModel.showFieldConfigTip {
                    CaptureFieldConfigTipCard {
                        viewModel.dismissFieldConfigTip()
                    }
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                CaptureMetadataSection(viewModel: viewModel)

                CaptureDetailsSection(
                    viewModel: viewModel,
                    showAnswer: showAnswerField
                )

                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .scrollDismissesKeyboard(.interactively)
        .accessibilityIdentifier("capture.result.root")
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
                            Image(systemName: "checkmark")
                        }
                    }
                    .disabled(
                        viewModel.isRecognizing
                            || viewModel.isAnswerPhotoLoading
                            || viewModel.isSaving
                            || viewModel.isSaved
                    )
                    .accessibilityLabel(L10n.Common.save)
                    .accessibilityIdentifier("capture.saveButton")
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.Common.done) {
                    dismissKeyboard()
                }
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
        .toolbar(.hidden, for: .tabBar)
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
        .alert(L10n.Capture.saveFailed, isPresented: $viewModel.showErrorAlert) {
            Button(L10n.Common.ok, role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    private func dismissKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

private struct CaptureFieldConfigTipCard: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "slider.horizontal.3")
                .font(.headline)
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.blue.opacity(0.12)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Onboarding.fieldConfigTitle)
                    .font(.subheadline.weight(.semibold))

                Text(L10n.Onboarding.fieldConfigDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button(L10n.Common.ok) {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .accessibilityIdentifier("capture.fieldConfigTip.ok")
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityIdentifier("capture.fieldConfigTip")
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
