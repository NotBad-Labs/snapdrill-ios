//
//  LibraryEditViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import SwiftUI
import SnapDrillDomain
import SnapDrillCore

@Observable
@MainActor
public final class LibraryEditViewModel {
    
    // MARK: - State
    
    public var content: String
    public var answer: String
    public var selectedSubject: String
    public var selectedSource: String
    public var tagList: [String]
    public var difficulty: Int
    
    public var displayedImage: UIImage?
    public var isProcessing = false
    public var isSavedNormally = false
    public var isCropping = false
    public var imageToCrop: UIImage?
    
    public var subjects: [Subject] = []
    public var sources: [Source] = []
    public var allTags: [Tag] = []
    
    // MARK: - Dependencies
    
    private var item: ReviewItem
    private let reviewUseCase: ReviewUseCaseProtocol
    private let taxonomyUseCase: TaxonomyUseCaseProtocol
    private let imageStorage = ImageStorage()
    private let ocrService = OCRService()
    
    public init(
        item: ReviewItem,
        reviewUseCase: ReviewUseCaseProtocol,
        taxonomyUseCase: TaxonomyUseCaseProtocol
    ) {
        self.item = item
        self.reviewUseCase = reviewUseCase
        self.taxonomyUseCase = taxonomyUseCase
        
        self.content = item.content
        self.answer = item.answerText
        self.selectedSubject = item.subject
        self.selectedSource = item.source
        self.tagList = item.tags
        self.difficulty = item.difficulty
    }
    
    // MARK: - Public API
    
    public func loadData() {
        if displayedImage == nil, let path = item.imagePath {
            displayedImage = imageStorage.loadImage(path: path)
        }
        
        do {
            self.subjects = try taxonomyUseCase.getSubjects()
            self.sources = try taxonomyUseCase.getSources()
            self.allTags = try taxonomyUseCase.getAllTags()
        } catch {
            SnapDrillLogger.generic.error("加载元数据失败: \(error.localizedDescription)")
        }
    }
    
    public func handleNewImage(_ image: UIImage) {
        self.displayedImage = image
        self.isProcessing = true
        
        Task {
            do {
                guard let cgImage = image.cgImage else { return }
                let recognizedText = try await ocrService.recognizeText(from: cgImage)
                
                await MainActor.run {
                    self.content = recognizedText
                    self.isProcessing = false
                }
            } catch {
                SnapDrillLogger.generic.info("OCR 识别失败: \(error.localizedDescription)")
                await MainActor.run {
                    self.isProcessing = false
                }
            }
        }
    }
    
    public func saveDraftIfNeeded() {
        // 后续可扩展草稿逻辑
    }
    
    public func save() async {
        isSavedNormally = true
        
        // 更新领域对象属性
        item.content = content
        item.answerText = answer
        item.subject = selectedSubject
        item.source = selectedSource
        item.difficulty = difficulty
        
        // 同步标签
        var finalTags: [String] = []
        for name in tagList {
            do {
                _ = try taxonomyUseCase.getOrCreateTag(name: name, colorHex: "#9E9E9E")
                finalTags.append(name)
            } catch {
                SnapDrillLogger.generic.error("同步标签失败: \(error.localizedDescription)")
            }
        }
        item.tags = finalTags
        
        // 处理图片保存
        if let newImage = displayedImage {
            do {
                let newPath = try await imageStorage.saveImage(newImage)
                item.imagePath = newPath
            } catch {
                SnapDrillLogger.generic.error("保存图片失败: \(error.localizedDescription)")
            }
        }
        
        do {
            try reviewUseCase.updateItem(item)
        } catch {
            SnapDrillLogger.generic.error("保存题目修改失败: \(error.localizedDescription)")
        }
    }
}
