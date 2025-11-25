//
//  CaptureViewModel.swift
//  NotBad
//
//  错题录入 ViewModel
//

import SwiftUI
import PhotosUI
import SwiftData

/// 错题录入 ViewModel
@MainActor
@Observable
final class CaptureViewModel {
    
    // MARK: - 图片状态
    
    var selectedItem: PhotosPickerItem?
    var selectedImage: Image?
    var selectedImageData: Data?
    var selectedUIImage: UIImage?
    
    // MARK: - 表单数据
    
    var title: String = ""
    var note: String = ""
    var subject: Subject = .math
    var grade: Grade = .grade10
    var knowledgePointsInput: String = ""
    var difficulty: Difficulty = .medium
    var errorType: ErrorType = .other
    var source: Source = .other
    var questionType: ReviewItemType = .other
    
    // MARK: - UI 状态
    
    var isSaving = false
    var isRecognizingText = false
    var showAlert = false
    var alertMessage = ""
    var showCamera = false
    var showLiveScanner = false
    
    // MARK: - Dependencies
    
    private let ocrService: OCRService
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init(ocrService: OCRService = .shared) {
        self.ocrService = ocrService
    }
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Computed Properties
    
    var isValid: Bool {
        selectedImageData != nil && !title.isEmpty
    }
    
    // MARK: - Actions
    
    func handlePickedImage(_ image: UIImage) {
        selectedUIImage = image
        selectedImage = Image(uiImage: image)
        
        // 压缩图片
        if let compressedData = image.jpegData(compressionQuality: 0.7) {
            selectedImageData = compressedData
        }
        
        // 自动触发 OCR
        if title.isEmpty {
            Task {
                await recognizeText()
            }
        }
    }
    
    func loadTransferable(from item: PhotosPickerItem?) async {
        guard let item = item,
              let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }
        
        handlePickedImage(uiImage)
    }
    
    func recognizeText() async {
        guard let image = selectedUIImage else { return }
        
        isRecognizingText = true
        
        do {
            let recognizedText = try await ocrService.recognizeText(from: image)
            let extractedTitle = ocrService.extractTitle(from: recognizedText)
            
            title = extractedTitle
            note = recognizedText
            isRecognizingText = false
            
            alertMessage = "文字识别成功！已自动填充标题和笔记"
            showAlert = true
        } catch {
            isRecognizingText = false
            alertMessage = "文字识别失败：\(error.localizedDescription)\n\n可以手动输入标题和笔记"
            showAlert = true
        }
    }
    
    func saveItem() {
        guard let data = selectedImageData, let modelContext = modelContext else { return }
        
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.isSaving = false
                self?.alertMessage = "保存成功！错题已添加到题库"
                self?.showAlert = true
            }
        } catch {
            isSaving = false
            alertMessage = "保存失败：\(error.localizedDescription)"
            showAlert = true
        }
    }
    
    func resetForm() {
        selectedItem = nil
        selectedImage = nil
        selectedImageData = nil
        selectedUIImage = nil
        title = ""
        note = ""
        knowledgePointsInput = ""
        // subject, grade 保持上次选择，方便连续录入
    }
    
    func handleLiveScanResult(_ text: String) {
        let firstLine = text.components(separatedBy: .newlines).first ?? text
        if title.isEmpty {
            title = String(firstLine.prefix(30))
        }
        note = text
    }
}
