//
//  OCRResultEditView.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//

import SwiftUI

/// OCR结果编辑视图 - Phase 1实现
struct OCRResultEditView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    
    @State private var recognizedText: String = ""
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var subject = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var isSaving = false
    
    @StateObject private var ocrService = OCRServiceManager.shared
    
    // 依赖注入 - 从父视图传递
    let createReviewItemUseCase: CreateReviewItemUseCase
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isProcessing {
                    processingView
                } else {
                    contentView
                }
            }
            .navigationTitle("编辑错题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            await saveReviewItem()
                        }
                    }
                    .disabled(recognizedText.isEmpty || isSaving)
                }
            }
        }
        .task {
            await performOCR()
        }
        .alert("识别错误", isPresented: $showingError) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
            
            Text("正在识别文字...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 图片预览
                imagePreview
                
                // 识别结果编辑
                textEditSection
                
                // 分类和标签
                classificationSection
                
                // 标签管理
                tagsSection
            }
            .padding()
        }
    }
    
    private var imagePreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("原图")
                .font(.headline)
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)
                .cornerRadius(12)
                .clipped()
        }
    }
    
    private var textEditSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("识别内容")
                .font(.headline)
            
            TextEditor(text: $recognizedText)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
    
    private var classificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("学科分类")
                .font(.headline)
            
            HStack {
                TextField("输入学科", text: $subject)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Menu("选择学科") {
                    Button("数学") { subject = "数学" }
                    Button("语文") { subject = "语文" }
                    Button("英语") { subject = "英语" }
                    Button("物理") { subject = "物理" }
                    Button("化学") { subject = "化学" }
                    Button("生物") { subject = "生物" }
                    Button("历史") { subject = "历史" }
                    Button("地理") { subject = "地理" }
                    Button("政治") { subject = "政治" }
                }
            }
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("知识点标签")
                .font(.headline)
            
            // 添加新标签
            HStack {
                TextField("添加标签", text: $newTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("添加") {
                    addTag()
                }
                .disabled(newTag.isEmpty)
            }
            
            // 标签列表
            if !tags.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                                .font(.caption)
                            Button(action: {
                                removeTag(tag)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private func performOCR() async {
        isProcessing = true
        
        do {
            let result = try await ocrService.recognizeText(from: image)
            await MainActor.run {
                recognizedText = result.text
                isProcessing = false
                
                // 自动推荐学科（简单实现）
                if recognizedText.contains("数学") || recognizedText.contains("方程") || recognizedText.contains("函数") {
                    subject = "数学"
                } else if recognizedText.contains("语文") || recognizedText.contains("阅读") || recognizedText.contains("作文") {
                    subject = "语文"
                } else if recognizedText.contains("英语") || recognizedText.contains("English") {
                    subject = "英语"
                }
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    @MainActor
    private func saveReviewItem() async {
        isSaving = true
        
        do {
            // 将UIImage转换为Data
            let imageData = image.jpegData(compressionQuality: 0.8)
            
            // 调用UseCase创建ReviewItem
                _ = try await createReviewItemUseCase.execute(
                imageData: imageData,
                recognizedText: recognizedText,
                userNotes: "", // 用户笔记暂时为空
                subject: subject,
                tags: tags
            )
            
            // 保存成功，关闭视图
            isPresented = false
            
        } catch {
            isSaving = false
            errorMessage = "保存失败: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    let mockUseCase = CreateReviewItemUseCaseImpl(repository: MockReviewItemRepository())
    return OCRResultEditView(
        image: UIImage(systemName: "photo")!,
        isPresented: .constant(true),
        createReviewItemUseCase: mockUseCase
    )
}
