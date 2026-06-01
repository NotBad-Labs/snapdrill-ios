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

    // 录入字段可见性（与 SettingsView 共享同一组 @AppStorage key）
    @AppStorage(UDKey.captureFieldSubject) private var showSubjectField: Bool = true
    @AppStorage(UDKey.captureFieldSource) private var showSourceField: Bool = false
    @AppStorage(UDKey.captureFieldDifficulty) private var showDifficultyField: Bool = false
    @AppStorage(UDKey.captureFieldGrade) private var showGradeField: Bool = false
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

                CaptureMetadataSection(
                    viewModel: viewModel,
                    showSubject: showSubjectField,
                    showSource: showSourceField
                )

                CaptureDetailsSection(
                    viewModel: viewModel,
                    showDifficulty: showDifficultyField,
                    showGrade: showGradeField,
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
                Button(L10n.Common.save) {
                    viewModel.save()
                }
                .fontWeight(.bold)
                .disabled(viewModel.isRecognizing || viewModel.isSaving)
                .accessibilityIdentifier("capture.saveButton")
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
        .alert(L10n.Capture.newSubject, isPresented: $viewModel.showNewSubjectAlert) {
            TextField(L10n.Capture.subjectNamePlaceholder, text: $viewModel.newSubjectName)
            Button(L10n.Common.create) { viewModel.confirmNewSubject() }
            Button(L10n.Common.cancel, role: .cancel) { viewModel.newSubjectName = "" }
        } message: {
            Text(L10n.Capture.newSubjectMessage)
        }
        .alert(L10n.Capture.newSource, isPresented: $viewModel.showNewSourceAlert) {
            TextField(L10n.Capture.sourceNamePlaceholder, text: $viewModel.newSourceName)
            Button(L10n.Common.create) { viewModel.confirmNewSource() }
            Button(L10n.Common.cancel, role: .cancel) { viewModel.newSourceName = "" }
        } message: {
            Text(L10n.Capture.newSourceMessage)
        }
        .alert(L10n.Capture.newGrade, isPresented: $viewModel.showNewGradeAlert) {
            TextField(L10n.Capture.gradeNamePlaceholder, text: $viewModel.newGradeName)
            Button(L10n.Common.create) { viewModel.confirmNewGrade() }
            Button(L10n.Common.cancel, role: .cancel) { viewModel.newGradeName = "" }
        } message: {
            Text(L10n.Capture.newGradeMessage)
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

// 移除 Preview 以避免繁琐的 Mock 数据注入依赖
