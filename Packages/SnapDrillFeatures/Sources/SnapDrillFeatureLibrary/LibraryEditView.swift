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

    /// 要编辑的题目数据模型
    let item: ReviewItemModel

    @State private var viewModel: LibraryEditViewModel?
    @FocusState private var isInputFocused: Bool

    @State private var tagInputText: String = ""
    @State private var isPickerPresented = false
    @State private var pickerSelection: PhotosPickerItem?
    @State private var answerPickerSelection: PhotosPickerItem?

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
            .onTapGesture {
                isInputFocused = false
            }
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
            // Image Picker
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
    
    private func loadData() async {
        if viewModel == nil {
            viewModel = LibraryEditViewModel(item: item, repositories: repositories)
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
                } else {
                    ContentUnavailableView(L10n.Library.noImage, systemImage: "photo.badge.exclamationmark")
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
                Label(L10n.Library.changeImage, systemImage: "arrow.triangle.2.circlepath.camera")
            })
            .disabled(vm.isProcessing)
        }
    }
    
    private func contentSection(vm: LibraryEditViewModel) -> some View {
        Section(L10n.Library.questionText) {
            TextEditor(text: Binding(get: { vm.content }, set: { vm.content = $0 }))
                .frame(minHeight: 120)
                .focused($isInputFocused)
        }
    }
    
    private func answerSection(vm: LibraryEditViewModel) -> some View {
        Section(L10n.Library.answerSection) {
            TextEditor(text: Binding(get: { vm.answer }, set: { vm.answer = $0 }))
                .frame(minHeight: 100)
                .focused($isInputFocused)

            if let answerImage = vm.answerDisplayedImage {
                Image(uiImage: answerImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .listRowInsets(EdgeInsets())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)

                Button(role: .destructive) {
                    vm.removeAnswerImage()
                } label: {
                    Label(L10n.Library.removeAnswerImage, systemImage: "trash")
                }
            } else {
                PhotosPicker(selection: $answerPickerSelection, matching: .images) {
                    Label(L10n.Library.addAnswerImage, systemImage: "photo.badge.plus")
                }
            }
        }
    }
    
    private func metadataSection(vm: LibraryEditViewModel) -> some View {
        Section(L10n.Library.metadata) {
            subjectPicker(vm: vm)
            sourcePicker(vm: vm)
            gradePicker(vm: vm)
            difficultyPicker(vm: vm)
            
            VStack(alignment: .leading) {
                Text(L10n.Library.filterTags)
                TagInputView(
                    tags: Binding(get: { vm.tagList }, set: { vm.tagList = $0 }),
                    text: $tagInputText,
                    suggestions: vm.allTags.map { $0.name }
                )
            }
        }
    }
    
    private func subjectPicker(vm: LibraryEditViewModel) -> some View {
        // HIG: Form 上下文 Picker(.menu)，整行自动可点，弹出框锚定右侧，左侧标签始终可见
        Picker(L10n.Library.filterSubjects, selection: Binding(get: { vm.selectedSubject }, set: { vm.selectedSubject = $0 })) {
            Text(L10n.Library.filterSubjects).tag("")
            ForEach(vm.subjects) { subject in
                Label(subject.name, systemImage: subject.icon).tag(subject.name)
            }
        }
        .pickerStyle(.menu)
    }

    private func sourcePicker(vm: LibraryEditViewModel) -> some View {
        // HIG: Form 上下文 Picker(.menu)，整行自动可点，弹出框锚定右侧，左侧标签始终可见
        Picker(L10n.Capture.source, selection: Binding(get: { vm.selectedSource }, set: { vm.selectedSource = $0 })) {
            Text(L10n.Capture.source).tag("")
            ForEach(vm.sources) { source in
                Label(source.name, systemImage: source.icon).tag(source.name)
            }
        }
        .pickerStyle(.menu)
    }

    private func gradePicker(vm: LibraryEditViewModel) -> some View {
        // HIG: Form 上下文 Picker(.menu)，整行自动可点，弹出框锚定右侧，左侧标签始终可见
        Picker(L10n.Capture.grade, selection: Binding(get: { vm.grade }, set: { vm.grade = $0 })) {
            Text(L10n.Capture.grade).tag("")
            ForEach(vm.grades) { grade in
                Text(grade.name).tag(grade.name)
            }
        }
        .pickerStyle(.menu)
    }

    private func difficultyPicker(vm: LibraryEditViewModel) -> some View {
        HStack {
            Text(L10n.Capture.difficulty)
            Spacer()
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: vm.difficulty.rawValue >= star ? "star.fill" : "star")
                        .foregroundStyle(.yellow)
                        .onTapGesture {
                            vm.difficulty = Difficulty(rawValue: star) ?? .one
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

#Preview {
    let schema = Schema([ReviewItemModel.self, SubjectModel.self, SourceModel.self, TagModel.self, GradeModel.self])
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    let item: ReviewItemModel = {
        let i = ReviewItemModel(content: "Sample Question", subject: "Math")
        container.mainContext.insert(i)
        return i
    }()
    NavigationStack {
        LibraryEditView(item: item)
    }
    .modelContainer(container)
}
