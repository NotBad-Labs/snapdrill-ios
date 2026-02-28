//
//  LibraryEditView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  错题编辑页面，用于修改题目内容、标签和学科。
//

import SwiftUI
import SnapDrillCore
import SnapDrillDomain
import SnapDrillUI
import PhotosUI

/// 题目编辑视图
struct LibraryEditView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.useCases) private var useCases
    
    /// 要编辑的题目数据模型 (Domain)
    let item: ReviewItem
    
    @State private var viewModel: LibraryEditViewModel?
    @FocusState private var isInputFocused: Bool
    
    @State private var tagInputText: String = ""
    @State private var isPickerPresented = false
    @State private var pickerSelection: PhotosPickerItem?
    
    init(item: ReviewItem) {
        self.item = item
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                if let vm = viewModel {
                    imageSection(vm: vm)
                    contentSection(vm: vm)
                    answerSection(vm: vm)
                    metadataSection(vm: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("编辑题目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        viewModel?.saveDraftIfNeeded()
                        dismiss()
                    }, label: {
                        Text("取消")
                    })
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let vm = viewModel {
                            Task {
                                await vm.save()
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel?.isProcessing ?? false)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .onTapGesture {
                isInputFocused = false
            }
            .onAppear {
                loadData()
            }
            // Image Picker
            .photosPicker(isPresented: $isPickerPresented, selection: $pickerSelection, matching: .images)
            .onChange(of: pickerSelection) { _, newItem in
                if let newItem {
                    loadTransferable(from: newItem)
                }
            }
            // Cropper
            .fullScreenCover(isPresented: Binding(
                get: { viewModel?.isCropping ?? false },
                set: { viewModel?.isCropping = $0 }
            )) {
                if let vm = viewModel, let img = vm.imageToCrop {
                    ImageCropperView(
                        originalImage: img,
                        onCrop: { cropped in
                            vm.isCropping = false
                            vm.handleNewImage(cropped)
                        },
                        onCancel: {
                            vm.isCropping = false
                        }
                    )
                    .ignoresSafeArea()
                }
            }
        }
    }
    
    private func loadData() {
        if viewModel == nil {
            viewModel = LibraryEditViewModel(
                item: item,
                reviewUseCase: useCases.review,
                taxonomyUseCase: useCases.taxonomy
            )
        }
        viewModel?.loadData()
    }
    
    // MARK: - Subviews
    
    private func imageSection(vm: LibraryEditViewModel) -> some View {
        Section("题目图片") {
            ZStack {
                if let image = vm.displayedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    ContentUnavailableView("无图片", systemImage: "photo.badge.exclamationmark")
                        .frame(height: 150)
                }
                
                // Loading Overlay
                if vm.isProcessing {
                    Color.black.opacity(0.3)
                    ProgressView()
                        .tint(.white)
                }
            }
            .listRowInsets(EdgeInsets())
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
            
            Button(action: {
                isPickerPresented = true
            }, label: {
                Label("更换图片 & 重新识别", systemImage: "arrow.triangle.2.circlepath.camera")
            })
            .disabled(vm.isProcessing)
        }
    }
    
    private func contentSection(vm: LibraryEditViewModel) -> some View {
        Section("题目内容") {
            TextEditor(text: Binding(get: { vm.content }, set: { vm.content = $0 }))
                .frame(minHeight: 120)
                .focused($isInputFocused)
        }
    }
    
    private func answerSection(vm: LibraryEditViewModel) -> some View {
        Section("参考答案") {
            TextEditor(text: Binding(get: { vm.answer }, set: { vm.answer = $0 }))
                .frame(minHeight: 100)
                .focused($isInputFocused)
        }
    }
    
    private func metadataSection(vm: LibraryEditViewModel) -> some View {
        Section("属性") {
            subjectPicker(vm: vm)
            sourcePicker(vm: vm)
            difficultyPicker(vm: vm)
            
            VStack(alignment: .leading) {
                Text("标签")
                TagInputView(
                    tags: Binding(get: { vm.tagList }, set: { vm.tagList = $0 }),
                    text: $tagInputText,
                    suggestions: vm.allTags.map { $0.name }
                )
            }
        }
    }
    
    private func subjectPicker(vm: LibraryEditViewModel) -> some View {
        HStack {
            Text("学科")
            Spacer()
            
            Menu {
                ForEach(vm.subjects) { subject in
                    Button {
                        vm.selectedSubject = subject.name
                    } label: {
                        Label(subject.name, systemImage: subject.icon)
                    }
                }
            } label: {
                HStack {
                    Text(vm.selectedSubject.isEmpty ? "选择学科" : vm.selectedSubject)
                        .foregroundStyle(vm.selectedSubject.isEmpty ? .secondary : .primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
    
    private func sourcePicker(vm: LibraryEditViewModel) -> some View {
        HStack {
            Text("来源")
            Spacer()
            
            Menu {
                ForEach(vm.sources) { source in
                    Button {
                        vm.selectedSource = source.name
                    } label: {
                        Label(source.name, systemImage: source.icon)
                    }
                }
            } label: {
                HStack {
                    Text(vm.selectedSource.isEmpty ? "选择来源" : vm.selectedSource)
                        .foregroundStyle(vm.selectedSource.isEmpty ? .secondary : .primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
    
    private func difficultyPicker(vm: LibraryEditViewModel) -> some View {
        HStack {
            Text("难度")
            Spacer()
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: vm.difficulty >= star ? "star.fill" : "star")
                        .foregroundStyle(.yellow)
                        .onTapGesture {
                            vm.difficulty = star
                        }
                }
            }
        }
    }
    
    private func loadTransferable(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let uiImage = UIImage(data: data) {
                    Task { @MainActor in
                        self.viewModel?.imageToCrop = uiImage
                        self.viewModel?.isCropping = true
                    }
                }
            case .failure(let error):
                SnapDrillLogger.generic.info("Failed to load image: \(error)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        LibraryEditView(
            item: ReviewItem(id: UUID(), content: "Sample Domain Question", subject: "Math")
        )
    }
}
