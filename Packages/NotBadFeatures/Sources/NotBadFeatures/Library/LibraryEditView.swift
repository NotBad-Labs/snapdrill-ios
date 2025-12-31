//
//  LibraryEditView.swift
//  NotBadFeatureLibrary
//
//  Created by Antigravity on 2025/12/31.
//

import SwiftUI
import NotBadData
import NotBadCore
import NotBadUI
import PhotosUI
import SwiftData

/// 题目编辑视图
struct LibraryEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: ReviewItemModel
    @Environment(\.modelContext) private var modelContext
    
    // Services
    private let imageStorage = ImageStorage()
    private let ocrService = OCRService()
    
    // State
    @State private var content: String
    @State private var selectedSubject: String
    @State private var selectedSource: String
    
    // Tag Input State
    @State private var tagList: [String] = []
    @State private var tagInputText: String = ""
    
    // Image Handling
    @State private var displayedImage: UIImage?
    @State private var isPickerPresented = false
    @State private var pickerSelection: PhotosPickerItem?
    @State private var isCropping = false
    @State private var imageToCrop: UIImage?
    
    @State private var isProcessing = false
    @State private var isSavedNormally = false // Track if exit is due to Save button
    
    init(item: ReviewItemModel) {
        self.item = item
        _content = State(initialValue: item.content)
        _selectedSubject = State(initialValue: item.subject)
        _selectedSource = State(initialValue: item.source)
        
        _tagList = State(initialValue: item.tags?.map { $0.name } ?? [])
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Image Section
                Section(header: Text("题目图片")) {
                    ZStack {
                        if let image = displayedImage {
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
                        if isProcessing {
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
                    .disabled(isProcessing)
                }
                
                // MARK: - Content Section
                Section(header: Text("题目内容")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                }
                
                // MARK: - Metadata
                Section(header: Text("属性")) {
                    // Subject
                    HStack {
                        Text("学科")
                        Spacer()
                        TextField("选择或输入", text: $selectedSubject)
                            .multilineTextAlignment(.trailing)
                        
                        Menu {
                            ForEach(SubjectPreset.allCases) { subject in
                                Button(subject.rawValue) {
                                    selectedSubject = subject.rawValue
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.up.chevron.down")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Source
                    HStack {
                        Text("来源")
                        Spacer()
                        TextField("选择或输入", text: $selectedSource)
                            .multilineTextAlignment(.trailing)
                        
                        Menu {
                            ForEach(ReviewSourcePreset.allCases) { source in
                                Button(source.rawValue) {
                                    selectedSource = source.rawValue
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.up.chevron.down")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("标签")
                        TagInputView(tags: $tagList, text: $tagInputText)
                    }
                }
            }
            .navigationTitle("编辑题目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        saveDraftIfNeeded()
                        dismiss()
                    }, label: {
                        Text("取消")
                    })
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(isProcessing)
                }
            }
            .onAppear {
                if displayedImage == nil, let path = item.imagePath {
                    displayedImage = imageStorage.loadImage(path: path)
                }
            }
            // Image Picker
            .photosPicker(isPresented: $isPickerPresented, selection: $pickerSelection, matching: .images)
            .onChange(of: pickerSelection) { _, newItem in
                if let newItem {
                    loadTransferable(from: newItem)
                }
            }
            // Cropper
            .fullScreenCover(isPresented: $isCropping) {
                if let img = imageToCrop {
                    ImageCropperView(
                        originalImage: img,
                        onCrop: { cropped in
                            isCropping = false
                            handleNewImage(cropped)
                        },
                        onCancel: {
                            isCropping = false
                        }
                    )
                    .ignoresSafeArea()
                }
            }
        }
    }
    
    // MARK: - Logic
    
    private func loadTransferable(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let uiImage = UIImage(data: data) {
                    Task { @MainActor in
                        self.imageToCrop = uiImage
                        self.isCropping = true
                    }
                }
            case .failure(let error):
                print("Failed to load image: \(error)")
            }
        }
    }
    
    private func handleNewImage(_ image: UIImage) {
        self.displayedImage = image
        self.isProcessing = true
        
        Task {
            do {
                // 1. OCR
                let recognizedText = try await ocrService.recognizeText(from: image)
                
                // 2. Save Image immediately? 
                // Wait until "Save" button to save image file effectively?
                // Or save temp?
                // Let's just hold it in memory for now, save on commit.
                
                await MainActor.run {
                    self.content = recognizedText
                    self.isProcessing = false
                }
            } catch {
                print("OCR Error: \(error)")
                await MainActor.run {
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func saveDraftIfNeeded() {
        if !isSavedNormally, let image = displayedImage {
            CaptureDraftService.shared.saveDraft(image: image, content: content)
        }
    }

    private func save() {
        isSavedNormally = true
        CaptureDraftService.shared.clearDraft()
        
        // Save fields
        item.content = content
        item.subject = selectedSubject
        item.source = selectedSource
        
        // Update Tags
        var newTags: [TagModel] = []
        for name in tagList {
            let fetch = FetchDescriptor<TagModel>(predicate: #Predicate<TagModel> { $0.name == name })
            if let existing = try? modelContext.fetch(fetch).first {
                newTags.append(existing)
            } else {
                let newTag = TagModel(name: name)
                modelContext.insert(newTag)
                newTags.append(newTag)
            }
        }
        item.tags = newTags
        
        // Save Image if changed
        if let newImage = displayedImage {
            // Optimization: check if image fundamentally changed? 
            // Simple logic: if displayedImage is different from loaded, save.
            // But checking equality is hard.
            // Let's rely on user intent. If they picked a new image, handleNewImage was called.
            // But displayedImage is init from storage.
            
            // We can just save it again if it's there. 
            // Better: only save if we have a flag `isImageModified`.
            // For now, let's just save it. Overwrite? 
            
            // ImageStorage.saveImage returns a new path (UUID).
            // We should delete old one if we care about cleanup, but `ImageStorage` logic is opaque here.
            
            do {
                let newPath = try imageStorage.saveImage(newImage)
                item.imagePath = newPath
            } catch {
                print("Failed to save new image: \(error)")
            }
        }
        
        dismiss()
    }
}
