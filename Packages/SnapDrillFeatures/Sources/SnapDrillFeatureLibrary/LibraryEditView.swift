//
//  LibraryEditView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  错题编辑页面，用于修改题目内容、标签和学科。
//

import SwiftUI
import SwiftData
import SnapDrillCore
import SnapDrillData
import SnapDrillUI
import PhotosUI

/// 题目编辑视图
public struct LibraryEditView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Environment(\.repositories) private var repositories
    @Environment(\.profileManager) private var profileManager

    /// 要编辑的题目数据模型
    let item: ReviewItemModel

    @State private var viewModel: LibraryEditViewModel?
    @FocusState private var isInputFocused: Bool

    @State private var isPickerPresented = false
    @State private var pickerSelection: PhotosPickerItem?
    @State private var answerPickerSelection: PhotosPickerItem?
    @State private var cropperItem: CropperItem?

    public init(item: ReviewItemModel) {
        self.item = item
    }
    
    // MARK: - Body
    
    public var body: some View {
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
            .accessibilityIdentifier("library.edit.root")
            .navigationTitle(L10n.Library.editTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        viewModel?.saveDraftIfNeeded()
                        dismiss()
                    }, label: {
                        Text(L10n.Common.cancel)
                    })
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.save) {
                        if let vm = viewModel {
                            Task {
                                await vm.save()
                                // 仅保存成功时关闭页面，失败时留在原地显示错误
                                if vm.isSavedNormally {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .disabled((viewModel?.isProcessing ?? false) || (viewModel?.isSaving ?? false))
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .task {
                await loadData()
            }
            .onDisappear {
                viewModel?.cancelTasks()
            }
            .alert(L10n.Errors.saveFailed, isPresented: Binding(
                get: { viewModel?.showErrorAlert ?? false },
                set: { viewModel?.showErrorAlert = $0 }
            )) {
                Button(L10n.Common.ok) {}
            } message: {
                Text(viewModel?.errorMessage ?? "")
            }
        }
        // 图片选择器
        .photosPicker(isPresented: $isPickerPresented, selection: $pickerSelection, matching: .images)
        .onChange(of: pickerSelection) { _, newItem in
            if let newItem {
                loadTransferable(from: newItem)
            }
        }
        .onChange(of: answerPickerSelection) { _, newItem in
            if let newItem {
                loadAnswerTransferable(from: newItem)
            }
        }
        // 裁剪器
        .fullScreenCover(item: $cropperItem) { item in
            ImageCropperView(
                originalImage: item.image,
                onCrop: { cropped in
                    cropperItem = nil
                    viewModel?.handleNewImage(cropped)
                },
                onCancel: {
                    cropperItem = nil
                }
            )
            .ignoresSafeArea()
        }
    }
    
    private func loadData() async {
        if viewModel == nil {
            viewModel = LibraryEditViewModel(
                item: item,
                repositories: repositories,
                imageStorage: profileManager.activeImageStorage
            )
        }
        await viewModel?.loadData()
    }
    
    // MARK: - Subviews
    
    private func imageSection(vm: LibraryEditViewModel) -> some View {
        Section(L10n.Library.questionImage) {
            ZStack {
                if let image = vm.displayedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .accessibleImage(label: L10n.Library.questionImage)
                        .accessibilityIdentifier("library.edit.questionImage")
                } else if vm.imageLoadFailed {
                    // 图片加载失败占位
                    ContentUnavailableView(L10n.Errors.imageLoadFailed, systemImage: "photo.badge.exclamationmark")
                        .frame(height: 150)
                } else if item.imagePath != nil {
                    // 有图片路径但尚未加载完成（async I/O）
                    ProgressView()
                        .frame(height: 150)
                } else {
                    ContentUnavailableView(L10n.Library.noImage, systemImage: "photo.badge.exclamationmark")
                        .frame(height: 150)
                }
                
                // 加载遮罩
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
                Label(L10n.Library.changeImage, systemImage: "arrow.triangle.2.circlepath.camera")
            })
            .disabled(vm.isProcessing)
            .accessibilityIdentifier("library.edit.changeImage")

            if let image = vm.displayedImage {
                Button {
                    cropperItem = CropperItem(image: image)
                } label: {
                    Label(L10n.Accessibility.cropImage, systemImage: "crop")
                }
                .accessibleButton(
                    label: L10n.Accessibility.cropImage,
                    hint: L10n.Accessibility.cropImageHint
                )
                .disabled(vm.isProcessing)
                .accessibilityIdentifier("library.edit.cropImage")
            }
        }
    }
    
    private func contentSection(vm: LibraryEditViewModel) -> some View {
        Section(L10n.Library.questionText) {
            TextEditor(text: Binding(get: { vm.content }, set: { vm.content = $0 }))
                .frame(minHeight: 120)
                .focused($isInputFocused)
                .accessibilityIdentifier("library.edit.contentEditor")
        }
    }
    
    private func answerSection(vm: LibraryEditViewModel) -> some View {
        Section(L10n.Library.answerSection) {
            TextEditor(text: Binding(get: { vm.answer }, set: { vm.answer = $0 }))
                .frame(minHeight: 100)
                .focused($isInputFocused)
                .accessibilityIdentifier("library.edit.answerEditor")

            if let answerImage = vm.answerDisplayedImage {
                Image(uiImage: answerImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibleImage(label: L10n.Library.answerSection)
                    .listRowInsets(EdgeInsets())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    .accessibilityIdentifier("library.edit.answerImage")

                Button(role: .destructive) {
                    vm.removeAnswerImage()
                } label: {
                    Label(L10n.Library.removeAnswerImage, systemImage: "trash")
                }
                .accessibilityIdentifier("library.edit.removeAnswerImage")
            } else if item.answerImagePath != nil && !vm.isAnswerImageCleared {
                // 有答案图路径但尚未加载完成（排除已删除待保存的情况）
                ProgressView()
                    .frame(height: 100)
            } else {
                PhotosPicker(selection: $answerPickerSelection, matching: .images) {
                    Label(L10n.Library.addAnswerImage, systemImage: "photo.badge.plus")
                }
                .accessibilityIdentifier("library.edit.addAnswerImage")
            }
        }
    }
    
    private func metadataSection(vm: LibraryEditViewModel) -> some View {
        Section(L10n.Library.metadata) {
            ForEach(vm.visibleDimensionInputModels()) { model in
                DimensionInputRow(
                    model: model,
                    selectedIds: vm.selectedIds(forDimension: model.id),
                    onToggle: { vm.toggleValue($0, inDimension: model.id) },
                    onCreateValue: { vm.createValue(name: $0, inDimension: model.id) }
                )
            }
            difficultyPicker(vm: vm)
        }
    }

    private func difficultyPicker(vm: LibraryEditViewModel) -> some View {
        HStack {
            Text(L10n.Capture.difficulty)
            Spacer()
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        vm.difficulty = Difficulty(rawValue: star) ?? .one
                    } label: {
                        Image(systemName: vm.difficulty.rawValue >= star ? "star.fill" : "star")
                            .foregroundStyle(.yellow)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .accessibilityLabel(L10n.Accessibility.starRating(difficulty: star))
                    .accessibilityAddTraits(vm.difficulty.rawValue >= star ? .isSelected : [])
                    .accessibilityIdentifier("library.edit.difficulty.\(star)")
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
                        self.cropperItem = CropperItem(image: uiImage)
                    }
                }
            case .failure(let error):
                SnapDrillLogger.generic.info("Failed to load image: \(error)")
            }
        }
    }

    private func loadAnswerTransferable(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let uiImage = UIImage(data: data) {
                    Task { @MainActor in
                        self.viewModel?.handleNewAnswerImage(uiImage)
                    }
                }
            case .failure(let error):
                SnapDrillLogger.generic.info("加载答案图片失败: \(error)")
            }
        }
    }
}

private struct CropperItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

#Preview {
    let schema = Schema(SnapDrillSchemaV1.models)
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    let item: ReviewItemModel = {
        let i = ReviewItemModel(content: "Sample Question")
        container.mainContext.insert(i)
        return i
    }()
    NavigationStack {
        LibraryEditView(item: item)
    }
    .modelContainer(container)
}
