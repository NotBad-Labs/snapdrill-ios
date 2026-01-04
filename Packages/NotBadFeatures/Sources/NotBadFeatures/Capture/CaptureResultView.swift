//
//  CaptureResultView.swift
//  NotBadFeatureCapture
//
//  Created by Yiming Liao on 2025/12/30.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  采集结果预览视图，提供裁剪、重拍和确认功能。
//

import SwiftUI
import NotBadData
import NotBadCore
import NotBadUI
import StoreKit
import SwiftData
import PhotosUI

/// 采集结果预览与编辑视图
struct CaptureResultView: View {
    @Bindable var router: CaptureRouter
    @Environment(\.modelContext) private var modelContext
    @Environment(\.analyticsService) private var analyticsService
    
    // 动态查询学科列表
    @Query(sort: \SubjectModel.sortOrder) private var subjects: [SubjectModel]
    @Query(sort: \SourceModel.sortOrder) private var sources: [SourceModel]
    @Query(sort: \TagModel.name) private var allTags: [TagModel]
    
    @State private var content: String
    @State private var image: UIImage?
    
    // String based
    @State private var selectedSubject: String = "数学"
    @State private var selectedSource: String = "试卷"
    
    // Tag Input State
    @State private var tagList: [String] = []
    @State private var tagInputText: String = ""
    
    // V2 Fields State
    @State private var answerText: String = ""
    @State private var difficulty: Int = 0
    @State private var grade: String = ""
    @State private var answerImage: UIImage?
    @State private var answerPhotoItem: PhotosPickerItem?
    
    @State private var isCropping = false
    @State private var isSaved = false  // Track if item was saved
    
    private let imageStorage = ImageStorage()
    
    init(router: CaptureRouter, content: String, image: UIImage?) {
        self.router = router
        _content = State(initialValue: content)
        _image = State(initialValue: image)
    }
    
    @State private var isRecognizing = false
    private let ocrService = OCRService()
    
    // ... init ...

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Image Preview
                if let image = image {
                    ZStack(alignment: .bottomTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay {
                                if isRecognizing {
                                    ZStack {
                                        Color.black.opacity(0.3)
                                        ProgressView()
                                            .tint(.white)
                                    }
                                }
                            }
                        
                        Button(action: {
                            isCropping = true
                        }, label: {
                            Image(systemName: "crop")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        })
                        .padding(8)
                        .disabled(isRecognizing)
                    }
                    .padding(.horizontal)
                    .onTapGesture {
                        isCropping = true
                    }
                }
                
                // Editor
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("题目内容")
                            .font(.headline)
                        if isRecognizing {
                            Text("正在重新识别...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    TextEditor(text: $content)
                        .font(.body)
                        .padding(12)
                        .frame(minHeight: 120)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .opacity(isRecognizing ? 0.6 : 1)
                        .disabled(isRecognizing)
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
                            TextField("选择或输入", text: $selectedSubject)
                                .multilineTextAlignment(.trailing)
                            
                            Menu {
                                ForEach(subjects) { subject in
                                    Button {
                                        selectedSubject = subject.name
                                    } label: {
                                        Label(subject.name, systemImage: subject.icon)
                                    }
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
                            TextField("选择或输入", text: $selectedSource)
                                .multilineTextAlignment(.trailing)
                            
                            Menu {
                                ForEach(sources) { source in
                                    Button {
                                        selectedSource = source.name
                                    } label: {
                                        Label(source.name, systemImage: source.icon)
                                    }
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
                                tags: $tagList,
                                text: $tagInputText,
                                suggestions: allTags.map { $0.name }
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
                                    Image(systemName: level <= difficulty ? "star.fill" : "star")
                                        .foregroundStyle(level <= difficulty ? .orange : .gray.opacity(0.3))
                                        .onTapGesture {
                                            difficulty = level
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
                            TextField("例如：高三", text: $grade)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        // Answer
                        VStack(alignment: .leading, spacing: 12) {
                            Text("参考答案")
                            TextEditor(text: $answerText)
                                .frame(minHeight: 80)
                                .scrollContentBackground(.hidden) // For iOS 16+
                                .background(Color(UIColor.tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            // Answer Image Picker
                            HStack {
                                if let answerImage {
                                    Image(uiImage: answerImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    Button(role: .destructive) {
                                        self.answerImage = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                }
                                
                                Spacer()
                                
                                PhotosPicker(selection: $answerPhotoItem, matching: .images) {
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("保存") {
                    saveAndDismiss()
                }
                .fontWeight(.bold)
                .disabled(isRecognizing)
            }
        }

        .navigationTitle("预览与编辑")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isCropping) {
            if let currentImage = image {
                ImageCropperView(
                    originalImage: currentImage,
                    onCrop: { croppedImage in
                        self.image = croppedImage
                        isCropping = false
                        reRecognizeText(from: croppedImage)
                    },
                    onCancel: {
                        isCropping = false
                    }
                )
                .ignoresSafeArea()
            }
        }
        .onDisappear {
            // Save draft if user leaves without saving
            if !isSaved, let image = image, !content.isEmpty {
                CaptureDraftService.shared.saveDraft(image: image, content: content)
            }
        }
        .onChange(of: answerPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let loadedImage = UIImage(data: data) {
                    await MainActor.run {
                        answerImage = loadedImage
                    }
                }
            }
        }
    }
    
    private func reRecognizeText(from image: UIImage) {
        isRecognizing = true
        Task {
            do {
                guard let cgImage = image.cgImage else {
                    throw OCRError.invalidImage
                }
                let newText = try await ocrService.recognizeText(from: cgImage)
                await MainActor.run {
                    self.content = newText
                    self.isRecognizing = false
                }
            } catch {
                print("Re-OCR failed: \(error)")
                await MainActor.run {
                    self.isRecognizing = false
                }
            }
        }
    }
    
    private func saveAndDismiss() {
        // Resolve Tags
        var tagModels: [TagModel] = []
        for name in tagList {
            let fetch = FetchDescriptor<TagModel>(predicate: #Predicate<TagModel> { $0.name == name })
            if let existing = try? modelContext.fetch(fetch).first {
                tagModels.append(existing)
            } else {
                let newTag = TagModel(name: name)
                modelContext.insert(newTag)
                tagModels.append(newTag)
            }
        }
        
        Task {
            var savedImagePath: String?
            if let image = image {
                do {
                    savedImagePath = try await imageStorage.saveImage(image)
                } catch {
                    print("Failed to save image: \(error)")
                }
            }
            
            // Save answer image
            var savedAnswerImagePath: String?
            if let answerImage {
                do {
                    savedAnswerImagePath = try await imageStorage.saveImage(answerImage)
                } catch {
                    print("Failed to save answer image: \(error)")
                }
            }
            
            await MainActor.run {
                let newItem = ReviewItemModel(
                    content: content,
                    imagePath: savedImagePath,
                    subject: selectedSubject,
                    source: selectedSource,
                    tags: tagModels,
                    answerText: answerText,
                    answerImagePath: savedAnswerImagePath,
                    difficulty: difficulty,
                    grade: grade
                )
                modelContext.insert(newItem)
                
                // Mark as saved (prevents draft save on disappear)
                isSaved = true
                CaptureDraftService.shared.clearDraft()
                
                // Analytics
                analyticsService.logEvent("capture_saved", properties: ["subject": selectedSubject])
                
                // Review Prompt
                let count = UserDefaults.standard.integer(forKey: "capture_save_count") + 1
                UserDefaults.standard.set(count, forKey: "capture_save_count")
                
                if count == 3 || count % 20 == 0 {
                    let scenes = UIApplication.shared.connectedScenes
                    if let scene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        AppStore.requestReview(in: scene)
                    }
                }
                
                // Feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // Pop to root (Capture Dashboard)
                router.path = .init()
            }
        }
    }
}

#Preview {
    NavigationStack {
        CaptureResultView(router: CaptureRouter(), content: "Sample recognized text from camera.", image: nil)
    }
    .modelContainer(for: [ReviewItemModel.self, TagModel.self], inMemory: true)
}
