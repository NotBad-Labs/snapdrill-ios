//
//  CaptureView.swift
//  NotBad
//
//  错题录入视图 - 支持相机拍摄、相册选择、OCR识别
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
    @State private var subject: Subject = .math
    @State private var grade: Grade = .grade10
    @State private var knowledgePointsInput: String = ""
    @State private var difficulty: Difficulty = .medium
    @State private var errorType: ErrorType = .other
    @State private var source: Source = .other
    @State private var questionType: ReviewItemType = .other
    
    // UI 状态
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showCamera = false
    @State private var showImageSourcePicker = false
    @State private var isRecognizingText = false
    @State private var showLiveScanner = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 1. 图片选择区域
                    imageSelectionSection
                    
                    // 2. OCR 识别按钮
                    if selectedUIImage != nil && title.isEmpty {
                        ocrButton
                    }
                    
                    // 3. 信息录入区域
                    inputSection
                    
                    // 4. 保存按钮
                    saveButton
                }
                .padding()
            }
            .navigationTitle("录入错题")
            .onChange(of: selectedItem) { _, newValue in
                loadTransferable(from: newValue)
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera) { image in
                    handlePickedImage(image)
                }
            }
            .confirmationDialog("选择图片来源", isPresented: $showImageSourcePicker) {
                Button("拍照") {
                    showCamera = true
                }
                Button("从相册选择") {
                    // PhotosPicker 会自动处理
                }
                Button("取消", role: .cancel) {}
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("确定") {
                    if alertMessage.contains("成功") {
                        resetForm()
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var imageSelectionSection: some View {
        Group {
            if let selectedImage {
                // 已选择图片
                VStack(spacing: 12) {
                    selectedImage
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 5)
                    
                    // 重新选择按钮
                    Button {
                        showImageSourcePicker = true
                    } label: {
                        Label("重新选择", systemImage: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            } else {
                // 未选择图片
                VStack(spacing: 16) {
                    // 拍照按钮
                    Button {
                        showCamera = true
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.blue)
                            Text("拍照录入")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // 实时扫描按钮 (iOS16+ 可用)
                    if #available(iOS 16.0, *) {
                        Button {
                            // 展示实时扫描视图
                            showLiveScanner = true
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.viewfinder")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.purple)
                                Text("实时扫描题干")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("无需拍照，直接提取文字")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(Color.purple.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .sheet(isPresented: $showLiveScanner) {
                            if #available(iOS 16.0, *) {
                                LiveTextScannerContainer(onResult: { text in
                                    // 将扫描的文字填入 note，并尝试提取标题（首行）
                                    let firstLine = text.components(separatedBy: .newlines).first ?? text
                                    if title.isEmpty { title = String(firstLine.prefix(30)) }
                                    note = text
                                }, onCancel: {})
                            } else {
                                Text("系统版本不支持实时扫描")
                            }
                        }
                    }
                    
                    // 相册选择
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 40))
                                .foregroundStyle(.green)
                            Text("从相册选择")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
    }
    
    private var ocrButton: some View {
        Button {
            recognizeText()
        } label: {
            HStack {
                if isRecognizingText {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "text.viewfinder")
                }
                Text(isRecognizingText ? "识别中..." : "自动识别文字")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isRecognizingText)
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("标题")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("例如: 数学-三角函数 (必填)", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .font(.headline)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("学科")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Picker("学科", selection: $subject) {
                        ForEach(Subject.allCases, id: \.self) { subject in
                            Text(subject.displayName).tag(subject)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("年级")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Picker("年级", selection: $grade) {
                        ForEach(Grade.allCases, id: \.self) { grade in
                            Text(grade.displayName).tag(grade)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("知识点标签")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("例如: 函数, 导数 (逗号分隔)", text: $knowledgePointsInput)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("备注")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("记录解题思路或知识点...", text: $note, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }
        }
    }
    
    private var saveButton: some View {
        Button {
            saveItem()
        } label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                        .padding(.trailing, 5)
                }
                Text(isSaving ? "保存中..." : "保存到题库")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isValid ? Color.blue : Color.gray.opacity(0.3))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isValid || isSaving)
    }
    
    // MARK: - Logic
    
    private var isValid: Bool {
        selectedImageData != nil && !title.isEmpty
    }
    
    private func handlePickedImage(_ image: UIImage) {
        selectedUIImage = image
        selectedImage = Image(uiImage: image)
        
        // 压缩图片
        if let compressedData = image.jpegData(compressionQuality: 0.7) {
            selectedImageData = compressedData
        }
        
        // 自动触发 OCR
        if title.isEmpty {
            Task {
                await MainActor.run {
                    recognizeText()
                }
            }
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
        
        isRecognizingText = true
        
        Task {
            do {
                let recognizedText = try await OCRService.shared.recognizeText(from: image)
                let extractedTitle = OCRService.shared.extractTitle(from: recognizedText)
                
                await MainActor.run {
                    title = extractedTitle
                    note = recognizedText
                    isRecognizingText = false
                    
                    // 提示用户
                    alertMessage = "文字识别成功！已自动填充标题和笔记"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isRecognizingText = false
                    alertMessage = "文字识别失败：\(error.localizedDescription)\n\n可以手动输入标题和笔记"
                    showAlert = true
                }
            }
        }
    }
    
    private func resetImage() {
        selectedItem = nil
        selectedImage = nil
        selectedImageData = nil
        selectedUIImage = nil
    }
    
    private func resetForm() {
        resetImage()
        title = ""
        note = ""
        knowledgePointsInput = ""
        // subject 和 grade 保持上次选择，方便连续录入
    }
    
    private func saveItem() {
        guard let data = selectedImageData else { return }
        isSaving = true
        
        let newItem = ReviewItem(
            imageData: data,
            title: title,
            note: note,
            subject: subject,
            grade: grade,
            knowledgePoints: KnowledgePoints(from: knowledgePointsInput),
            difficulty: difficulty,
            errorType: errorType,
            source: source,
            questionType: questionType
        )
        
        modelContext.insert(newItem)
        
        do {
            try modelContext.save()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSaving = false
                alertMessage = "保存成功！错题已添加到题库"
                showAlert = true
            }
        } catch {
            isSaving = false
            alertMessage = "保存失败：\(error.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: ReviewItem.self, inMemory: true)
}
