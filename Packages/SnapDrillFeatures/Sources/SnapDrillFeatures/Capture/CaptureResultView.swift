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
    
    @State var viewModel: CaptureResultViewModel
    
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
                        // Subject
                        HStack {
                            Text("学科")
                            Spacer()
                            Text(viewModel.selectedSubject)
                                .foregroundStyle(.secondary)

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
                                    Label("新建学科", systemImage: "plus")
                                }
                            } label: {
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                
                        Divider().padding(.leading)
                
                        // Source
                        HStack {
                            Text("来源")
                            Spacer()
                            Text(viewModel.selectedSource)
                                .foregroundStyle(.secondary)

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
                                    Label("新建来源", systemImage: "plus")
                                }
                            } label: {
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundStyle(.secondary)
                            }
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
                
                        // Grade/Mastery
                        HStack {
                            Text("年级/程度")
                            Spacer()
                            Text(viewModel.grade.isEmpty ? "未选择" : viewModel.grade)
                                .foregroundStyle(viewModel.grade.isEmpty ? .tertiary : .secondary)

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
                                    Label("新建年级", systemImage: "plus")
                                }
                            } label: {
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundStyle(.secondary)
                            }
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
        }
        .alert("新建学科", isPresented: $viewModel.showNewSubjectAlert) {
            TextField("学科名称", text: $viewModel.newSubjectName)
            Button("创建") { viewModel.confirmNewSubject() }
            Button("取消", role: .cancel) { viewModel.newSubjectName = "" }
        } message: {
            Text("输入新学科名称，创建后自动选中")
        }
        .alert("新建来源", isPresented: $viewModel.showNewSourceAlert) {
            TextField("来源名称", text: $viewModel.newSourceName)
            Button("创建") { viewModel.confirmNewSource() }
            Button("取消", role: .cancel) { viewModel.newSourceName = "" }
        } message: {
            Text("输入新来源名称，创建后自动选中")
        }
        .alert("新建年级", isPresented: $viewModel.showNewGradeAlert) {
            TextField("年级名称", text: $viewModel.newGradeName)
            Button("创建") { viewModel.confirmNewGrade() }
            Button("取消", role: .cancel) { viewModel.newGradeName = "" }
        } message: {
            Text("输入新年级名称，创建后自动选中")
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

