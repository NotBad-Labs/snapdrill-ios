//
//  CaptureResultView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/30.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集结果预览视图，提供裁剪、重拍和确认功能。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI
import PhotosUI

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
    
    /// 采集结果预览与编辑的视图层次
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Image Preview
                if let image = viewModel.image {
                    ZStack(alignment: .bottomTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay {
                                if viewModel.isRecognizing {
                                    ZStack {
                                        Color.black.opacity(0.3)
                                        ProgressView()
                                            .tint(.white)
                                    }
                                }
                            }
                
                        Button(action: {
                            viewModel.isCropping = true
                        }, label: {
                            Image(systemName: "crop")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        })
                        .padding(8)
                        .disabled(viewModel.isRecognizing)
                    }
                    .padding(.horizontal)
                    .onTapGesture {
                        viewModel.isCropping = true
                    }
                }
        
                // Editor
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(L10n.Capture.questionContent)
                            .font(.headline)
                        if viewModel.isRecognizing {
                            Text(L10n.Capture.reRecognizing)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
            
                    TextEditor(text: $viewModel.content)
                        .font(.body)
                        .padding(12)
                        .frame(minHeight: 120)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .opacity(viewModel.isRecognizing ? 0.6 : 1)
                        .disabled(viewModel.isRecognizing)
                }
                .padding(.horizontal)
        
                // Metadata Form（字段按 Settings 中的开关条件渲染）
                VStack(alignment: .leading, spacing: 20) {
                    Text(L10n.Capture.categoryInfo)
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        // Subject — Menu label 仅覆盖右侧（当前值 + chevron），弹出框锚定右侧，左侧标签始终可见
                        // 支持内联新建：Things 3 / Notion / Apple Notes 均采用此模式
                        if showSubjectField {
                            HStack {
                                Text(L10n.Capture.subject)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Menu {
                                    ForEach(viewModel.availableSubjects) { subject in
                                        Button {
                                            viewModel.selectedSubject = subject.name
                                        } label: {
                                            Label(subject.name, systemImage: subject.icon)
                                        }
                                    }
                                    Divider()
                                    Button {
                                        viewModel.showNewSubjectAlert = true
                                    } label: {
                                        Label(L10n.Capture.newSubject, systemImage: "plus")
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(viewModel.selectedSubject)
                                            .foregroundStyle(.secondary)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                            .padding()
                        }

                        // Source — 同上：Menu label 仅右侧，保留内联新建
                        if showSourceField {
                            if showSubjectField { Divider().padding(.leading) }
                            HStack {
                                Text(L10n.Capture.source)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Menu {
                                    ForEach(viewModel.availableSources) { source in
                                        Button {
                                            viewModel.selectedSource = source.name
                                        } label: {
                                            Label(source.name, systemImage: source.icon)
                                        }
                                    }
                                    Divider()
                                    Button {
                                        viewModel.showNewSourceAlert = true
                                    } label: {
                                        Label(L10n.Capture.newSource, systemImage: "plus")
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(viewModel.selectedSource)
                                            .foregroundStyle(.secondary)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                            .padding()
                        }

                        // Tags（始终可用，不可关闭）
                        if showSubjectField || showSourceField { Divider().padding(.leading) }
                        VStack(alignment: .leading) {
                            Text(L10n.Capture.tags)
                            TagInputView(
                                tags: $viewModel.tagList,
                                text: $viewModel.tagInputText,
                                suggestions: viewModel.availableTags.map { $0.name }
                            )
                        }
                        .padding()
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
        
                // Details Form（难度、年级、答案 — 全部关闭时整个 section 隐藏）
                if showDifficultyField || showGradeField || showAnswerField {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(L10n.Capture.questionDetails)
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            // Difficulty
                            if showDifficultyField {
                                HStack {
                                    Text(L10n.Capture.difficulty)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        ForEach(1...5, id: \.self) { level in
                                            Button {
                                                viewModel.difficulty = Difficulty(rawValue: level) ?? .one
                                            } label: {
                                                Image(systemName: level <= viewModel.difficulty.rawValue ? "star.fill" : "star")
                                                    .foregroundStyle(level <= viewModel.difficulty.rawValue ? .orange : .gray.opacity(0.3))
                                            }
                                            .buttonStyle(.plain)
                                            .accessibilityLabel("\(level) \(L10n.Capture.difficulty)")
                                        }
                                    }
                                }
                                .padding()
                            }

                            // Grade/Mastery — 同上：Menu label 仅右侧，保留内联新建
                            if showGradeField {
                                if showDifficultyField { Divider().padding(.leading) }
                                HStack {
                                    Text(L10n.Capture.grade)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Menu {
                                        ForEach(viewModel.availableGrades) { grade in
                                            Button {
                                                viewModel.grade = grade.name
                                            } label: {
                                                Text(grade.name)
                                            }
                                        }
                                        Divider()
                                        Button {
                                            viewModel.showNewGradeAlert = true
                                        } label: {
                                            Label(L10n.Capture.newGrade, systemImage: "plus")
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(viewModel.grade.isEmpty ? L10n.Common.notSelected : viewModel.grade)
                                                .foregroundStyle(viewModel.grade.isEmpty ? .tertiary : .secondary)
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                }
                                .padding()
                            }

                            // Answer
                            if showAnswerField {
                                if showDifficultyField || showGradeField { Divider().padding(.leading) }
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(L10n.Capture.answer)
                                    TextEditor(text: $viewModel.answerText)
                                        .frame(minHeight: 80)
                                        .scrollContentBackground(.hidden)
                                        .background(Color(UIColor.tertiarySystemFill))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                    // Answer Image Picker
                                    HStack {
                                        if let answerImage = viewModel.answerImage {
                                            Image(uiImage: answerImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(maxHeight: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))

                                            Button(role: .destructive) {
                                                viewModel.answerImage = nil
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.red)
                                            }
                                        }

                                        Spacer()

                                        PhotosPicker(selection: $viewModel.answerPhotoItem, matching: .images) {
                                            Label(L10n.Capture.addAnswerImage, systemImage: "photo.badge.plus")
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }
        
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

