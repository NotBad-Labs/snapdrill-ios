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

    public init(viewModel: CaptureResultViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
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
                        Text("题目内容")
                            .font(.headline)
                        if viewModel.isRecognizing {
                            Text("正在重新识别...")
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
        
                // Metadata Form
                VStack(alignment: .leading, spacing: 20) {
                    Text("分类信息")
                        .font(.headline)
                        .padding(.horizontal)
            
                    VStack(spacing: 0) {
                        // Subject — HIG: 非 Form 上下文用 Picker(.menu)，右侧为点击区，弹出框锚定右侧
                        HStack {
                            Text("学科")
                                .foregroundStyle(.primary)
                            Spacer()
                            Picker("学科", selection: $viewModel.selectedSubject) {
                                ForEach(viewModel.availableSubjects) { subject in
                                    Label(subject.name, systemImage: subject.icon).tag(subject.name)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                        .padding()

                        Divider().padding(.leading)

                        // Source — HIG: 非 Form 上下文用 Picker(.menu)，右侧为点击区，弹出框锚定右侧
                        HStack {
                            Text("来源")
                                .foregroundStyle(.primary)
                            Spacer()
                            Picker("来源", selection: $viewModel.selectedSource) {
                                ForEach(viewModel.availableSources) { source in
                                    Label(source.name, systemImage: source.icon).tag(source.name)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                        .padding()
                
                        Divider().padding(.leading)
                
                        // Tags
                        VStack(alignment: .leading) {
                            Text("标签")
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
        
                // Details Form (Answer & difficulty)
                VStack(alignment: .leading, spacing: 20) {
                    Text("题目详情")
                        .font(.headline)
                        .padding(.horizontal)
            
                    VStack(spacing: 0) {
                        // Difficulty
                        HStack {
                            Text("难度")
                            Spacer()
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { level in
                                    Image(systemName: level <= viewModel.difficulty.rawValue ? "star.fill" : "star")
                                        .foregroundStyle(level <= viewModel.difficulty.rawValue ? .orange : .gray.opacity(0.3))
                                        .onTapGesture {
                                            viewModel.difficulty = Difficulty(rawValue: level) ?? .one
                                        }
                                }
                            }
                        }
                        .padding()
                
                        Divider().padding(.leading)
                
                        // Grade/Mastery — HIG: 非 Form 上下文用 Picker(.menu)，右侧为点击区，弹出框锚定右侧
                        HStack {
                            Text("年级/程度")
                                .foregroundStyle(.primary)
                            Spacer()
                            Picker("年级/程度", selection: $viewModel.grade) {
                                Text("未选择").tag("")
                                ForEach(viewModel.availableGrades) { grade in
                                    Text(grade.name).tag(grade.name)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                        .padding()
                
                        Divider().padding(.leading)
                
                        // Answer
                        VStack(alignment: .leading, spacing: 12) {
                            Text("参考答案")
                            TextEditor(text: $viewModel.answerText)
                                .frame(minHeight: 80)
                                .scrollContentBackground(.hidden) // For iOS 16+
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
                                    Label("添加答案图片", systemImage: "photo.badge.plus")
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
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
                Button("保存") {
                    Task { await viewModel.saveResult() }
                }
                .fontWeight(.bold)
                .disabled(viewModel.isRecognizing)
            }
        }
        .navigationTitle("预览与编辑")
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
            viewModel.generateDraftIfNeeded()
            viewModel.cancelTasks()
        }
        .alert("保存失败", isPresented: $viewModel.showErrorAlert) {
            Button("好", role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// 移除 Preview 以避免繁琐的 Mock 数据注入依赖

