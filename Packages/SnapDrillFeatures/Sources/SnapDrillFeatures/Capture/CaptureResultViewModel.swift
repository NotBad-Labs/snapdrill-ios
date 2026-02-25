//
//  CaptureResultViewModel.swift
//  SnapDrillFeatureCapture
//
//  Created by SnapDrill Labs on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//

import SwiftUI
import PhotosUI
import SnapDrillCore
import SnapDrillData

/// 采集结果预览与编辑的 ViewModel
@MainActor
@Observable
public final class CaptureResultViewModel {
    
    // MARK: - View Data State
    
    public var content: String
    public var image: UIImage?
    
    // Taxonomy Information
    public var selectedSubject: String = "数学"
    public var selectedSource: String = "试卷"
    public var tagList: [String] = []
    public var tagInputText: String = ""
    
    // Details Form State
    public var answerText: String = ""
    public var difficulty: Int = 0
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
    
    // Dropdown Form Data (Replaces @Query)
    public private(set) var availableSubjects: [SubjectModel] = []
    public private(set) var availableSources: [SourceModel] = []
    public private(set) var availableTags: [TagModel] = []

    // MARK: - Dependencies
    
    private let reviewRepository: ReviewRepositoryProtocol
    private let subjectRepository: SubjectRepositoryProtocol
    private let sourceRepository: SourceRepositoryProtocol
    private let tagRepository: TagRepositoryProtocol
    private let ocrService: OCRServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let router: CaptureRouter
    
    /// 识别任务句柄，用于取消旧任务防止竞态
    private var recognitionTask: Task<Void, Never>?
    
    // MARK: - Init
    
    public init(
        content: String,
        image: UIImage?,
        reviewRepository: ReviewRepositoryProtocol,
        subjectRepository: SubjectRepositoryProtocol,
        sourceRepository: SourceRepositoryProtocol,
        tagRepository: TagRepositoryProtocol,
        ocrService: OCRServiceProtocol,
        analyticsService: AnalyticsServiceProtocol,
        router: CaptureRouter
    ) {
        self.content = content
        self.image = image
        self.reviewRepository = reviewRepository
        self.subjectRepository = subjectRepository
        self.sourceRepository = sourceRepository
        self.tagRepository = tagRepository
        self.ocrService = ocrService
        self.analyticsService = analyticsService
        self.router = router
    }
    
    // MARK: - Public Intents
    
    /// 加载默认表单数据
    public func loadFormData() {
        do {
            availableSubjects = try subjectRepository.fetchAll().sorted(by: { $0.sortOrder < $1.sortOrder })
            availableSources = try sourceRepository.fetchAll().sorted(by: { $0.sortOrder < $1.sortOrder })
            availableTags = try tagRepository.fetchAll().sorted(by: { $0.name < $1.name })
        } catch {
            SnapDrillLogger.generic.error("加载下拉表单失败: \(error.localizedDescription)")
        }
    }
    
    /// 处理裁切结果
    public func handleImageCrop(_ croppedImage: UIImage) {
        self.image = croppedImage
        self.isCropping = false
        
        // 取消之前的识别任务，防止旧结果覆盖新结果
        recognitionTask?.cancel()
        recognitionTask = Task {
            await reRecognizeText(from: croppedImage)
        }
    }
    
    /// 取消裁切
    public func cancelCrop() {
        self.isCropping = false
    }
    
    /// 保存 Draft（当离开时触发）
    public func generateDraftIfNeeded() {
        if !isSaved, let img = image, !content.isEmpty {
            CaptureDraftService.shared.saveDraft(image: img, content: content)
        }
    }
    
    /// 保存最终复习记录
    public func saveResult() async {
        isSaved = true
        
        do {
            // 解析 tags
            var finalTags: [TagModel] = []
            for tagName in tagList {
                let tag = try tagRepository.getOrCreate(name: tagName, colorHex: "#CCCCCC")
                finalTags.append(tag)
            }
            try tagRepository.save()
            
            // 构造新的 Review Item (Domain entity definition mismatch fix)
            var item = ReviewItem(
                content: content,
                imagePath: nil, // Note: raw image doesn't construct imagePath here yet
                source: selectedSource,
                difficulty: difficulty
            )
            item.answerText = answerText
            item.tags = finalTags.map { $0.name }
            item.grade = grade
            
            // 保存
            try reviewRepository.save(item, subject: selectedSubject)
            try reviewRepository.save()
            
            // 埋点
            analyticsService.track(
                .captureSaved,
                parameters: [
                    "subject": selectedSubject,
                    "source": selectedSource,
                    "has_image": String(image != nil),
                    "difficulty": String(difficulty)
                ]
            )
            
            // 跳转回 Dashboard (清除 Capture Stack)
            router.path.removeLast(router.path.count)
        } catch {
            SnapDrillLogger.generic.error("保存失败: \(error.localizedDescription)")
            isSaved = false
            // TODO: 显示错误给用户
        }
    }
    
    // MARK: - Private Core Logic
    
    private func processSelectedPhoto() {
        guard let item = answerPhotoItem else { return }
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let loadedImage = UIImage(data: data) {
                    self.answerImage = loadedImage
                }
            } catch {
                SnapDrillLogger.generic.error("无法加载答案图片: \(error.localizedDescription)")
            }
        }
    }
    
    private func reRecognizeText(from img: UIImage) async {
        isRecognizing = true
        defer { isRecognizing = false }
        
        do {
            guard let cgImage = img.cgImage else {
                throw OCRError.invalidImage
            }
            
            // 检查任务是否已被取消
            try Task.checkCancellation()
            
            // ocrService is actor, safely await result
            let newText = try await ocrService.recognizeText(from: cgImage)
            
            // 再次检查取消
            try Task.checkCancellation()
            
            self.content = newText
        } catch is CancellationError {
            SnapDrillLogger.generic.info("OCR 任务被取消 (新任务已启动)")
        } catch {
            SnapDrillLogger.generic.warning("重新 OCR 失败: \(error.localizedDescription)")
        }
    }
}
