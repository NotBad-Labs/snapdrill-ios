//
//  CaptureView.swift
//  NotBad
//
//  错题录入 - iOS 26 现代化设计
//

import SwiftUI
import PhotosUI
import SwiftData

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    
    // 图片选择
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var selectedImageData: Data?
    @State private var selectedUIImage: UIImage?
    
    // 表单数据
    @State private var title: String = ""
    @State private var note: String = ""
    @State private var subject: String = "数学"
    @State private var grade: String = "高一"
    @State private var tags: String = ""
    
    // UI 状态
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showCamera = false
    @State private var showImageSourcePicker = false
    @State private var isRecognizingText = false
    @State private var hasTriedOCR = false
    @State private var recognizedText = ""
    
    let subjects = ["语文", "数学", "英语", "物理", "化学", "生物", "历史", "地理", "政治", "其他"]
    let grades = ["小学", "七年级", "八年级", "九年级", "高一", "高二", "高三", "大学", "成人"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if selectedUIImage == nil {
                        // 图片选择入口
                        imageSelectionPrompt
                    } else {
                        // 已选择图片的完整流程
                        imagePreviewSection
                        
                        if !hasTriedOCR {
                            ocrPromptCard
                        }
                        
                        if !recognizedText.isEmpty {
                            recognizedTextCard
                        }
                        
                        formSection
                        saveButton
                    }
                }
                .padding()
            }
            .navigationTitle("录入错题")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: selectedItem) { _, newValue in
                loadTransferable(from: newValue)
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera) { image in
                    handlePickedImage(image)
                }
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("好的") {
                    if alertMessage.contains("保存成功") {
                        resetForm()
                    }
                }
            }
        }
    }
    
    // MARK: - 图片选择入口（iOS 26 现代化设计）
    
    private var imageSelectionPrompt: some View {
        VStack(spacing: 24) {
            // Hero 区域
            VStack(spacing: 12) {
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.bounce, value: selectedUIImage == nil)
                
                Text("记录错题，高效复习")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("拍照或选择图片，智能识别文字")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
            
            // 操作卡片
            VStack(spacing: 16) {
                // 拍照按钮
                Button {
                    showCamera = true
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.blue.gradient)
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("拍照录入")
                                .font(.headline)
                            Text("使用相机拍摄错题")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                
                // 相册选择
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.green.gradient)
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("从相册选择")
                                .font(.headline)
                            Text("选择已有的错题照片")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
    }
    
    // MARK: - 图片预览（现代化）
    
    private var imagePreviewSection: some View {
        VStack(spacing: 12) {
            if let selectedImage {
                selectedImage
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    .overlay(alignment: .topTrailing) {
                        Button {
                            showImageSourcePicker = true
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                                .shadow(radius: 3)
                        }
                        .padding(12)
                    }
                    .confirmationDialog("选择图片来源", isPresented: $showImageSourcePicker) {
                        Button("重新拍照") {
                            showCamera = true
                        }
                        Button("从相册选择") {
                            // PhotosPicker 会处理
                        }
                        Button("取消", role: .cancel) {}
                    }
            }
        }
    }
    
    // MARK: - OCR 提示卡片（现代化）
    
    private var ocrPromptCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.orange.gradient)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("智能识别")
                        .font(.headline)
                    Text("自动识别图片中的文字内容")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button {
                    recognizeText()
                } label: {
                    HStack {
                        if isRecognizingText {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "wand.and.stars")
                        }
                        Text(isRecognizingText ? "识别中..." : "开始识别")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange.gradient, in: Capsule())
                    .foregroundStyle(.white)
                }
                .disabled(isRecognizingText)
                
                Button {
                    withAnimation {
                        hasTriedOCR = true
                    }
                } label: {
                    Text("跳过")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(width: 80)
                }
            }
        }
        .padding()
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - 识别结果卡片（现代化）
    
    private var recognizedTextCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("识别结果")
                    .font(.headline)
                Spacer()
            }
            
            Text(recognizedText)
                .font(.callout)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
            
            Label("已自动填充到下方表单", systemImage: "arrow.down.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - 表单区域（现代化）
    
    private var formSection: some View {
        VStack(spacing: 20) {
            // 标题
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("标题")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text("*")
                        .foregroundStyle(.red)
                }
                
                TextField("例如：数学-三角函数", text: $title)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
            }
            
            // 学科和年级
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("学科")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Menu {
                        ForEach(subjects, id: \.self) { subject in
                            Button(subject) {
                                self.subject = subject
                            }
                        }
                    } label: {
                        HStack {
                            Text(subject)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("年级")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Menu {
                        ForEach(grades, id: \.self) { grade in
                            Button(grade) {
                                self.grade = grade
                            }
                        }
                    } label: {
                        HStack {
                            Text(grade)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            
            // 标签
            VStack(alignment: .leading, spacing: 8) {
                Text("知识点标签")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                TextField("例如：函数, 导数", text: $tags)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
            }
            
            // 笔记
            VStack(alignment: .leading, spacing: 8) {
                Text("笔记/解题思路")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                TextField("记录解题思路、易错点等...", text: $note, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(5...10)
                    .padding()
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - 保存按钮（现代化）
    
    private var saveButton: some View {
        VStack(spacing: 8) {
            Button {
                saveItem()
            } label: {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(isSaving ? "保存中..." : "保存到题库")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    isValid ? 
                    LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                    LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .shadow(color: isValid ? .blue.opacity(0.3) : .clear, radius: 8, y: 4)
            }
            .disabled(!isValid || isSaving)
            
            if !isValid && selectedUIImage != nil {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text("请填写标题")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Logic
    
    private var isValid: Bool {
        selectedImageData != nil && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func handlePickedImage(_ image: UIImage) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedUIImage = image
            selectedImage = Image(uiImage: image)
            
            if let compressedData = image.jpegData(compressionQuality: 0.7) {
                selectedImageData = compressedData
            }
            
            hasTriedOCR = false
            recognizedText = ""
        }
    }
    
    private func loadTransferable(from item: PhotosPickerItem?) {
        Task {
            if let data = try? await item?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    handlePickedImage(uiImage)
                }
            }
        }
    }
    
    private func recognizeText() {
        guard let image = selectedUIImage else { return }
        
        withAnimation {
            isRecognizingText = true
        }
        
        Task {
            do {
                let text = try await OCRService.shared.recognizeText(from: image)
                let extractedTitle = OCRService.shared.extractTitle(from: text)
                
                await MainActor.run {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        recognizedText = text
                        
                        if title.isEmpty {
                            title = extractedTitle
                        }
                        
                        if note.isEmpty {
                            note = text
                        }
                        
                        hasTriedOCR = true
                        isRecognizingText = false
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        hasTriedOCR = true
                        isRecognizingText = false
                    }
                    
                    alertMessage = "文字识别失败\n\n您可以手动输入标题和笔记"
                    showAlert = true
                }
            }
        }
    }
    
    private func resetImage() {
        withAnimation {
            selectedItem = nil
            selectedImage = nil
            selectedImageData = nil
            selectedUIImage = nil
            hasTriedOCR = false
            recognizedText = ""
        }
    }
    
    private func resetForm() {
        resetImage()
        title = ""
        note = ""
        tags = ""
    }
    
    private func saveItem() {
        guard let data = selectedImageData else { return }
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "请填写标题"
            showAlert = true
            return
        }
        
        withAnimation {
            isSaving = true
        }
        
        let newItem = ReviewItem(
            imageData: data,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note,
            subject: subject,
            grade: grade,
            tags: tags
        )
        
        modelContext.insert(newItem)
        
        do {
            try modelContext.save()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation {
                    isSaving = false
                }
                alertMessage = "保存成功！\n\n错题已添加到题库"
                showAlert = true
            }
        } catch {
            withAnimation {
                isSaving = false
            }
            alertMessage = "保存失败\n\n\(error.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: ReviewItem.self, inMemory: true)
}
