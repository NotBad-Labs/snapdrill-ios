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
struct LibraryEditView: View {

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

    init(item: ReviewItemModel) {
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
    
    private func loadData() {
        if viewModel == nil {
            viewModel = LibraryEditViewModel(item: item, repositories: repositories)
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
                    Label("移除答案图片", systemImage: "trash")
                }
            } else {
                PhotosPicker(selection: $answerPickerSelection, matching: .images) {
                    Label("添加答案图片", systemImage: "photo.badge.plus")
                }
            }
        }
    }
    
    private func metadataSection(vm: LibraryEditViewModel) -> some View {
        Section("属性") {
            subjectPicker(vm: vm)
            sourcePicker(vm: vm)
            gradePicker(vm: vm)
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
    
    private func gradePicker(vm: LibraryEditViewModel) -> some View {
        HStack {
            Text("年级/程度")
            Spacer()
            Menu {
                ForEach(vm.grades) { grade in
                    Button {
                        vm.grade = grade.name
                    } label: {
                        Text(grade.name)
                    }
                }
            } label: {
                HStack {
                    Text(vm.grade.isEmpty ? "选择年级" : vm.grade)
                        .foregroundStyle(vm.grade.isEmpty ? .secondary : .primary)
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
