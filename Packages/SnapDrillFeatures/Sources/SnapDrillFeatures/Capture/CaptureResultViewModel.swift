//
//  CaptureResultViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集结果预览与编辑的 ViewModel，负责保存题目内容与图片。
//

import SwiftUI
import PhotosUI
import SnapDrillCore
import SnapDrillDomain

/// 采集结果预览与编辑的 ViewModel
@MainActor
@Observable
public final class CaptureResultViewModel {
    
    // MARK: - Properties
    
    public var content: String
    public var image: UIImage?
    
    // Taxonomy Information
    public var selectedSubject: String = "数学"
    public var selectedSource: String = "试卷"
    public var tagList: [String] = []
    public var tagInputText: String = ""
    
    // Details Form State
    public var answerText: String = ""
    public var difficulty: Difficulty = .one
    public var grade: String = ""
    public var answerImage: UIImage?
    
    // Photo Picker State
    public var answerPhotoItem: PhotosPickerItem? {
        didSet {
            processSelectedPhoto()
        }
    }
    
    // UI State
    public var isRecognizing = false
    public var isCropping = false
    public var isSaved = false
    public var showErrorAlert = false
    public var errorMessage: String?
    
    // Dropdown Form Data (Domain Entities)
    public private(set) var availableSubjects: [Subject] = []
    public private(set) var availableSources: [Source] = []
    public private(set) var availableGrades: [Grade] = []
    public private(set) var availableTags: [Tag] = []

    // MARK: - Dependencies

    private let reviewUseCase: ReviewUseCaseProtocol
    private let taxonomyUseCase: TaxonomyUseCaseProtocol
    private let ocrService: OCRServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let imageStorage: ImageStorage
    private let router: CaptureRouter
    
    /// 识别任务句柄
    private var recognitionTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    public init(
        content: String,
        image: UIImage?,
        reviewUseCase: ReviewUseCaseProtocol,
        taxonomyUseCase: TaxonomyUseCaseProtocol,
        ocrService: OCRServiceProtocol,
        analyticsService: AnalyticsServiceProtocol,
        imageStorage: ImageStorage = ImageStorage(),
        router: CaptureRouter
    ) {
        self.content = content
        self.image = image
        self.reviewUseCase = reviewUseCase
        self.taxonomyUseCase = taxonomyUseCase
        self.ocrService = ocrService
        self.analyticsService = analyticsService
        self.imageStorage = imageStorage
        self.router = router
    }
    
    // MARK: - Public API
    
    /// 加载默认表单数据
    public func loadFormData() {
        do {
            availableSubjects = try taxonomyUseCase.getSubjects().sorted(by: { $0.sortOrder < $1.sortOrder })
            availableSources = try taxonomyUseCase.getSources().sorted(by: { $0.sortOrder < $1.sortOrder })
            availableGrades = try taxonomyUseCase.getGrades().sorted(by: { $0.sortOrder < $1.sortOrder })
            availableTags = try taxonomyUseCase.getAllTags().sorted(by: { $0.name < $1.name })
        } catch {
            SnapDrillLogger.generic.error("加载下拉表单失败: \(error.localizedDescription)")
        }
    }
    
    /// 处理裁切结果
    public func handleImageCrop(_ croppedImage: UIImage) {
        self.image = croppedImage
        self.isCropping = false
        
        recognitionTask?.cancel()
        recognitionTask = Task {
            await reRecognizeText(from: croppedImage)
        }
    }
    
    /// 取消裁切
    public func cancelCrop() {
        self.isCropping = false
    }
    
    /// 保存预览 Draft (离开时触发)
    public func generateDraftIfNeeded() {
        if !isSaved, let img = image, !content.isEmpty {
            CaptureDraftService.shared.saveDraft(image: img, content: content)
        }
    }
    
    /// 保存正式题目
    public func saveResult() async {
        isSaved = true
        
        do {
            // 解析并同步标签
            var finalTagNames: [String] = []
            for name in tagList {
                _ = try taxonomyUseCase.getOrCreateTag(name: name, colorHex: "#CCCCCC")
                finalTagNames.append(name)
            }
            
            // 持久化题目截图，获取本地相对路径
            var savedImagePath: String?
            if let img = image {
                savedImagePath = try await imageStorage.saveImage(img)
            }

            // 持久化答案图片
            var savedAnswerImagePath: String?
            if let answerImg = answerImage {
                savedAnswerImagePath = try await imageStorage.saveImage(answerImg)
            }

            // 构造领域对象
            let item = ReviewItem(
                content: content.isEmpty ? nil : content,
                imagePath: savedImagePath,
                subject: selectedSubject,
                source: selectedSource,
                tags: finalTagNames,
                answerText: answerText.isEmpty ? nil : answerText,
                answerImagePath: savedAnswerImagePath,
                difficulty: difficulty,
                grade: grade
            )
            
            // 下推业务用例
            try reviewUseCase.captureNewItem(item)
            
            // 埋点
            analyticsService.track(
                .captureSaved,
                parameters: [
                    "subject": selectedSubject,
                    "source": selectedSource,
                    "difficulty": String(difficulty.rawValue)
                ]
            )
            
            // 清理并返回
            CaptureDraftService.shared.clearDraft()
            router.path.removeLast(router.path.count)
            
        } catch {
            SnapDrillLogger.generic.error("保存失败: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            self.showErrorAlert = true
            isSaved = false
        }
    }
    
    // MARK: - Private Helpers
    
    private func processSelectedPhoto() {
        guard let item = answerPhotoItem else { return }
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let loadedImage = UIImage(data: data) {
                    self.answerImage = loadedImage
                }
            } catch {
                SnapDrillLogger.generic.error("加载图片失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func reRecognizeText(from img: UIImage) async {
        isRecognizing = true
        defer { isRecognizing = false }
        
        do {
            guard let cgImage = img.cgImage else { return }
            try Task.checkCancellation()
            let newText = try await ocrService.recognizeText(from: cgImage)
            try Task.checkCancellation()
            self.content = newText
        } catch {
            SnapDrillLogger.generic.warning("重新识别失败: \(error.localizedDescription)")
        }
    }
}
