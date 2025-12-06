//
//  CaptureView.swift
//  NotBad
//
//  错题录入视图
//  功能闭环：拍照 → OCR 识别 → 存图 → 写入数据库
//

import SwiftUI

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var note = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isRecognizing = false
    @State private var recognizedText = ""
    @State private var showSaveSuccess = false
    
    // OCR 服务（直接使用，无需包装）
    private let ocrService = OCRService.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section("图片") {
                    imageSection
                }
                
                if isRecognizing {
                    Section {
                        HStack {
                            ProgressView()
                            Text("正在识别文字...")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("信息") {
                    TextField("标题", text: $title)
                    TextField("笔记", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if !recognizedText.isEmpty {
                    Section("识别结果") {
                        Text(recognizedText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    Button(action: saveItem) {
                        HStack {
                            Spacer()
                            Label("保存错题", systemImage: "checkmark.circle.fill")
                            Spacer()
                        }
                    }
                    .disabled(title.isEmpty && selectedImage == nil)
                }
            }
            .navigationTitle("录入错题")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onChange(of: selectedImage) { _, newImage in
                if let image = newImage {
                    performOCR(on: image)
                }
            }
            .sensoryFeedback(.success, trigger: showSaveSuccess)
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var imageSection: some View {
        if let image = selectedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onTapGesture { showImagePicker = true }
                .accessibilityLabel("已选择的图片")
                .accessibilityHint("点击更换图片")
        } else {
            Button {
                showImagePicker = true
            } label: {
                Label("选择图片", systemImage: "photo.on.rectangle.angled")
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
            }
            .accessibilityHint("从相册选择错题图片")
        }
    }
    
    // MARK: - OCR
    
    private func performOCR(on image: UIImage) {
        isRecognizing = true
        recognizedText = ""
        
        Task {
            do {
                let text = try await ocrService.recognizeText(from: image)
                recognizedText = text
                
                // 自动填充标题（如果为空）
                if title.isEmpty {
                    title = ocrService.extractTitle(from: text)
                }
            } catch {
                recognizedText = "识别失败: \(error.localizedDescription)"
            }
            isRecognizing = false
        }
    }
    
    // MARK: - Save
    
    private func saveItem() {
        let item = ReviewItemModel(
            title: title,
            note: note.isEmpty ? recognizedText : note
        )
        
        // 保存图片到磁盘（使用 ImageStorageService）
        if let image = selectedImage {
            item.imagePath = ImageStorageService.shared.save(image: image, with: item.id)
        }
        
        modelContext.insert(item)
        
        // 触觉反馈
        showSaveSuccess.toggle()
        
        // 重置表单
        title = ""
        note = ""
        selectedImage = nil
        recognizedText = ""
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
